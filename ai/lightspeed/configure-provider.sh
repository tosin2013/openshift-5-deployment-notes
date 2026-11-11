#!/usr/bin/env bash
# Create the Lightspeed provider Secret with oc, then apply a temporary
# kustomize overlay for the non-secret fields. The token stays out of git.
set -euo pipefail

if [[ $- == *x* ]]; then
  echo "Refusing to run while xtrace is on (bash -x). That would print the token." >&2
  exit 1
fi

NS=openshift-lightspeed
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TMP_DIR=
cleanup() {
  if [[ -n "${TMP_DIR}" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

usage() {
  cat <<'EOF'
Usage: configure-provider.sh <provider>

Creates or updates the Secret in openshift-lightspeed, then applies a
temporary kustomize overlay on the catalog instance for that provider.
The overlay is not committed. The token stays in the Secret.
The Lightspeed operator must already be running there.
A second provider replaces the OLSConfig named cluster.

Set GITOPS_CATALOG to the openshift-lightspeed-operator directory, or to a
gitops-catalog checkout. The default is a checkout next to this repo.

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

catalog_dir() {
  local candidate
  if [[ -n "${GITOPS_CATALOG:-}" ]]; then
    if [[ -d "${GITOPS_CATALOG}/instance/overlays" ]]; then
      printf '%s\n' "${GITOPS_CATALOG}"
      return
    fi
    candidate="${GITOPS_CATALOG}/openshift-lightspeed-operator"
    if [[ -d "${candidate}/instance/overlays" ]]; then
      printf '%s\n' "${candidate}"
      return
    fi
    die "GITOPS_CATALOG does not contain the Lightspeed instance overlays: ${GITOPS_CATALOG}"
  fi
  candidate="$(cd "${ROOT}/../../.." && pwd)/gitops-catalog/openshift-lightspeed-operator"
  if [[ -d "${candidate}/instance/overlays" ]]; then
    printf '%s\n' "${candidate}"
    return
  fi
  die "Clone https://github.com/tosin2013/gitops-catalog next to this repo, or set GITOPS_CATALOG."
}

apply_kustomize() {
  local overlay=$1
  shift
  local catalog
  catalog="$(catalog_dir)"
  [[ -f "${catalog}/instance/overlays/${overlay}/kustomization.yaml" ]] || die "No kustomize overlay for ${overlay}."
  TMP_DIR=$(mktemp -d)
  # oc kustomize refuses an absolute resource path. Copy the instance tree
  # into the temp dir so the overlay and its base stay inside one root.
  cp -a "${catalog}/instance" "${TMP_DIR}/instance"
  python3 - "$TMP_DIR" "$overlay" "$@" <<'PY'
import json, pathlib, sys
tmp, overlay, *pairs = sys.argv[1:]
patches = []
for pair in pairs:
    path, value = pair.split("=", 1)
    patches.append({"op": "replace", "path": path, "value": value})
kustomization = {
    "apiVersion": "kustomize.config.k8s.io/v1beta1",
    "kind": "Kustomization",
    "resources": [f"instance/overlays/{overlay}"],
}
if patches:
    pathlib.Path(tmp, "patch.json").write_text(json.dumps(patches))
    kustomization["patches"] = [{
        "target": {
            "group": "ols.openshift.io",
            "version": "v1alpha1",
            "kind": "OLSConfig",
            "name": "cluster",
        },
        "path": "patch.json",
    }]
pathlib.Path(tmp, "kustomization.yaml").write_text(json.dumps(kustomization) + "\n")
PY
  oc apply -k "$TMP_DIR"
  rm -rf "$TMP_DIR"
  TMP_DIR=
}

apply_azure() {
  apply_kustomize azure-openai \
    "/spec/llm/providers/0/apiVersion=${AZURE_OPENAI_API_VERSION}" \
    "/spec/llm/providers/0/deploymentName=${AZURE_OPENAI_DEPLOYMENT}" \
    "/spec/llm/providers/0/url=${AZURE_OPENAI_URL}" \
    "/spec/llm/providers/0/models/0/name=${AZURE_OPENAI_MODEL}" \
    "/spec/ols/defaultModel=${AZURE_OPENAI_MODEL}"
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
    if [[ "$provider" == vertex-anthropic ]]; then
      apply_kustomize vertex-anthropic \
        "/spec/llm/providers/0/googleVertexAnthropicConfig/projectID=${GCP_PROJECT}"
    else
      apply_kustomize gemini-vertex \
        "/spec/llm/providers/0/googleVertexConfig/projectID=${GCP_PROJECT}"
    fi
    ;;
  gemini-api)
    require GEMINI_API_KEY
    apply_literal_secret gemini-api-keys \
      --from-literal="apitoken=${GEMINI_API_KEY}"
    pairs=()
    if [[ -n "${GEMINI_MODEL:-}" ]]; then
      require GEMINI_MODEL
      pairs+=("/spec/llm/providers/0/models/0/name=${GEMINI_MODEL}")
      pairs+=("/spec/ols/defaultModel=${GEMINI_MODEL}")
    fi
    apply_kustomize gemini-api "${pairs[@]}"
    ;;
  rhoai-vllm)
    require RHOAI_API_TOKEN
    require RHOAI_URL
    require_v1_url RHOAI_URL
    apply_literal_secret rhoai-api-keys \
      --from-literal="apitoken=${RHOAI_API_TOKEN}"
    pairs=("/spec/llm/providers/0/url=${RHOAI_URL}")
    if [[ -n "${RHOAI_MODEL:-}" ]]; then
      require RHOAI_MODEL
      pairs+=("/spec/llm/providers/0/models/0/name=${RHOAI_MODEL}")
      pairs+=("/spec/ols/defaultModel=${RHOAI_MODEL}")
    fi
    apply_kustomize rhoai-vllm "${pairs[@]}"
    ;;
  rhelai-vllm)
    require RHELAI_API_TOKEN
    require RHELAI_URL
    require RHELAI_MODEL
    require_v1_url RHELAI_URL
    apply_literal_secret rhelai-api-keys \
      --from-literal="apitoken=${RHELAI_API_TOKEN}"
    apply_kustomize rhelai-vllm \
      "/spec/llm/providers/0/url=${RHELAI_URL}" \
      "/spec/llm/providers/0/models/0/name=models/${RHELAI_MODEL}" \
      "/spec/ols/defaultModel=models/${RHELAI_MODEL}"
    ;;
  openai)
    require OPENAI_API_TOKEN
    require OPENAI_MODEL
    apply_literal_secret openai \
      --from-literal="apitoken=${OPENAI_API_TOKEN}"
    apply_kustomize openai \
      "/spec/llm/providers/0/models/0/name=${OPENAI_MODEL}" \
      "/spec/ols/defaultModel=${OPENAI_MODEL}"
    ;;
  azure-openai)
    require AZURE_OPENAI_API_KEY
    require AZURE_OPENAI_API_VERSION
    require AZURE_OPENAI_DEPLOYMENT
    require AZURE_OPENAI_URL
    require AZURE_OPENAI_MODEL
    apply_literal_secret azure-api-keys \
      --from-literal="apitoken=${AZURE_OPENAI_API_KEY}"
    apply_azure
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
    apply_azure
    ;;
  watsonx)
    require WATSONX_API_KEY
    require WATSONX_URL
    require WATSONX_PROJECT_ID
    require WATSONX_MODEL
    apply_literal_secret watsonx-api-keys \
      --from-literal="apitoken=${WATSONX_API_KEY}"
    apply_kustomize watsonx \
      "/spec/llm/providers/0/url=${WATSONX_URL}" \
      "/spec/llm/providers/0/projectID=${WATSONX_PROJECT_ID}" \
      "/spec/llm/providers/0/models/0/name=${WATSONX_MODEL}" \
      "/spec/ols/defaultModel=${WATSONX_MODEL}"
    ;;
  *)
    die "Unknown provider: ${provider}. Run with --help for the list."
    ;;
esac

echo
oc get olsconfig cluster
echo
echo "Applied ${provider}. Another provider replaces this same OLSConfig named cluster."
