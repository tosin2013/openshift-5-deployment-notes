#!/usr/bin/env bash
# Setup Route53 credentials and generate kustomize patch for AWS IPI deployment.
# Platform: aws — region and zone auto-detected from cluster infrastructure when not provided.
#
# Usage: ./setup-secrets.sh <access_key_id> <secret_access_key> <email> [hosted_zone_id] [region]
set -euo pipefail

usage() {
  echo "Usage: $0 <aws_access_key_id> <aws_secret_access_key> <email> [hosted_zone_id] [region]"
  exit 1
}

[[ $# -lt 3 ]] && usage

ACCESS_KEY="$1"
SECRET_KEY="$2"
EMAIL="$3"
ZONE_ID="${4:-}"
REGION="${5:-}"

if ! command -v oc &>/dev/null; then echo "oc not found on PATH"; exit 1; fi
if ! oc whoami &>/dev/null; then echo "Not logged in — set KUBECONFIG"; exit 1; fi

# Auto-detect region from AWS infrastructure
if [[ -z "${REGION}" ]]; then
  REGION="$(oc get infrastructure cluster \
    -o jsonpath='{.status.platformStatus.aws.region}' 2>/dev/null || true)"
fi
[[ -z "${REGION}" ]] && { echo "Could not detect region. Pass it as arg 5."; exit 1; }

APPS_DOMAIN="*.$(oc get ingresscontroller default -n openshift-ingress-operator \
  -o jsonpath='{.status.domain}')"
API_HOST="$(oc whoami --show-server | sed -E 's#https://([^:/]+).*#\1#')"
BASE_DOMAIN="$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')"

# Auto-detect public hosted zone if not provided
if [[ -z "${ZONE_ID}" ]]; then
  if ! command -v aws &>/dev/null; then echo "aws CLI required to auto-detect zone"; exit 1; fi
  candidate="${BASE_DOMAIN}"
  while [[ "${candidate}" == *.* ]]; do
    found="$(AWS_ACCESS_KEY_ID="${ACCESS_KEY}" AWS_SECRET_ACCESS_KEY="${SECRET_KEY}" \
      AWS_DEFAULT_REGION="${REGION}" \
      aws route53 list-hosted-zones-by-name \
        --dns-name "${candidate}." \
        --query "HostedZones[?Name=='${candidate}.' && Config.PrivateZone==\`false\`].Id | [0]" \
        --output text)"
    found="${found#/hostedzone/}"
    if [[ -n "${found}" && "${found}" != "None" ]]; then
      ZONE_ID="${found}"
      break
    fi
    candidate="${candidate#*.}"
  done
fi
[[ -z "${ZONE_ID}" || "${ZONE_ID}" == "None" ]] && { echo "No public Route53 zone found for ${BASE_DOMAIN}"; exit 1; }

echo "Apps domain : ${APPS_DOMAIN}"
echo "API host    : ${API_HOST}"
echo "Zone ID     : ${ZONE_ID} (${REGION})"
echo "Email       : ${EMAIL}"

oc create secret generic route53-credentials \
  --from-literal=awsSecretAccessKey="${SECRET_KEY}" \
  -n cert-manager \
  --dry-run=client -o yaml | oc apply -f -

echo "Secret route53-credentials created in cert-manager namespace."

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
