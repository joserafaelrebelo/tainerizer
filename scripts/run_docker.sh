#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

"${ROOT_DIR}/scripts/setup.sh" >/dev/null

set -a
source .env
set +a

SERVICE="${1:-cuda130-devel}"
if [[ $# -gt 0 ]]; then
  shift
fi

export WORKSPACE_HOST_BIND="${WORKSPACE_HOST_BIND:-..}"
WORKSPACE_HOST_ABS="$(realpath -m "${WORKSPACE_HOST_BIND}")"
WORKSPACE_NAME="$(basename "${WORKSPACE_HOST_ABS}")"
export WORKSPACE_CONTAINER_DIR="${WORKSPACE_CONTAINER_DIR:-/workspace/${WORKSPACE_NAME}}"
export HF_CACHE_BIND="${HF_CACHE_BIND:-../.cache/huggingface}"
export UV_CACHE_BIND="${UV_CACHE_BIND:-../.cache/uv}"
export HF_CACHE_CONTAINER_PATH="${HF_CACHE_CONTAINER_PATH:-${WORKSPACE_CONTAINER_DIR}/.cache/huggingface}"
export UV_CACHE_CONTAINER_PATH="${UV_CACHE_CONTAINER_PATH:-${WORKSPACE_CONTAINER_DIR}/.cache/uv}"

mkdir -p "${HF_CACHE_BIND}" "${UV_CACHE_BIND}"

COMPOSE_ARGS=()
if [[ "${GUI:-0}" == "1" ]]; then
  if [[ -z "${DISPLAY:-}" ]]; then
    echo "GUI=1 requires DISPLAY to be set on the host." >&2
    exit 1
  fi

  export XAUTHORITY="${XAUTHORITY:-${HOME}/.Xauthority}"
  if [[ ! -e "${XAUTHORITY}" ]]; then
    echo "GUI=1 requires an Xauthority file at ${XAUTHORITY}." >&2
    exit 1
  fi

  COMPOSE_ARGS=(-f compose.yaml -f compose.gui.yaml)
fi

if [[ $# -gt 0 ]]; then
  exec docker compose "${COMPOSE_ARGS[@]}" run --rm "${SERVICE}" "$@"
fi

exec docker compose "${COMPOSE_ARGS[@]}" run --rm "${SERVICE}"
