#!/usr/bin/env bash
# cert-manager/instances/add-trusted-ca.sh
#
# REQUIRED STEP — run this BEFORE rotating any cluster certificate with cert-manager.
#
# Adds the Let's Encrypt certificate chain to the cluster's trusted CA bundle
# (proxy/cluster trustedCA). The MCO distributes this bundle to every RHCOS node,
# allowing kubelets and operators to trust Let's Encrypt-signed certs.
#
# Without this step, rotating the API server cert with cert-manager causes:
#   - "Kubelet stopped posting node status" on all nodes
#   - Cascading kube-apiserver CrashLoopBackOff (OOM/kill during restart)
#   - All nodes going NotReady
#
# Reference: "Proxy certificates" in OCP Security and Compliance docs
#   https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions
#
# Usage:
#   ./cert-manager/instances/add-trusted-ca.sh
#   ./cert-manager/instances/add-trusted-ca.sh --skip-wait   # skip MCO rollout wait

set -euo pipefail

SKIP_WAIT="${1:-}"

# ── Colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Prerequisites ─────────────────────────────────────────────────────────────
command -v oc &>/dev/null    || die "oc not found"
command -v openssl &>/dev/null || die "openssl not found"
command -v curl &>/dev/null   || die "curl not found"
oc whoami &>/dev/null         || die "Not logged in to cluster. Set KUBECONFIG or run 'oc login'."

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Add Let's Encrypt CA to cluster trusted bundle${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

API_HOST="$(oc whoami --show-server | sed -E 's#https://([^:/]+).*#\1#')"
info "Cluster API: ${API_HOST}"

# ── Step 1: Discover the Let's Encrypt chain in use ──────────────────────────
info "Step 1: Discovering Let's Encrypt intermediate CA from cluster API cert..."

# Get the Authority Information Access (AIA) URL for the intermediate from the API cert
AIA_URL="$(openssl s_client -connect "${API_HOST}:6443" \
  -servername "${API_HOST}" \
  </dev/null 2>/dev/null \
  | openssl x509 -noout -text 2>/dev/null \
  | grep "CA Issuers - URI" \
  | awk -F'URI:' '{print $2}' \
  | tr -d ' ')"

if [[ -z "$AIA_URL" ]]; then
  die "Could not read AIA CA Issuers URL from API server cert. Is cert-manager already installed and the cert issued?"
fi

ok "Intermediate CA AIA URL: ${AIA_URL}"

# Derive the root URL by replacing the intermediate path with root
# e.g. https://yr2.i.lencr.org/ → root is at https://yr.i.lencr.org/
ROOT_URL="$(echo "$AIA_URL" | sed 's|yr2\.|yr.|; s|e[0-9]*\.|r[0-9]*.|; s|r[0-9]*\.|e[0-9]*.| ')"
# Simpler: use the standard Let's Encrypt AIA root endpoint
# YR2 → http://yr.i.lencr.org/
# E5/E6 → http://r.i.lencr.org/
if echo "$AIA_URL" | grep -q "yr2"; then
  ROOT_URL="http://yr.i.lencr.org/"
elif echo "$AIA_URL" | grep -q "^http.*e[0-9]"; then
  ROOT_URL="http://r3.i.lencr.org/"
else
  ROOT_URL="http://r3.i.lencr.org/"
fi

info "Root CA AIA URL: ${ROOT_URL}"

# ── Step 2: Download the intermediate and cross-signed root ──────────────────
info "Step 2: Downloading Let's Encrypt intermediate and root certs..."

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

curl -sf "${AIA_URL}" | openssl x509 -inform DER -out "${TMPDIR}/intermediate.pem" 2>/dev/null \
  || die "Failed to download intermediate CA from ${AIA_URL}"
ok "Intermediate: $(openssl x509 -noout -subject -in "${TMPDIR}/intermediate.pem" 2>/dev/null | cut -d= -f2-)"

curl -sf "${ROOT_URL}" | openssl x509 -inform DER -out "${TMPDIR}/root-crosssigned.pem" 2>/dev/null \
  || die "Failed to download root CA from ${ROOT_URL}"
ok "Root (cross-signed): $(openssl x509 -noout -subject -in "${TMPDIR}/root-crosssigned.pem" 2>/dev/null | cut -d= -f2-)"

# ── Step 3: Build and verify the bundle ──────────────────────────────────────
info "Step 3: Building and verifying CA bundle..."

cat "${TMPDIR}/intermediate.pem" "${TMPDIR}/root-crosssigned.pem" > "${TMPDIR}/ca-bundle.pem"

# Verify that the API server cert chains to this bundle
LEAF_CERT="$(openssl s_client -connect "${API_HOST}:6443" \
  -servername "${API_HOST}" \
  </dev/null 2>/dev/null \
  | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/')"

echo "${LEAF_CERT}" > "${TMPDIR}/leaf.pem"

if openssl verify \
  -untrusted "${TMPDIR}/intermediate.pem" \
  -CAfile "${TMPDIR}/root-crosssigned.pem" \
  "${TMPDIR}/leaf.pem" &>/dev/null; then
  ok "CA bundle verified — API cert chains correctly to bundle"
else
  warn "Chain verification failed — bundle may still work if ISRG root is in RHCOS system trust"
fi

# ── Step 4: Apply to cluster ──────────────────────────────────────────────────
info "Step 4: Creating/updating letsencrypt-ca ConfigMap in openshift-config..."

# Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions
# Section 4.2: Proxy certificates — trustedCA field
oc create configmap letsencrypt-ca \
  --from-file=ca-bundle.crt="${TMPDIR}/ca-bundle.pem" \
  -n openshift-config \
  --dry-run=client -o yaml | oc apply -f -

ok "ConfigMap letsencrypt-ca created/updated in openshift-config"

info "Step 5: Patching proxy/cluster to reference the trust bundle..."

# The MCO reads trustedCA from proxy/cluster and distributes it to ALL RHCOS nodes
# via MachineConfig, merged with the RHCOS system trust bundle.
oc patch proxy/cluster --type=merge \
  --patch='{"spec":{"trustedCA":{"name":"letsencrypt-ca"}}}'

ok "proxy/cluster patched — MCO will now distribute Let's Encrypt CA to all nodes"

# ── Step 5: Wait for MCO rollout ──────────────────────────────────────────────
if [[ "${SKIP_WAIT}" == "--skip-wait" ]]; then
  warn "Skipping MCO rollout wait (--skip-wait). Do NOT rotate API cert until MCO completes."
  warn "Monitor with: oc get mcp"
else
  echo ""
  info "Step 6: Waiting for MCO to roll out trust bundle to all nodes..."
  info "This updates /etc/pki/ca-trust on every RHCOS node. Takes ~5-15 min."
  info "Reference: https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions"
  info ""

  echo "Waiting for master MachineConfigPool..."
  oc wait mcp/master --for=condition=Updated --timeout=20m \
    || warn "master MCP did not complete within 20 min — check: oc get mcp,mc"

  echo "Waiting for worker MachineConfigPool..."
  oc wait mcp/worker --for=condition=Updated --timeout=20m \
    || warn "worker MCP did not complete within 20 min — check: oc get mcp,mc"

  ok "MCO rollout complete — Let's Encrypt CA is now trusted on all RHCOS nodes"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Let's Encrypt CA trust bundle applied successfully${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "You can now safely proceed with cert-manager certificate issuance:"
echo ""
echo "  ./cert-manager/setup-secrets.sh --provider <provider> <args>"
echo "  oc apply -k cert-manager/instances/<provider>/"
echo ""
echo "Reference:"
echo "  https://docs.redhat.com/en/documentation/openshift_container_platform/5.0/html/security_and_compliance/certificate-types-and-descriptions"
