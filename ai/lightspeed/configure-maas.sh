#!/usr/bin/env bash
# Point Lightspeed at an OpenAI-compatible endpoint.
# The URL, model, and token are read from the environment or from the prompt.
# This file does not store them. It calls configure-provider.sh for rhoai-vllm.
set -euo pipefail

if [[ $- == *x* ]]; then
  echo "Refusing to run while xtrace is on (bash -x). That would print the token." >&2
  exit 1
fi

ask() {
  local name=$1
  local prompt=$2
  local secret=${3:-}
  if [[ -n "${!name:-}" ]]; then
    return
  fi
  if [[ -t 0 ]]; then
    if [[ "$secret" == secret ]]; then
      read -rs -p "${prompt}: " "$name"
      echo
    else
      read -r -p "${prompt}: " "$name"
    fi
  else
    IFS= read -r "$name" || true
  fi
  if [[ -z "${!name:-}" ]]; then
    echo "Missing ${name}." >&2
    exit 1
  fi
}

# A pipe supplies one value per line, in this order: URL, model, token.
# A terminal asks for whichever of those is not already set.
ask RHOAI_URL "Endpoint URL, ending in /v1"
ask RHOAI_MODEL "Model id"
ask MAAS_API_TOKEN "API token" secret

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export RHOAI_URL RHOAI_MODEL
export RHOAI_API_TOKEN="${MAAS_API_TOKEN}"

exec "${ROOT}/configure-provider.sh" rhoai-vllm
