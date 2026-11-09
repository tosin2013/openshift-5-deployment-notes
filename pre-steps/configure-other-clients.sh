#!/bin/bash
# Install Helm, rosa, butane, coreos-installer, and mirror-registry.
# These are not in the OpenShift release directory. RHEL 9 and newer.
# With no version variable, -i uses the newest numbered directory for that tool.
# The directory named latest is not used.

set -euo pipefail

HELM_BASE="https://mirror.openshift.com/pub/cgw/helm"
ROSA_BASE="https://mirror.openshift.com/pub/openshift-v5/clients/rosa"
BUTANE_BASE="https://mirror.openshift.com/pub/openshift-v5/clients/butane"
COREOS_BASE="https://mirror.openshift.com/pub/openshift-v5/clients/coreos-installer"
MIRROR_REGISTRY_BASE="https://mirror.openshift.com/pub/openshift-v4/clients/mirror-registry"
INSTALL_DIR="/usr/local/bin"
MIRROR_REGISTRY_DIR="${HOME}/mirror-registry"
CURL_UA="Mozilla/5.0 (compatible; openshift-field-notes)"

usage() {
  cat <<EOF
Usage:
  $0 -i --helm [--rosa] [--butane] [--coreos-installer] [--mirror-registry]
  HELM_VERSION=<dir> $0 -i --helm
  $0 -d
  $0 -h

RHEL 9 and newer. -i installs only the tools named on the command line.
With no version variable, each tool uses the newest numbered directory that
contains its file. The directory named latest is not used.

Pin a directory with HELM_VERSION, ROSA_VERSION, BUTANE_VERSION,
COREOS_INSTALLER_VERSION, or MIRROR_REGISTRY_VERSION.

-i, --install           Install the tools named with the flags below
--helm                  Install helm to ${INSTALL_DIR}
--rosa                  Install rosa to ${INSTALL_DIR}
--butane                Install butane to ${INSTALL_DIR}
--coreos-installer      Install coreos-installer to ${INSTALL_DIR}
--mirror-registry       Extract mirror-registry to ${MIRROR_REGISTRY_DIR}
-d, --delete            Remove those installs when they are present
-h, --help              Show this help

--mirror-registry does not run mirror-registry install.
-d does not run mirror-registry uninstall.
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

run_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

ensure_tools() {
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=(curl)
  command -v tar >/dev/null 2>&1 || missing+=(tar)
  if (( ${#missing[@]} > 0 )); then
    run_root dnf install -y "${missing[@]}"
  fi
}

curl_get() {
  curl -fL --retry 3 -A "$CURL_UA" "$@"
}

reject_version() {
  local value="$1" label="$2"
  if [[ "$value" == *"/"* || "$value" == *".."* || "$value" == "." || "$value" == "latest" ]]; then
    echo "${label} must be a single directory name, not a path." >&2
    exit 1
  fi
}

resolve_tool_version() {
  local base_url="$1" marker="$2" pinned="$3" label="$4"
  local version listing versions index
  if [[ -n "$pinned" ]]; then
    reject_version "$pinned" "$label"
    listing="$(curl_get -fsS "${base_url}/${pinned}/")"
    if ! grep -Fq "$marker" <<<"$listing"; then
      echo "${base_url}/${pinned}/ does not contain ${marker}." >&2
      exit 1
    fi
    printf '%s\n' "$pinned"
    return
  fi

  echo "Listing ${base_url}/ for the newest numbered ${label} release" >&2
  index="$(curl_get -fsS "${base_url}/")"
  versions="$(grep -oE 'href="[^"]+/"' <<<"$index" \
    | sed -E 's/.*href="([^"]+)".*/\1/' \
    | awk -F/ '{print $(NF-1)}' \
    | grep -E '^(v?[0-9]+(\.[0-9]+)*(-[0-9A-Za-z.]+)?)$' \
    | sort -urV || true)"
  if [[ -z "$versions" ]]; then
    echo "No numbered directory was listed under ${base_url}/." >&2
    exit 1
  fi

  while IFS= read -r version; do
    [[ -z "$version" ]] && continue
    listing="$(curl_get -fsS "${base_url}/${version}/")"
    if grep -Fq "$marker" <<<"$listing"; then
      echo "Selected ${label} ${version}" >&2
      printf '%s\n' "$version"
      return
    fi
  done <<<"$versions"

  echo "No numbered directory under ${base_url}/ contained ${marker}." >&2
  exit 1
}

arch_name() {
  local kind="$1" machine
  machine="$(uname -m)"
  case "$kind:$machine" in
    helm:x86_64|helm:amd64|coreos:x86_64|coreos:amd64) printf '%s\n' amd64 ;;
    helm:aarch64|helm:arm64|coreos:aarch64|coreos:arm64) printf '%s\n' arm64 ;;
    butane:x86_64|butane:amd64) printf '%s\n' amd64 ;;
    butane:aarch64|butane:arm64) printf '%s\n' aarch64 ;;
    helm:ppc64le|butane:ppc64le|coreos:ppc64le) printf '%s\n' ppc64le ;;
    helm:s390x|butane:s390x|coreos:s390x) printf '%s\n' s390x ;;
    *)
      echo "Unsupported architecture: ${machine}" >&2
      exit 1
      ;;
  esac
}

install_member() {
  local url="$1" member="$2" dest_name="$3"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  curl_get -o "${tmp}/download" "$url"
  if [[ "$url" == *.tar.gz ]]; then
    tar -xzf "${tmp}/download" -C "$tmp"
  else
    mv "${tmp}/download" "${tmp}/${member}"
  fi
  if [[ ! -f "${tmp}/${member}" ]]; then
    echo "${url} does not contain ${member}." >&2
    exit 1
  fi
  run_root install -m 0755 "${tmp}/${member}" "${INSTALL_DIR}/${dest_name}"
}

install_helm() {
  local arch archive version
  arch="$(arch_name helm)"
  archive="helm-linux-${arch}.tar.gz"
  version="$(resolve_tool_version "$HELM_BASE" "$archive" "${HELM_VERSION:-}" "helm")"
  install_member "${HELM_BASE}/${version}/${archive}" "helm-linux-${arch}" helm
  helm version
}

install_rosa() {
  local version
  version="$(resolve_tool_version "$ROSA_BASE" "rosa-linux.tar.gz" "${ROSA_VERSION:-}" "rosa")"
  install_member "${ROSA_BASE}/${version}/rosa-linux.tar.gz" rosa rosa
  rosa version
}

install_butane() {
  local arch file version
  arch="$(arch_name butane)"
  file="butane-${arch}"
  version="$(resolve_tool_version "$BUTANE_BASE" "$file" "${BUTANE_VERSION:-}" "butane")"
  install_member "${BUTANE_BASE}/${version}/${file}" "$file" butane
  butane --version
}

install_coreos_installer() {
  local arch file version
  arch="$(arch_name coreos)"
  file="coreos-installer_${arch}"
  version="$(resolve_tool_version "$COREOS_BASE" "$file" "${COREOS_INSTALLER_VERSION:-}" "coreos-installer")"
  install_member "${COREOS_BASE}/${version}/${file}" "$file" coreos-installer
  coreos-installer --version
}

install_mirror_registry() {
  local version url tmp dest
  version="$(resolve_tool_version "$MIRROR_REGISTRY_BASE" "mirror-registry.tar.gz" "${MIRROR_REGISTRY_VERSION:-}" "mirror-registry")"
  dest="$MIRROR_REGISTRY_DIR"
  if [[ -e "$dest" ]] && [[ -n "$(ls -A "$dest" 2>/dev/null)" ]]; then
    echo "${dest} is not empty. Remove it before installing again." >&2
    exit 1
  fi
  mkdir -p "$dest"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  url="${MIRROR_REGISTRY_BASE}/${version}/mirror-registry.tar.gz"
  echo "Downloading ${url}"
  curl_get -o "${tmp}/mirror-registry.tar.gz" "$url"
  tar -xzf "${tmp}/mirror-registry.tar.gz" -C "$dest"
  if [[ ! -f "${dest}/mirror-registry" ]]; then
    echo "mirror-registry.tar.gz did not contain mirror-registry." >&2
    exit 1
  fi
  chmod 755 "${dest}/mirror-registry"
  echo "Extracted mirror-registry ${version} to ${dest}"
  echo "It does not run mirror-registry install."
}

remove_bin() {
  local name="$1" dir
  for dir in "$INSTALL_DIR" /usr/bin; do
    if [[ -e "${dir}/${name}" ]]; then
      run_root rm -f "${dir}/${name}"
      echo "Removed ${dir}/${name}"
    fi
  done
}

delete_clients() {
  require_rhel9
  local reply dest
  read -r -p "Remove helm, rosa, butane, and coreos-installer from the path when those files are present? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    remove_bin helm
    remove_bin rosa
    remove_bin butane
    remove_bin coreos-installer
  else
    echo "Left the binaries in place."
  fi

  dest="$MIRROR_REGISTRY_DIR"
  read -r -p "Remove ${dest}? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    if [[ -e "$dest" ]]; then
      if [[ -w "$dest" ]]; then
        rm -rf "$dest"
      else
        run_root rm -rf "$dest"
      fi
      echo "Removed ${dest}"
    else
      echo "${dest} is not present."
    fi
  else
    echo "Left ${dest} in place."
  fi
}

install_clients() {
  require_rhel9
  ensure_tools
  if [[ "$WITH_HELM" -eq 0 && "$WITH_ROSA" -eq 0 && "$WITH_BUTANE" -eq 0 \
    && "$WITH_COREOS" -eq 0 && "$WITH_MIRROR_REGISTRY" -eq 0 ]]; then
    echo "Name at least one tool to install." >&2
    usage >&2
    exit 1
  fi
  if [[ "$WITH_HELM" -eq 1 ]]; then
    install_helm
  fi
  if [[ "$WITH_ROSA" -eq 1 ]]; then
    install_rosa
  fi
  if [[ "$WITH_BUTANE" -eq 1 ]]; then
    install_butane
  fi
  if [[ "$WITH_COREOS" -eq 1 ]]; then
    install_coreos_installer
  fi
  if [[ "$WITH_MIRROR_REGISTRY" -eq 1 ]]; then
    install_mirror_registry
  fi
}

INSTALL=0
DELETE=0
WITH_HELM=0
WITH_ROSA=0
WITH_BUTANE=0
WITH_COREOS=0
WITH_MIRROR_REGISTRY=0

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      -i|--install)
        INSTALL=1
        ;;
      -d|--delete)
        DELETE=1
        ;;
      --helm)
        WITH_HELM=1
        ;;
      --rosa)
        WITH_ROSA=1
        ;;
      --butane)
        WITH_BUTANE=1
        ;;
      --coreos-installer)
        WITH_COREOS=1
        ;;
      --mirror-registry)
        WITH_MIRROR_REGISTRY=1
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  if [[ "$INSTALL" -eq 1 && "$DELETE" -eq 1 ]]; then
    echo "Choose -i or -d, not both." >&2
    exit 1
  fi

  if [[ "$INSTALL" -eq 0 && "$DELETE" -eq 0 ]]; then
    usage >&2
    exit 1
  fi

  if [[ "$DELETE" -eq 1 ]]; then
    delete_clients
  else
    install_clients
  fi
fi
