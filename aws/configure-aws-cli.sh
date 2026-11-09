#!/bin/bash
# Install AWS CLI v2 and write the default profile. RHEL 9 and newer.
# -i takes the access key, secret key, and region. It does not print them.

set -euo pipefail

usage() {
  cat <<EOF
${0} [OPTION]

 Options:
  -i, --install     Install awscli latest binaries
  -d, --delete      Remove awscli
  -h, --help        Display this help and exit

  USAGE: $0 -i aws_access_key_id aws_secret_access_key aws_region

RHEL 9 and newer. The zip is unpacked in a temporary directory, not in this aws/ folder.
The access key and secret go to ~/.aws/credentials. The region goes to ~/.aws/config.
The script does not print those files. Do not commit them.
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
  command -v unzip >/dev/null 2>&1 || missing+=(unzip)
  if (( ${#missing[@]} > 0 )); then
    run_root dnf install -y "${missing[@]}"
  fi
}

zip_name() {
  case "$(uname -m)" in
    x86_64|amd64) echo "awscli-exe-linux-x86_64.zip" ;;
    aarch64|arm64) echo "awscli-exe-linux-aarch64.zip" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

write_profile() {
  local access_key="$1" secret_key="$2" region="$3"
  if [[ -z "$access_key" || -z "$secret_key" || -z "$region" ]]; then
    echo "Missing access key, secret key, or region." >&2
    usage >&2
    exit 1
  fi
  if [[ "$access_key" == *$'\n'* || "$secret_key" == *$'\n'* || "$region" == *$'\n'* ]]; then
    echo "Access key, secret key, and region must be one line each." >&2
    exit 1
  fi

  mkdir -p "${HOME}/.aws"
  printf '%s\n' \
    '[default]' \
    "aws_access_key_id = ${access_key}" \
    "aws_secret_access_key = ${secret_key}" \
    > "${HOME}/.aws/credentials"
  printf '%s\n' \
    '[default]' \
    "region = ${region}" \
    'output = json' \
    > "${HOME}/.aws/config"
  chmod 600 "${HOME}/.aws/credentials" "${HOME}/.aws/config"
}

install_aws_cli() {
  local access_key="$1" secret_key="$2" region="$3"
  require_rhel9
  ensure_tools

  local tmp zip
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  zip="$(zip_name)"
  curl -fL --retry 3 -o "${tmp}/${zip}" "https://awscli.amazonaws.com/${zip}"
  unzip -q "${tmp}/${zip}" -d "$tmp"
  run_root "${tmp}/aws/install"
  aws --version
  write_profile "$access_key" "$secret_key" "$region"
  aws sts get-caller-identity
}

delete_aws_cli() {
  require_rhel9
  local reply
  read -r -p "Remove the AWS CLI from /usr/local? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  run_root rm -f /usr/local/bin/aws /usr/local/bin/aws_completer
  run_root rm -rf /usr/local/aws-cli
  echo "Removed /usr/local/bin/aws and /usr/local/aws-cli."
}

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 1
fi

case "$1" in
  -h|--help)
    usage
    ;;
  -i|--install)
    if [[ $# -lt 4 ]]; then
      echo "Missing access key, secret key, or region." >&2
      usage >&2
      exit 1
    fi
    install_aws_cli "$2" "$3" "$4"
    ;;
  -d|--delete)
    delete_aws_cli
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
esac
