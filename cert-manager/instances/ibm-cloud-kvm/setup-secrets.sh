#!/usr/bin/env bash
# Setup Route53 credentials and generate kustomize patch for IBM Cloud KVM deployment.
# Platform: baremetal — zone and region cannot be auto-detected; pass them explicitly.
#
# Usage: ./setup-secrets.sh <access_key_id> <secret_access_key> <email> <hosted_zone_id> [region]
set -euo pipefail

usage() {
  echo "Usage: $0 <aws_access_key_id> <aws_secret_access_key> <email> <hosted_zone_id> [region]"
  echo "  hosted_zone_id  Route53 zone ID (e.g. Z0796000303B5B0UIF2CH)"
  echo "  region          AWS region for Route53 (default: us-east-1)"
  exit 1
}

[[ $# -lt 4 ]] && usage

ACCESS_KEY="$1"
SECRET_KEY="$2"
EMAIL="$3"
ZONE_ID="$4"
REGION="${5:-us-east-1}"

if ! command -v oc &>/dev/null; then echo "oc not found on PATH"; exit 1; fi
if ! oc whoami &>/dev/null; then echo "Not logged in — set KUBECONFIG"; exit 1; fi

APPS_DOMAIN="*.$(oc get ingresscontroller default -n openshift-ingress-operator \
  -o jsonpath='{.status.domain}')"
API_HOST="$(oc whoami --show-server | sed -E 's#https://([^:/]+).*#\1#')"

echo "Apps domain : ${APPS_DOMAIN}"
echo "API host    : ${API_HOST}"
echo "Zone ID     : ${ZONE_ID} (${REGION})"
echo "Email       : ${EMAIL}"

# Create credentials secret
oc create secret generic route53-credentials \
  --from-literal=awsSecretAccessKey="${SECRET_KEY}" \
  -n cert-manager \
  --dry-run=client -o yaml | oc apply -f -

echo "Secret route53-credentials created in cert-manager namespace."

# Generate kustomize strategic merge patch
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
          route53:
            accessKeyID: "${ACCESS_KEY}"
            hostedZoneID: "${ZONE_ID}"
            region: "${REGION}"
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
