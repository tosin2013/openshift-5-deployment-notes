#!/usr/bin/env bash
# cert-manager/setup-secrets.sh
# Top-level dispatcher: validates prerequisites then delegates to the
# provider-specific setup-secrets.sh in instances/<provider>/.
#
# Usage:
#   ./cert-manager/setup-secrets.sh --provider ibm-cloud-kvm <args>
#   ./cert-manager/setup-secrets.sh --provider aws            <args>
#   ./cert-manager/setup-secrets.sh --provider gcp            <args>
#   ./cert-manager/setup-secrets.sh --provider azure          <args>
#
# Run from the repo root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()   { error "$*"; exit 1; }

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
${BOLD}cert-manager/setup-secrets.sh${NC} — create credentials secrets for cert-manager DNS01

${BOLD}Usage:${NC}
  $0 --provider <provider> [provider-args...]

${BOLD}Providers:${NC}
  ibm-cloud-kvm   Route53 DNS01 — cluster on KVM with baremetal platform
  aws             Route53 DNS01 — cluster on AWS (auto-detects region/zone)
  gcp             Cloud DNS     — cluster on GCP
  azure           Azure DNS     — cluster on Azure

${BOLD}Provider args:${NC}
  ibm-cloud-kvm:  <access-key-id> <secret-key> <email> <hosted-zone-id> <region>
  aws:            <access-key-id> <secret-key> <email> [hosted-zone-id] [region]
  gcp:            <gcp-project-id> <path-to-sa-json> <email>
  azure:          <tenant-id> <client-id> <client-secret> <subscription-id> \\
                  <resource-group> <zone-name> <email>

${BOLD}Required binaries (checked before proceeding):${NC}
  All providers:  oc, kubectl (or oc)
  ibm-cloud-kvm:  aws
  aws:            aws
  gcp:            gcloud
  azure:          az

${BOLD}Examples:${NC}
  $0 --provider ibm-cloud-kvm AKIAIOSFODNN7 wJalrXUtn you@example.com Z0796000303 us-east-1
  $0 --provider aws           AKIAIOSFODNN7 wJalrXUtn you@example.com
  $0 --provider gcp           my-project ./sa-key.json you@example.com
  $0 --provider azure         tenant-id client-id client-secret sub-id rg zone you@example.com
EOF
}

# ── Argument parsing ──────────────────────────────────────────────────────────
if [[ $# -lt 2 ]] || [[ "$1" != "--provider" ]]; then
  usage; exit 1
fi
PROVIDER="$2"
shift 2   # remaining args go to the provider script

# ── Binary prerequisite checks ────────────────────────────────────────────────
check_binary() {
  local bin="$1" install_hint="$2"
  if command -v "$bin" &>/dev/null; then
    ok "$bin found: $(command -v "$bin")"
  else
    error "$bin not found."
    echo "    Install: $install_hint" >&2
    return 1
  fi
}

check_common_prereqs() {
  info "Checking common prerequisites..."
  local failed=0

  check_binary oc \
    "Download from: https://mirror.openshift.com/pub/openshift-v5/x86_64/clients/ocp/stable-5.0/" \
    || failed=1

  # Verify cluster access
  if command -v oc &>/dev/null; then
    if oc whoami &>/dev/null; then
      ok "oc logged in as: $(oc whoami)"
    else
      error "oc is not logged in. Set KUBECONFIG or run 'oc login'."
      failed=1
    fi
  fi

  # Verify cert-manager operator is installed
  if oc get namespace cert-manager-operator &>/dev/null; then
    ok "cert-manager-operator namespace exists"
    if oc get csv -n cert-manager-operator 2>/dev/null | grep -q "Succeeded"; then
      ok "cert-manager CSV phase: Succeeded"
    else
      warn "cert-manager CSV not yet Succeeded — it may still be installing."
      warn "Run: oc get csv -n cert-manager-operator"
      warn "Wait for phase 'Succeeded' before continuing."
      failed=1
    fi
  else
    error "cert-manager-operator namespace not found."
    echo "    Install first: oc apply -k cert-manager/operator/overlays/stable-v1" >&2
    failed=1
  fi

  return $failed
}

check_aws_prereqs() {
  info "Checking AWS prerequisites..."
  local failed=0
  check_binary aws \
    "https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html" \
    || failed=1
  if command -v aws &>/dev/null; then
    if aws sts get-caller-identity &>/dev/null; then
      ok "AWS credentials valid: $(aws sts get-caller-identity --query 'Arn' --output text)"
    else
      error "AWS credentials not configured or invalid."
      echo "    Run: aws configure  (or set AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)" >&2
      failed=1
    fi
  fi
  return $failed
}

check_gcp_prereqs() {
  info "Checking GCP prerequisites..."
  local failed=0
  check_binary gcloud \
    "https://cloud.google.com/sdk/docs/install" \
    || failed=1
  if command -v gcloud &>/dev/null; then
    if gcloud auth print-access-token &>/dev/null; then
      ok "gcloud authenticated: $(gcloud config get-value account 2>/dev/null)"
    else
      warn "gcloud not authenticated (may not be needed if using service account JSON)."
    fi
  fi
  return $failed
}

check_azure_prereqs() {
  info "Checking Azure prerequisites..."
  local failed=0
  check_binary az \
    "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" \
    || failed=1
  if command -v az &>/dev/null; then
    if az account show &>/dev/null; then
      ok "az logged in: $(az account show --query name -o tsv)"
    else
      warn "az not logged in (may not be needed if using service principal args directly)."
    fi
  fi
  return $failed
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}cert-manager setup-secrets — provider: ${CYAN}${PROVIDER}${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

INSTANCE_DIR="${SCRIPT_DIR}/instances/${PROVIDER}"
if [[ ! -d "$INSTANCE_DIR" ]]; then
  die "Unknown provider '${PROVIDER}'. Valid: ibm-cloud-kvm, aws, gcp, azure"
fi

INSTANCE_SCRIPT="${INSTANCE_DIR}/setup-secrets.sh"
if [[ ! -f "$INSTANCE_SCRIPT" ]]; then
  die "setup-secrets.sh not found in ${INSTANCE_DIR}"
fi

check_failed=0
check_common_prereqs || check_failed=1

case "$PROVIDER" in
  ibm-cloud-kvm|aws)
    check_aws_prereqs || check_failed=1
    ;;
  gcp)
    check_gcp_prereqs || check_failed=1
    ;;
  azure)
    check_azure_prereqs || check_failed=1
    ;;
esac

if [[ $check_failed -ne 0 ]]; then
  echo ""
  die "Prerequisites not met. Fix the issues above before continuing."
fi

echo ""
echo -e "${BOLD}Prerequisites satisfied. Running ${PROVIDER} setup...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

bash "$INSTANCE_SCRIPT" "$@"

echo ""
echo -e "${GREEN}${BOLD}Setup complete.${NC}"
echo ""
echo "Apply with:"
echo -e "  ${BOLD}oc apply -k cert-manager/instances/${PROVIDER}/${NC}"
