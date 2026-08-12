#!/usr/bin/env bash
#SBATCH --job-name=tainerizer
#SBATCH --output=slurm-%j.out
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --export=ALL

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

"${ROOT_DIR}/scripts/setup.sh" >/dev/null

set -a
source .env
set +a

export WORKSPACE_HOST_BIND="${WORKSPACE_HOST_BIND:-..}"
WORKSPACE_HOST_ABS="$(realpath -m "${WORKSPACE_HOST_BIND}")"
WORKSPACE_NAME="$(basename "${WORKSPACE_HOST_ABS}")"
export WORKSPACE_CONTAINER_DIR="${WORKSPACE_CONTAINER_DIR:-/workspace/${WORKSPACE_NAME}}"
export HF_CACHE_BIND="${HF_CACHE_BIND:-../.cache/huggingface}"
export UV_CACHE_BIND="${UV_CACHE_BIND:-../.cache/uv}"
export HF_CACHE_CONTAINER_PATH="${HF_CACHE_CONTAINER_PATH:-${WORKSPACE_CONTAINER_DIR}/.cache/huggingface}"
export UV_CACHE_CONTAINER_PATH="${UV_CACHE_CONTAINER_PATH:-${WORKSPACE_CONTAINER_DIR}/.cache/uv}"

BACKEND="${BACKEND:-apptainer}"
SERVICE="${SERVICE:-cuda130-devel}"
SIF_PATH="${SIF_PATH:-dist/cuda130-devel.sif}"
JOB_CMD="${JOB_CMD:-nvidia-smi && python --version && uv --version}"

if [[ "${BACKEND}" == "docker" ]]; then
  exec "${ROOT_DIR}/scripts/run_docker.sh" "${SERVICE}" bash -lc "${JOB_CMD}"
fi

exec "${ROOT_DIR}/scripts/run_apptainer.sh" "${SIF_PATH}" bash -lc "${JOB_CMD}"
