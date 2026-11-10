#!/bin/bash
# Mirror an OpenShift 5 release with oc-mirror plugin v2.
# oc adm release mirror is deprecated as of 4.22. This script does not run it.
# It does not install the registry, start a web server, or download RHCOS.

set -euo pipefail

CHANNEL="${CHANNEL:-stable-5.0}"
MIN_VERSION="${MIN_VERSION:-5.0.1}"
MAX_VERSION="${MAX_VERSION:-5.0.1}"
REGISTRY="${REGISTRY:-registry.example.com}"
REGISTRY_PORT="${REGISTRY_PORT:-8443}"
REGISTRY_USER="${REGISTRY_USER:-init}"
REGISTRY_EMAIL="${REGISTRY_EMAIL:-you@example.com}"
CATALOG="${CATALOG:-registry.redhat.io/redhat/redhat-operator-index:v5.0}"
WORKSPACE="${WORKSPACE:-${HOME}/oc-mirror}"
PULL_SECRET_JSON="${PULL_SECRET_JSON:-${HOME}/pull-secret.json}"
PACKAGES="${PACKAGES:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_SCRIPT="${SCRIPT_DIR}/../pre-steps/configure-openshift-packages.sh"

usage() {
  cat <<EOF
Usage:
  $0
  MIN_VERSION=5.0.1 MAX_VERSION=5.0.1 REGISTRY=registry.example.com $0
  PACKAGES=local-storage-operator,lvms-operator $0
  $0 -h

Writes an ImageSetConfiguration for channel ${CHANNEL} and runs
oc mirror --v2 to docker://\${REGISTRY}:\${REGISTRY_PORT}.
The default pin is ${MIN_VERSION}. The directory named latest is not used.

REGISTRY_USER and REGISTRY_PASSWORD are merged into
\$XDG_RUNTIME_DIR/containers/auth.json. The file is not printed.
When REGISTRY_PASSWORD is unset, that file must already contain the registry.

oc comes from pre-steps/configure-openshift-packages.sh when it is missing.
oc-mirror must already be on PATH. This script does not download it.
EOF
}

require_rhel9() {
  local major
  major="$(rpm -E '%{rhel}' 2>/dev/null || true)"
  if ! [[ "$major" =~ ^[0-9]+$ ]] || (( major < 9 )); then
    echo "This script supports RHEL 9 and newer." >&2
    exit 1
  fi
}

reject_token() {
  local value="$1" label="$2"
  if [[ -z "$value" || "$value" == *"/"* || "$value" == *".."* || "$value" == "." || "$value" == "latest" || "$value" == *$'\n'* ]]; then
    echo "${label} must be a single name, not a path or latest." >&2
    exit 1
  fi
}

reject_version() {
  local value="$1" label="$2"
  reject_token "$value" "$label"
  if ! [[ "$value" =~ ^[0-9]+(\.[0-9]+){1,2}(-[0-9A-Za-z.]+)?$ ]]; then
    echo "${label} must look like 5.0.1." >&2
    exit 1
  fi
}

ensure_oc() {
  if command -v oc >/dev/null 2>&1; then
    return
  fi
  if [[ ! -x "$PACKAGES_SCRIPT" ]]; then
    echo "oc is not on PATH, and ${PACKAGES_SCRIPT} is missing." >&2
    exit 1
  fi
  "$PACKAGES_SCRIPT" -i
}

ensure_oc_mirror() {
  if ! command -v oc-mirror >/dev/null 2>&1; then
    echo "oc-mirror is not on PATH." >&2
    echo "Download oc-mirror.tar.gz from the OpenShift downloads page. See disconnected-scripts/README.md." >&2
    exit 1
  fi
}

auth_file() {
  if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    if [[ -d "/run/user/$(id -u)" ]]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    else
      echo "XDG_RUNTIME_DIR is not set." >&2
      exit 1
    fi
  fi
  printf '%s\n' "${XDG_RUNTIME_DIR}/containers/auth.json"
}

prepare_auth() {
  local dest
  dest="$(auth_file)"
  mkdir -p "$(dirname "$dest")"
  if [[ ! -f "$dest" ]]; then
    if [[ ! -f "$PULL_SECRET_JSON" ]]; then
      echo "Save the pull secret as ${PULL_SECRET_JSON}, or create ${dest} first." >&2
      exit 1
    fi
    cp "$PULL_SECRET_JSON" "$dest"
    chmod 600 "$dest"
  fi
  if [[ -z "${REGISTRY_PASSWORD:-}" ]]; then
    return
  fi
  if [[ "$REGISTRY_PASSWORD" == "CHANGEME" || "$REGISTRY_PASSWORD" == *$'\n'* ]]; then
    echo "REGISTRY_PASSWORD must be the registry password. Do not use CHANGEME." >&2
    exit 1
  fi
  reject_token "$REGISTRY_USER" "REGISTRY_USER"
  export AUTH_DEST="$dest"
  export REGISTRY REGISTRY_PORT REGISTRY_USER REGISTRY_PASSWORD REGISTRY_EMAIL
  python3 - <<'PY'
import base64, json, os
dest = os.environ["AUTH_DEST"]
registry = os.environ["REGISTRY"] + ":" + os.environ["REGISTRY_PORT"]
user = os.environ["REGISTRY_USER"]
password = os.environ["REGISTRY_PASSWORD"]
email = os.environ["REGISTRY_EMAIL"]
with open(dest, encoding="utf-8") as handle:
    data = json.load(handle)
if not isinstance(data, dict):
    raise SystemExit("auth.json is not a JSON object")
auths = data.setdefault("auths", {})
if not isinstance(auths, dict):
    raise SystemExit("auth.json auths is not an object")
token = base64.b64encode(f"{user}:{password}".encode()).decode()
auths[registry] = {"auth": token, "email": email}
with open(dest, "w", encoding="utf-8") as handle:
    json.dump(data, handle)
os.chmod(dest, 0o600)
PY
}

write_imageset() {
  local dest="$1" pkg
  mkdir -p "$(dirname "$dest")"
  {
    cat <<EOF
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
mirror:
  platform:
    channels:
    - name: ${CHANNEL}
      minVersion: ${MIN_VERSION}
      maxVersion: ${MAX_VERSION}
    graph: true
EOF
    if [[ -n "$PACKAGES" ]]; then
      printf '  operators:\n    - catalog: %s\n      packages:\n' "$CATALOG"
      local IFS=','
      read -ra pkgs <<< "$PACKAGES"
      for pkg in "${pkgs[@]}"; do
        pkg="${pkg#"${pkg%%[![:space:]]*}"}"
        pkg="${pkg%"${pkg##*[![:space:]]}"}"
        reject_token "$pkg" "PACKAGES"
        printf '        - name: %s\n' "$pkg"
      done
    fi
  } > "$dest"
}

main() {
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
    "")
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac

  require_rhel9
  reject_token "$CHANNEL" "CHANNEL"
  reject_version "$MIN_VERSION" "MIN_VERSION"
  reject_version "$MAX_VERSION" "MAX_VERSION"
  reject_token "$REGISTRY" "REGISTRY"
  if [[ "$REGISTRY" =~ ^[0-9.]+$ ]]; then
    echo "REGISTRY must be a DNS name. An IP address is not accepted." >&2
    exit 1
  fi
  if ! [[ "$REGISTRY_PORT" =~ ^[0-9]+$ ]]; then
    echo "REGISTRY_PORT must be a port number." >&2
    exit 1
  fi

  umask 0022
  ensure_oc
  ensure_oc_mirror
  prepare_auth
  write_imageset "${WORKSPACE}/imageset-config.yaml"
  oc mirror -c "${WORKSPACE}/imageset-config.yaml" \
    --workspace "file://${WORKSPACE}" \
    --v2 \
    "docker://${REGISTRY}:${REGISTRY_PORT}"
  echo "Cluster resources: ${WORKSPACE}/working-dir/cluster-resources"
}

main "$@"
