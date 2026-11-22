#!/bin/bash
# AWS example for the cert-manager operator already installed on the cluster.
# Route 53 DNS-01 with explicit credentials, then the apps wildcard and the external API name.
# acme.sh is the older note's tool.
#
# The access key and secret are arguments. They are not printed and not written into this repo.

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 aws_access_key_id aws_secret_access_key email [hosted_zone_id] [region] [--include-api]

Default: issues only the *.apps wildcard cert (ingress). Safe for all cluster types.

--include-api  Also issue and apply a cert for api.<cluster>.<domain>.
               WARNING: Rotating the API server cert breaks kubelet client cert rotation,
               causing all nodes to go NotReady (User: system:anonymous errors).
               Only use on AWS IPI clusters where Let's Encrypt CA is already in the
               RHCOS trust bundle via MachineConfig. On KVM/baremetal, skip this flag
               and access the API via kubeconfig with the cluster's internal CA.

The script checks oc whoami before it changes the cluster. When KUBECONFIG is unset
and ~/.kube/config is absent, it uses $HOME/cluster/auth/kubeconfig from the AWS install.
See cert-manager/README.md for the operator install.
The secret aws-secret is created in the cert-manager namespace. Do not commit it.

ACME_SERVER overrides the Let's Encrypt directory. The default is the production
directory. The 5.0 sample uses the staging directory:
  https://acme-staging-v02.api.letsencrypt.org/directory
EOF
}

INCLUDE_API=false
ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--include-api" ]]; then
    INCLUDE_API=true
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

if [[ $# -lt 3 || $# -gt 5 ]]; then
  usage >&2
  exit 1
fi

access_key=$1
secret_key=$2
email=$3
zone_id=${4:-}
region=${5:-}

if [[ -z "$access_key" || -z "$secret_key" || -z "$email" ]]; then
  echo "Access key, secret key, and email are required." >&2
  usage >&2
  exit 1
fi
if [[ "$access_key" == *$'\n'* || "$secret_key" == *$'\n'* || "$email" == *$'\n'* ]]; then
  echo "Access key, secret key, and email must be one line each." >&2
  exit 1
fi
# Let's Encrypt rejects placeholder/example domains for ACME account registration.
# Catch them early before wasting time on DNS01 challenge setup.
if [[ "$email" == *@example.com || "$email" == *@example.org || "$email" == *@example.net \
   || "$email" == you@* || "$email" == user@* || "$email" == admin@example* ]]; then
  echo "Error: '${email}' looks like a placeholder. Provide a real email address." >&2
  echo "Let's Encrypt rejects example.com and similar forbidden domains." >&2
  exit 1
fi
if [[ "$email" != *@*.* ]]; then
  echo "Error: '${email}' does not look like a valid email address." >&2
  exit 1
fi

if ! command -v oc >/dev/null 2>&1; then
  echo "oc is not on PATH." >&2
  exit 1
fi

if [[ -z "${KUBECONFIG:-}" && ! -f "${HOME}/.kube/config" && -f "${HOME}/cluster/auth/kubeconfig" ]]; then
  export KUBECONFIG="${HOME}/cluster/auth/kubeconfig"
  echo "Using ${KUBECONFIG}"
fi
if ! oc whoami >/dev/null 2>&1; then
  echo "oc is not logged in. Set KUBECONFIG, or place a kubeconfig at ~/.kube/config." >&2
  echo "The AWS install writes ${HOME}/cluster/auth/kubeconfig." >&2
  exit 1
fi
echo "Logged in as $(oc whoami)"

ACME_SERVER="${ACME_SERVER:-https://acme-v02.api.letsencrypt.org/directory}"

if [[ -z "$region" ]]; then
  region="$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}')"
fi
if [[ -z "$region" ]]; then
  echo "Could not read the AWS region from infrastructure/cluster. Pass it as the fifth argument." >&2
  exit 1
fi

cluster_domain="$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')"
apps_domain="$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')"
api_host="$(oc whoami --show-server | sed -E 's#https://([^:/]+).*#\1#')"

if [[ -z "$cluster_domain" || -z "$apps_domain" || -z "$api_host" ]]; then
  echo "Could not read the cluster domain, apps domain, or API host." >&2
  exit 1
fi
if [[ "$api_host" == api-int.* ]]; then
  echo "Refusing to issue a named certificate for ${api_host}." >&2
  exit 1
fi

# dns/cluster reports the cluster domain. On this AWS install that is
# ocp5.sandbox5524.opentlc.com, and the public records live in the parent zone.
# Let's Encrypt cannot validate a record that exists only in the private zone.
zone_name=""
if [[ -n "$zone_id" ]]; then
  if ! command -v aws >/dev/null 2>&1; then
    echo "The AWS CLI is required to confirm hosted zone ${zone_id} is public." >&2
    exit 1
  fi
  zone_private="$(
    AWS_ACCESS_KEY_ID="$access_key" \
    AWS_SECRET_ACCESS_KEY="$secret_key" \
    AWS_DEFAULT_REGION="$region" \
    aws route53 get-hosted-zone --id "$zone_id" --query 'HostedZone.Config.PrivateZone' --output text
  )"
  zone_name="$(
    AWS_ACCESS_KEY_ID="$access_key" \
    AWS_SECRET_ACCESS_KEY="$secret_key" \
    AWS_DEFAULT_REGION="$region" \
    aws route53 get-hosted-zone --id "$zone_id" --query 'HostedZone.Name' --output text
  )"
  zone_name="${zone_name%.}"
  if [[ "$zone_private" == "True" || "$zone_private" == "true" ]]; then
    echo "Hosted zone ${zone_id} (${zone_name}) is private. Let's Encrypt uses the public parent zone." >&2
    zone_id=""
    zone_name=""
  fi
fi
if [[ -z "$zone_id" ]]; then
  if ! command -v aws >/dev/null 2>&1; then
    echo "Pass a public hosted zone id, or install the AWS CLI so the public zone can be looked up." >&2
    exit 1
  fi
  candidate="$cluster_domain"
  while [[ "$candidate" == *.* ]]; do
    found="$(
      AWS_ACCESS_KEY_ID="$access_key" \
      AWS_SECRET_ACCESS_KEY="$secret_key" \
      AWS_DEFAULT_REGION="$region" \
      aws route53 list-hosted-zones-by-name \
        --dns-name "${candidate}." \
        --query "HostedZones[?Name=='${candidate}.' && Config.PrivateZone==\`false\`].Id | [0]" \
        --output text
    )"
    found="${found#/hostedzone/}"
    if [[ -n "$found" && "$found" != "None" ]]; then
      zone_id="$found"
      zone_name="$candidate"
      break
    fi
    candidate="${candidate#*.}"
  done
fi
if [[ -z "$zone_id" || "$zone_id" == "None" ]]; then
  echo "No public hosted zone found for ${cluster_domain}." >&2
  exit 1
fi

echo "API host: ${api_host}"
echo "Apps domain: *.${apps_domain}"
if [[ -n "$zone_name" ]]; then
  echo "Route 53 zone: ${zone_name} (${zone_id}) in ${region}"
else
  echo "Route 53 zone: ${zone_id} in ${region}"
fi

# AWS installer-provisioned clusters also have a private zone for the cluster domain.
# The 5.0 chapter uses these arguments when that private zone overlaps the public zone.
oc patch certmanager cluster --type=merge -p '{"spec":{"controllerConfig":{"overrideArgs":["--dns01-recursive-nameservers-only","--dns01-recursive-nameservers=1.1.1.1:53"]}}}'
oc rollout status deployment/cert-manager -n cert-manager --timeout=5m

oc create secret generic aws-secret -n cert-manager \
  --from-literal=awsSecretAccessKey="$secret_key" \
  --dry-run=client -o yaml | oc apply -f -

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
chmod 700 "$tmp"

cat > "$tmp/clusterissuer.yaml" <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: route53-acme
spec:
  acme:
    preferredChain: ""
    server: ${ACME_SERVER}
    email: "${email}"
    privateKeySecretRef:
      name: route53-acme-account-key
    solvers:
    - dns01:
        route53:
          accessKeyID: ${access_key}
          hostedZoneID: ${zone_id}
          region: ${region}
          secretAccessKeySecretRef:
            name: aws-secret
            key: awsSecretAccessKey
EOF

cat > "$tmp/certificates.yaml" <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: router-certs
  namespace: openshift-ingress
spec:
  secretName: router-certs
  issuerRef:
    name: route53-acme
    kind: ClusterIssuer
  commonName: "*.${apps_domain}"
  dnsNames:
  - "*.${apps_domain}"
EOF

if [[ "$INCLUDE_API" == "true" ]]; then
cat >> "$tmp/certificates.yaml" <<EOF
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: api-cert
  namespace: openshift-config
spec:
  secretName: api-cert
  issuerRef:
    name: route53-acme
    kind: ClusterIssuer
  dnsNames:
  - ${api_host}
EOF
fi

oc apply -f "$tmp/clusterissuer.yaml"
oc apply -f "$tmp/certificates.yaml"

oc wait -n openshift-ingress certificate/router-certs --for=condition=Ready --timeout=20m
if [[ "$INCLUDE_API" == "true" ]]; then
  oc wait -n openshift-config certificate/api-cert --for=condition=Ready --timeout=20m
fi

# The ingress chapter puts the signing root in openshift-config and points the proxy at it.
# Updating trustedCA restarts kubelet and CRI-O on each node.
oc get secret router-certs -n openshift-ingress -o go-template='{{index .data "tls.crt"}}' \
  | base64 -d \
  | awk 'BEGIN {cert=""} /-----BEGIN CERTIFICATE-----/ {cert=""} {cert=cert $0 ORS} END {printf "%s", cert}' \
  > "$tmp/ca.crt"
if [[ ! -s "$tmp/ca.crt" ]]; then
  echo "router-certs did not contain a certificate chain." >&2
  exit 1
fi
oc create configmap custom-ca \
  --from-file=ca-bundle.crt="$tmp/ca.crt" \
  -n openshift-config \
  --dry-run=client -o yaml | oc apply -f -
oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'

oc patch ingresscontroller.operator default \
  --type=merge \
  -p '{"spec":{"defaultCertificate":{"name":"router-certs"}}}' \
  -n openshift-ingress-operator

# Approve any pending CSRs — cert rotation can cause kubelet client certs to
# queue for re-issuance. Without approval nodes go NotReady (system:anonymous errors).
echo "Approving any pending CSRs..."
for _ in $(seq 1 5); do
  pending=$(oc get csr --no-headers 2>/dev/null | awk '/Pending/{print $1}')
  if [[ -n "$pending" ]]; then
    echo "$pending" | xargs oc adm certificate approve 2>/dev/null || true
  fi
  sleep 10
done
echo "CSR approval complete."

if [[ "$INCLUDE_API" == "true" ]]; then
  # WARNING: Rotating the API server cert triggers a kube-apiserver revision rollout.
  # During or after that rollout, extension-apiserver-authentication (kube-system) can
  # lose its requestheader-client-ca-file key, causing openshift-apiserver and
  # oauth-apiserver to return 401 on every aggregated API request (authentication,
  # monitoring, console all go degraded). Recovery requires:
  #   1. oc get csr --no-headers | awk '/Pending/{print $1}' | xargs -r oc adm certificate approve
  #   2. oc annotate kubeapiserver cluster unsupported-red-hat-internal-force-deployment=true --overwrite
  #   3. wait for configmap to repopulate, then restart openshift-apiserver/oauth-apiserver pods
  # Only use --include-api on AWS IPI clusters. On KVM/baremetal, skip it.
  oc patch apiserver cluster --type=merge -p "{\"spec\":{\"servingCerts\":{\"namedCertificates\":[{\"names\":[\"${api_host}\"],\"servingCertificate\":{\"name\":\"api-cert\"}}]}}}"
  echo "Waiting for kube-apiserver to finish progressing."
else
  echo "Skipping API server cert patch (use --include-api to enable)."
  echo "Waiting for kube-apiserver to finish progressing."
fi
for _ in $(seq 1 60); do
  progressing="$(oc get clusteroperators kube-apiserver -o jsonpath='{.status.conditions[?(@.type=="Progressing")].status}')"
  available="$(oc get clusteroperators kube-apiserver -o jsonpath='{.status.conditions[?(@.type=="Available")].status}')"
  if [[ "$progressing" == "False" && "$available" == "True" ]]; then
    break
  fi
  sleep 10
done
oc get clusteroperators kube-apiserver
oc get pods -n openshift-ingress
oc get certificate -n openshift-ingress router-certs
oc get certificate -n openshift-config api-cert
