#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

"${ROOT_DIR}/scripts/setup.sh" >/dev/null

set -a
source .env
set +a

SIF_PATH="${1:-dist/cuda130-devel.sif}"
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

APPTAINER_BIN="${APPTAINER_BIN:-apptainer}"
BIND_ARGS=(
  --bind "${WORKSPACE_HOST_BIND}:${WORKSPACE_CONTAINER_DIR}"
  --bind "${HF_CACHE_BIND}:${HF_CACHE_CONTAINER_PATH}"
  --bind "${UV_CACHE_BIND}:${UV_CACHE_CONTAINER_PATH}"
  --bind "${HF_CACHE_BIND}:/root/.cache/huggingface"
  --bind "${UV_CACHE_BIND}:/root/.cache/uv"
)

ENV_ARGS=()
while IFS= read -r key; do
  if [[ -n "${!key+x}" ]]; then
    ENV_ARGS+=(--env "${key}=${!key}")
  fi
done < <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' .env | cut -d '=' -f 1)

if [[ $# -gt 0 ]]; then
  exec "${APPTAINER_BIN}" exec --nv "${ENV_ARGS[@]}" "${BIND_ARGS[@]}" "${SIF_PATH}" "$@"
fi

exec "${APPTAINER_BIN}" exec --nv "${ENV_ARGS[@]}" "${BIND_ARGS[@]}" "${SIF_PATH}" bash
