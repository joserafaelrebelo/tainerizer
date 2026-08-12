#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

to_abs_path() {
  local path="$1"
  if [[ "${path}" = /* ]]; then
    realpath -m "${path}"
  else
    realpath -m "${ROOT_DIR}/${path}"
  fi
}

upsert_env() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    printf '%s=%s\n' "${key}" "${value}" >> .env
  fi
}

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

set -a
source .env
set +a

WORKSPACE_HOST_BIND="${WORKSPACE_HOST_BIND:-..}"
WORKSPACE_HOST_ABS="$(to_abs_path "${WORKSPACE_HOST_BIND}")"
WORKSPACE_NAME="$(basename "${WORKSPACE_HOST_ABS}")"

if [[ -z "${WORKSPACE_CONTAINER_DIR:-}" || "${WORKSPACE_CONTAINER_DIR}" == "/workspace/workspace" ]]; then
  WORKSPACE_CONTAINER_DIR="/workspace/${WORKSPACE_NAME}"
fi

if [[ -z "${HF_CACHE_BIND:-}" || "${HF_CACHE_BIND}" == "../.cache/huggingface" ]]; then
  HF_CACHE_BIND="${WORKSPACE_HOST_ABS}/.cache/huggingface"
fi

if [[ -z "${UV_CACHE_BIND:-}" || "${UV_CACHE_BIND}" == "../.cache/uv" ]]; then
  UV_CACHE_BIND="${WORKSPACE_HOST_ABS}/.cache/uv"
fi

if [[ -z "${HF_CACHE_CONTAINER_PATH:-}" || "${HF_CACHE_CONTAINER_PATH}" == "/workspace/workspace/.cache/huggingface" ]]; then
  HF_CACHE_CONTAINER_PATH="${WORKSPACE_CONTAINER_DIR}/.cache/huggingface"
fi

if [[ -z "${UV_CACHE_CONTAINER_PATH:-}" || "${UV_CACHE_CONTAINER_PATH}" == "/workspace/workspace/.cache/uv" ]]; then
  UV_CACHE_CONTAINER_PATH="${WORKSPACE_CONTAINER_DIR}/.cache/uv"
fi

DOCKER_GPUS="${DOCKER_GPUS:-all}"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-uv-cuda-experiments}"

upsert_env COMPOSE_PROJECT_NAME "${COMPOSE_PROJECT_NAME}"
upsert_env WORKSPACE_HOST_BIND "${WORKSPACE_HOST_BIND}"
upsert_env WORKSPACE_CONTAINER_DIR "${WORKSPACE_CONTAINER_DIR}"
upsert_env HF_CACHE_BIND "${HF_CACHE_BIND}"
upsert_env UV_CACHE_BIND "${UV_CACHE_BIND}"
upsert_env HF_CACHE_CONTAINER_PATH "${HF_CACHE_CONTAINER_PATH}"
upsert_env UV_CACHE_CONTAINER_PATH "${UV_CACHE_CONTAINER_PATH}"
upsert_env DOCKER_GPUS "${DOCKER_GPUS}"

mkdir -p "${WORKSPACE_HOST_ABS}" "${HF_CACHE_BIND}" "${UV_CACHE_BIND}"

echo "Workspace bind: ${WORKSPACE_HOST_BIND}"
echo "Detected workspace name: ${WORKSPACE_NAME}"
echo "Container workspace dir: ${WORKSPACE_CONTAINER_DIR}"
echo "HF cache bind: ${HF_CACHE_BIND}"
echo "UV cache bind: ${UV_CACHE_BIND}"
