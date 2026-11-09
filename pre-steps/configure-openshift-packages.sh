#!/bin/bash
# Install the OpenShift client and installer from a numbered openshift-v5 directory.
# RHEL 9 and newer. With no VERSION, -i uses the newest numbered 5.x directory.

set -euo pipefail

MIRROR="https://mirror.openshift.com/pub/openshift-v5/clients/ocp"
INSTALL_DIR="/usr/local/bin"

usage() {
  cat <<EOF
Usage:
  $0 -i [--ccoctl] [--opm]
  VERSION=<release> $0 -i [--ccoctl] [--opm]
  $0 -d
  $0 -h

RHEL 9 and newer. With no VERSION, -i selects the newest numbered 5.x
directory under ${MIRROR}/ that contains the client and the installer.
The directory named latest is not used. Set VERSION to pin a release:
  VERSION=5.0.1 $0 -i

-i, --install     Install oc, kubectl, and openshift-install
--ccoctl          Also install ccoctl from the same directory
--opm             Also install opm from the same directory
-d, --delete      Remove those binaries when the files are present
-h, --help        Show this help

--ccoctl is for manual cloud credentials and STS. --opm is for catalog work.
A normal -i does not install them.
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

resolve_version() {
  if [[ -n "${VERSION:-}" ]]; then
    if [[ "$VERSION" == *"/"* || "$VERSION" == *".."* || "$VERSION" == "." ]]; then
      echo "VERSION must be a single directory name, not a path." >&2
      exit 1
    fi
    return
  fi

  local index versions version listing
  echo "Listing ${MIRROR}/ for the newest numbered 5.x release"
  index="$(curl -fsSL --retry 3 "${MIRROR}/")"
  versions="$(grep -oE 'href="5\.[0-9]+\.[0-9]+/"' <<<"$index" | sed -E 's/.*href="([^/]+)\/".*/\1/' | sort -urV)"
  if [[ -z "$versions" ]]; then
    echo "No numbered 5.x directory was listed under ${MIRROR}/." >&2
    exit 1
  fi

  while IFS= read -r version; do
    [[ -z "$version" ]] && continue
    listing="$(curl -fsSL --retry 3 "${MIRROR}/${version}/")"
    if grep -Fq "openshift-client-linux-${version}.tar.gz" <<<"$listing" \
      && grep -Fq "openshift-install-linux-${version}.tar.gz" <<<"$listing"; then
      VERSION="$version"
      echo "Selected VERSION=${VERSION}"
      return
    fi
  done <<<"$versions"

  echo "No numbered 5.x directory contained both the client and the installer." >&2
  exit 1
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

listing_has() {
  grep -Fq "$1" <<<"$LISTING"
}

install_archive() {
  local versioned="$1"
  local archive="$2"
  shift 2

  if ! listing_has "$versioned"; then
    echo "The ${VERSION} listing does not contain ${versioned}." >&2
    exit 1
  fi

  local tmp bin
  tmp="$(mktemp -d)"
  curl -fL --retry 3 -o "${tmp}/${archive}" "${MIRROR}/${VERSION}/${archive}"
  tar -xzf "${tmp}/${archive}" -C "$tmp"
  for bin in "$@"; do
    if [[ ! -f "${tmp}/${bin}" ]]; then
      echo "${archive} does not contain ${bin}." >&2
      rm -rf "$tmp"
      exit 1
    fi
    run_root install -m 0755 "${tmp}/${bin}" "${INSTALL_DIR}/${bin}"
  done
  rm -rf "$tmp"
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

install_packages() {
  require_rhel9
  ensure_tools
  resolve_version

  echo "Listing ${MIRROR}/${VERSION}/"
  LISTING="$(curl -fsSL --retry 3 "${MIRROR}/${VERSION}/")"

  install_archive \
    "openshift-client-linux-${VERSION}.tar.gz" \
    "openshift-client-linux.tar.gz" \
    oc kubectl
  install_archive \
    "openshift-install-linux-${VERSION}.tar.gz" \
    "openshift-install-linux.tar.gz" \
    openshift-install

  oc version
  openshift-install version

  if [[ "$WITH_CCOCTL" -eq 1 ]]; then
    install_archive \
      "ccoctl-linux-${VERSION}.tar.gz" \
      "ccoctl-linux.tar.gz" \
      ccoctl
    if ccoctl version >/dev/null 2>&1; then
      ccoctl version
    else
      command -v ccoctl
    fi
  fi

  if [[ "$WITH_OPM" -eq 1 ]]; then
    install_archive \
      "opm-linux-${VERSION}.tar.gz" \
      "opm-linux.tar.gz" \
      opm
    opm version
  fi
}

delete_packages() {
  require_rhel9
  local reply
  read -r -p "Remove oc, kubectl, openshift-install, ccoctl, and opm from the path? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  remove_bin oc
  remove_bin kubectl
  remove_bin openshift-install
  remove_bin ccoctl
  remove_bin opm
}

INSTALL=0
DELETE=0
WITH_CCOCTL=0
WITH_OPM=0

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
    --ccoctl)
      WITH_CCOCTL=1
      ;;
    --opm)
      WITH_OPM=1
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
  delete_packages
else
  install_packages
fi
