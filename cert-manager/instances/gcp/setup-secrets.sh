#!/usr/bin/env bash
# Setup GCP Cloud DNS credentials and generate kustomize patch.
#
# Usage: ./setup-secrets.sh <gcp_project_id> <path_to_sa_json> <email>
set -euo pipefail

usage() {
  echo "Usage: $0 <gcp_project_id> <path_to_service_account_json> <email>"
  echo "  The service account must have roles/dns.admin on the Cloud DNS zone."
  exit 1
}

[[ $# -ne 3 ]] && usage

PROJECT_ID="$1"
SA_JSON="$2"
EMAIL="$3"

[[ ! -f "${SA_JSON}" ]] && { echo "Service account JSON not found: ${SA_JSON}"; exit 1; }

if ! command -v oc &>/dev/null; then echo "oc not found on PATH"; exit 1; fi
if ! oc whoami &>/dev/null; then echo "Not logged in — set KUBECONFIG"; exit 1; fi

# Validate email — Let's Encrypt rejects placeholder domains
if [[ "$EMAIL" == *@example.com || "$EMAIL" == *@example.org || "$EMAIL" == *@example.net \
   || "$EMAIL" == you@* || "$EMAIL" == user@* || "$EMAIL" == admin@example* ]]; then
  echo "Error: placeholder email detected. Provide a real email address." >&2; exit 1
fi
if [[ "$EMAIL" != *@*.* ]]; then
  echo "Error: '${EMAIL}' is not a valid email address." >&2; exit 1
fi

APPS_DOMAIN="*.$(oc get ingresscontroller default -n openshift-ingress-operator \
  -o jsonpath='{.status.domain}')"
API_HOST="$(oc whoami --show-server | sed -E 's#https://([^:/]+).*#\1#')"

echo "Apps domain : ${APPS_DOMAIN}"
echo "API host    : ${API_HOST}"
echo "GCP project : ${PROJECT_ID}"
echo "Email       : ${EMAIL}"

oc create secret generic gcp-dns-sa \
  --from-file=service-account.json="${SA_JSON}" \
  -n cert-manager \
  --dry-run=client -o yaml | oc apply -f -

echo "Secret gcp-dns-sa created in cert-manager namespace."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cat > "${SCRIPT_DIR}/generated-patch.yaml" <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: "${EMAIL}"
    solvers:
      - dns01:
          cloudDNS:
            project: "${PROJECT_ID}"
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: router-certs
  namespace: openshift-ingress
spec:
  commonName: "${APPS_DOMAIN}"
  dnsNames:
    - "${APPS_DOMAIN}"
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-cert
  namespace: openshift-config
spec:
  dnsNames:
    - "${API_HOST}"
EOF

echo ""
echo "generated-patch.yaml written (gitignored)."
echo ""
echo "Now run:"
echo "  oc apply -k ${SCRIPT_DIR}"
