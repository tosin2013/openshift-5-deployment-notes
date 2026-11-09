#!/usr/bin/env bash
# Create the Lightspeed provider Secret from the environment, fill non-secret
# placeholders, and apply that provider's OLSConfig. Tokens stay out of git.
set -euo pipefail

if [[ $- == *x* ]]; then
  echo "Refusing to run while xtrace is on (bash -x). That would print the token." >&2
  exit 1
fi

NS=openshift-lightspeed
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROVIDERS="${ROOT}/providers"
TMP_RENDER=
cleanup() {
  if [[ -n "${TMP_RENDER}" ]]; then
    rm -f "$TMP_RENDER"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: configure-provider.sh <provider>

Creates or updates the Secret in openshift-lightspeed, then applies the
matching OLSConfig. The Lightspeed operator must already be running there.
A second provider replaces the OLSConfig named cluster.

  vertex-anthropic   GCP_SERVICE_ACCOUNT_JSON GCP_PROJECT
  gemini-vertex      GCP_SERVICE_ACCOUNT_JSON GCP_PROJECT
  gemini-api         GEMINI_API_KEY
                     optional GEMINI_MODEL (default gemini-4-argon)
  rhoai-vllm         RHOAI_API_TOKEN RHOAI_URL (ends in /v1)
                     optional RHOAI_MODEL (default granite-4-0-h-tiny)
  rhelai-vllm        RHELAI_API_TOKEN RHELAI_URL (ends in /v1)
                     RHELAI_MODEL (name after the models/ prefix)
  openai             OPENAI_API_TOKEN OPENAI_MODEL
  azure-openai       AZURE_OPENAI_API_KEY AZURE_OPENAI_API_VERSION
                     AZURE_OPENAI_DEPLOYMENT AZURE_OPENAI_URL AZURE_OPENAI_MODEL
  azure-entra        AZURE_CLIENT_ID AZURE_CLIENT_SECRET AZURE_TENANT_ID
                     AZURE_OPENAI_API_VERSION AZURE_OPENAI_DEPLOYMENT
                     AZURE_OPENAI_URL AZURE_OPENAI_MODEL
  watsonx            WATSONX_API_KEY WATSONX_URL WATSONX_PROJECT_ID
                     WATSONX_MODEL (full id, including the ibm/ prefix)

Example:
  GCP_SERVICE_ACCOUNT_JSON=/path/to/key.json GCP_PROJECT=my-project \
    ./ai/lightspeed/configure-provider.sh vertex-anthropic
EOF
}

die() {
  echo "$1" >&2
  exit 1
}

require() {
  local name=$1
  if [[ -z "${!name:-}" ]]; then
    die "Set ${name}."
  fi
  if [[ "${!name}" == *$'\n'* ]]; then
    die "${name} contains a newline."
  fi
}

require_operator() {
  local ready
  ready=$(oc get deploy lightspeed-operator-controller-manager -n "$NS" \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)
  if [[ "${ready:-0}" -lt 1 ]]; then
    die "Lightspeed operator is not running in ${NS}. Wait until deployment/lightspeed-operator-controller-manager has a ready pod."
  fi
}

require_v1_url() {
  local name=$1
  local value=${!name}
  value=${value%/}
  [[ "$value" == */v1 ]] || die "${name} must end in /v1."
  printf -v "$name" '%s' "$value"
}

apply_literal_secret() {
  local name=$1
  shift
  oc create secret generic "$name" \
    "$@" \
    -n "$NS" \
    --dry-run=client -o yaml | oc apply -f -
}

render_apply() {
  local src=$1
  shift
  TMP_RENDER=$(mktemp)
  python3 - "$src" "$TMP_RENDER" "$@" <<'PY'
import pathlib, sys
src, dest, *pairs = sys.argv[1:]
text = pathlib.Path(src).read_text()
for pair in pairs:
    old, new = pair.split("=", 1)
    if old not in text:
        sys.exit(f"placeholder {old} not found in {src}")
    text = text.replace(old, new)
if "REPLACE_WITH_" in text:
    sys.exit("rendered OLSConfig still contains REPLACE_WITH_")
pathlib.Path(dest).write_text(text)
PY
  oc apply -f "$TMP_RENDER"
  rm -f "$TMP_RENDER"
  TMP_RENDER=
}

if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
  usage
  exit 0
fi
if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

provider=$1
oc get ns "$NS" >/dev/null 2>&1 || die "Namespace ${NS} was not found. Install the OpenShift Lightspeed operator first."
require_operator

case "$provider" in
  vertex-anthropic|gemini-vertex)
    require GCP_SERVICE_ACCOUNT_JSON
    require GCP_PROJECT
    [[ -f "$GCP_SERVICE_ACCOUNT_JSON" ]] || die "GCP_SERVICE_ACCOUNT_JSON is not a file: ${GCP_SERVICE_ACCOUNT_JSON}"
    apply_literal_secret llmcreds \
      --from-file="gcp-service-account.json=${GCP_SERVICE_ACCOUNT_JSON}"
    src="${PROVIDERS}/${provider}.yaml"
    render_apply "$src" "REPLACE_WITH_GCP_PROJECT=${GCP_PROJECT}"
    ;;
  gemini-api)
    require GEMINI_API_KEY
    apply_literal_secret gemini-api-keys \
      --from-literal="apitoken=${GEMINI_API_KEY}"
    pairs=()
    if [[ -n "${GEMINI_MODEL:-}" ]]; then
      require GEMINI_MODEL
      pairs+=("name: gemini-4-argon=name: ${GEMINI_MODEL}")
      pairs+=("defaultModel: gemini-4-argon=defaultModel: ${GEMINI_MODEL}")
    fi
    render_apply "${PROVIDERS}/gemini-api.yaml" "${pairs[@]}"
    ;;
  rhoai-vllm)
    require RHOAI_API_TOKEN
    require RHOAI_URL
    require_v1_url RHOAI_URL
    apply_literal_secret rhoai-api-keys \
      --from-literal="apitoken=${RHOAI_API_TOKEN}"
    pairs=("https://REPLACE_WITH_HOST/v1=${RHOAI_URL}")
    if [[ -n "${RHOAI_MODEL:-}" ]]; then
      require RHOAI_MODEL
      pairs+=("name: granite-4-0-h-tiny=name: ${RHOAI_MODEL}")
      pairs+=("defaultModel: granite-4-0-h-tiny=defaultModel: ${RHOAI_MODEL}")
    fi
    render_apply "${PROVIDERS}/rhoai-vllm.yaml" "${pairs[@]}"
    ;;
  rhelai-vllm)
    require RHELAI_API_TOKEN
    require RHELAI_URL
    require RHELAI_MODEL
    require_v1_url RHELAI_URL
    apply_literal_secret rhelai-api-keys \
      --from-literal="apitoken=${RHELAI_API_TOKEN}"
    render_apply "${PROVIDERS}/rhelai-vllm.yaml" \
      "https://REPLACE_WITH_HOST/v1=${RHELAI_URL}" \
      "REPLACE_WITH_MODEL=${RHELAI_MODEL}"
    ;;
  openai)
    require OPENAI_API_TOKEN
    require OPENAI_MODEL
    apply_literal_secret openai \
      --from-literal="apitoken=${OPENAI_API_TOKEN}"
    render_apply "${PROVIDERS}/openai.yaml" \
      "REPLACE_WITH_MODEL=${OPENAI_MODEL}"
    ;;
  azure-openai)
    require AZURE_OPENAI_API_KEY
    require AZURE_OPENAI_API_VERSION
    require AZURE_OPENAI_DEPLOYMENT
    require AZURE_OPENAI_URL
    require AZURE_OPENAI_MODEL
    apply_literal_secret azure-api-keys \
      --from-literal="apitoken=${AZURE_OPENAI_API_KEY}"
    render_apply "${PROVIDERS}/azure-openai.yaml" \
      "REPLACE_WITH_AZURE_API_VERSION=${AZURE_OPENAI_API_VERSION}" \
      "REPLACE_WITH_AZURE_DEPLOYMENT=${AZURE_OPENAI_DEPLOYMENT}" \
      "https://REPLACE_WITH_RESOURCE.openai.azure.com/=${AZURE_OPENAI_URL}" \
      "REPLACE_WITH_MODEL=${AZURE_OPENAI_MODEL}"
    ;;
  azure-entra)
    require AZURE_CLIENT_ID
    require AZURE_CLIENT_SECRET
    require AZURE_TENANT_ID
    require AZURE_OPENAI_API_VERSION
    require AZURE_OPENAI_DEPLOYMENT
    require AZURE_OPENAI_URL
    require AZURE_OPENAI_MODEL
    apply_literal_secret azure-api-keys \
      --from-literal="client_id=${AZURE_CLIENT_ID}" \
      --from-literal="client_secret=${AZURE_CLIENT_SECRET}" \
      --from-literal="tenant_id=${AZURE_TENANT_ID}"
    render_apply "${PROVIDERS}/azure-openai.yaml" \
      "REPLACE_WITH_AZURE_API_VERSION=${AZURE_OPENAI_API_VERSION}" \
      "REPLACE_WITH_AZURE_DEPLOYMENT=${AZURE_OPENAI_DEPLOYMENT}" \
      "https://REPLACE_WITH_RESOURCE.openai.azure.com/=${AZURE_OPENAI_URL}" \
      "REPLACE_WITH_MODEL=${AZURE_OPENAI_MODEL}"
    ;;
  watsonx)
    require WATSONX_API_KEY
    require WATSONX_URL
    require WATSONX_PROJECT_ID
    require WATSONX_MODEL
    apply_literal_secret watsonx-api-keys \
      --from-literal="apitoken=${WATSONX_API_KEY}"
    render_apply "${PROVIDERS}/watsonx.yaml" \
      "https://REPLACE_WITH_WATSONX_HOST=${WATSONX_URL}" \
      "REPLACE_WITH_PROJECT_ID=${WATSONX_PROJECT_ID}" \
      "ibm/REPLACE_WITH_MODEL=${WATSONX_MODEL}"
    ;;
  *)
    die "Unknown provider: ${provider}. Run with --help for the list."
    ;;
esac

echo
oc get olsconfig cluster
echo
echo "Applied ${provider}. Another provider replaces this same OLSConfig named cluster."
