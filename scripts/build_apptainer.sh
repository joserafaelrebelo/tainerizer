#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

SERVICE="${1:-cuda130-devel}"
DIST_DIR="${DIST_DIR:-dist}"
mkdir -p "${DIST_DIR}"

case "${SERVICE}" in
  cuda128-runtime) IMAGE_TAG="uv-cuda-experiments:cuda12.8-runtime" ;;
  cuda128-devel) IMAGE_TAG="uv-cuda-experiments:cuda12.8-devel" ;;
  cuda130-runtime) IMAGE_TAG="uv-cuda-experiments:cuda13.0-runtime" ;;
  cuda130-devel) IMAGE_TAG="uv-cuda-experiments:cuda13.0-devel" ;;
  *)
    echo "Unsupported service: ${SERVICE}" >&2
    exit 1
    ;;
esac

IMAGE_TAG="${IMAGE_TAG_OVERRIDE:-${IMAGE_TAG}}"
TAR_PATH="${DIST_DIR}/${SERVICE}.tar"
SIF_PATH="${DIST_DIR}/${SERVICE}.sif"

if [[ "${SKIP_DOCKER_BUILD:-0}" != "1" ]]; then
  docker compose build "${SERVICE}"
fi

docker save "${IMAGE_TAG}" -o "${TAR_PATH}"

APPTAINER_BIN="${APPTAINER_BIN:-apptainer}"
APPTAINER_ARGS=()
if [[ "${APPTAINER_FAKEROOT:-0}" == "1" ]]; then
  APPTAINER_ARGS+=(--fakeroot)
fi

"${APPTAINER_BIN}" build "${APPTAINER_ARGS[@]}" "${SIF_PATH}" "docker-archive://${TAR_PATH}"

echo "Built ${SIF_PATH} from ${IMAGE_TAG}"
