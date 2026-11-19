#!/usr/bin/env bash
# Setup Azure DNS service principal credentials and generate kustomize patch.
#
# Usage: ./setup-secrets.sh <tenant_id> <client_id> <client_secret> \
#                           <subscription_id> <resource_group> <zone_name> <email>
set -euo pipefail

usage() {
  echo "Usage: $0 <tenant_id> <client_id> <client_secret> <subscription_id> <resource_group> <zone_name> <email>"
  echo "  The service principal must have DNS Zone Contributor on the Azure DNS zone."
  exit 1
}

[[ $# -ne 7 ]] && usage

TENANT_ID="$1"
CLIENT_ID="$2"
CLIENT_SECRET="$3"
SUBSCRIPTION_ID="$4"
RESOURCE_GROUP="$5"
ZONE_NAME="$6"
EMAIL="$7"

if ! command -v oc &>/dev/null; then echo "oc not found on PATH"; exit 1; fi
if ! oc whoami &>/dev/null; then echo "Not logged in — set KUBECONFIG"; exit 1; fi

APPS_DOMAIN="*.$(oc get ingresscontroller default -n openshift-ingress-operator \
  -o jsonpath='{.status.domain}')"
API_HOST="$(oc whoami --show-server | sed -E 's#https://([^:/]+).*#\1#')"

echo "Apps domain   : ${APPS_DOMAIN}"
echo "API host      : ${API_HOST}"
echo "Azure zone    : ${ZONE_NAME} (${RESOURCE_GROUP})"
echo "Email         : ${EMAIL}"

oc create secret generic azure-dns-sp \
  --from-literal=client-secret="${CLIENT_SECRET}" \
  -n cert-manager \
  --dry-run=client -o yaml | oc apply -f -

echo "Secret azure-dns-sp created in cert-manager namespace."

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
          azureDNS:
            subscriptionID: "${SUBSCRIPTION_ID}"
            resourceGroupName: "${RESOURCE_GROUP}"
            hostedZoneName: "${ZONE_NAME}"
            environment: AzurePublicCloud
            clientID: "${CLIENT_ID}"
            clientSecretSecretRef:
              name: azure-dns-sp
              key: client-secret
            tenantID: "${TENANT_ID}"
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
