#!/bin/bash
# Create an OpenShift cluster on AWS with the installer already on PATH.
# The client and installer come from ../pre-steps/configure-openshift-packages.sh.
#
# install-config.yaml is required before create cluster. This script runs
# create install-config only when that file is missing, then stops so it can
# be edited. The next run copies the file and creates the cluster.

set -euo pipefail

INSTALL_DIR="${HOME}/cluster"
KEY="${HOME}/.ssh/cluster-key"

if ! command -v openshift-install >/dev/null 2>&1; then
  echo "openshift-install is not on PATH. From the repo root, run: pre-steps/configure-openshift-packages.sh -i" >&2
  exit 1
fi

mkdir -p "$(dirname "$KEY")"
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -N '' -f "$KEY"
fi
chmod 400 "$KEY"
eval "$(ssh-agent -s)"
ssh-add "$KEY"
echo "SSH public key: ${KEY}.pub"
echo "For FIPS, create an rsa or ecdsa key instead of this ed25519 key."

if [[ -d "$INSTALL_DIR" ]]; then
  while IFS= read -r -d '' path; do
    if [[ "$(basename "$path")" != "install-config.yaml" ]]; then
      echo "${INSTALL_DIR} already has installation assets. Use a new directory." >&2
      exit 1
    fi
  done < <(find "$INSTALL_DIR" -mindepth 1 -print0)
fi

if [[ ! -f "${INSTALL_DIR}/install-config.yaml" ]]; then
  mkdir -p "$INSTALL_DIR"
  openshift-install create install-config --dir "$INSTALL_DIR"
  echo "Edit ${INSTALL_DIR}/install-config.yaml if you need to, then run this script again."
  exit 0
fi

cp "${INSTALL_DIR}/install-config.yaml" "${HOME}/cluster-install-config.yaml"
openshift-install create cluster --dir "$INSTALL_DIR" --log-level=debug
