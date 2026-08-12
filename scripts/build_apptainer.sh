#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

# Accept either:
# 1) a known alias (cuda128-runtime, cuda128-devel, cuda130-runtime, cuda130-devel)
# 2) a full Docker image reference (e.g. nvidia/cuda:12.8.1-devel-ubuntu24.04)
IMAGE_INPUT="${1:-cuda130-devel}"
DIST_DIR="${DIST_DIR:-dist}"
mkdir -p "${DIST_DIR}"

case "${IMAGE_INPUT}" in
  cuda128-runtime) DOCKER_IMAGE="nvidia/cuda:12.8.1-runtime-ubuntu24.04" ;;
  cuda128-devel)   DOCKER_IMAGE="nvidia/cuda:12.8.1-devel-ubuntu24.04" ;;
  cuda130-runtime) DOCKER_IMAGE="nvidia/cuda:13.0.0-runtime-ubuntu24.04" ;;
  cuda130-devel)   DOCKER_IMAGE="nvidia/cuda:13.0.0-devel-ubuntu24.04" ;;
  *)
    # Treat input as direct image reference from Docker Hub (or any registry)
    DOCKER_IMAGE="${IMAGE_INPUT}"
    ;;
esac

DOCKER_IMAGE="${IMAGE_TAG_OVERRIDE:-${DOCKER_IMAGE}}"

# Safe output name for files
SAFE_NAME="$(echo "${DOCKER_IMAGE}" | tr '/:@' '___')"
TAR_PATH="${DIST_DIR}/${SAFE_NAME}.tar"
SIF_PATH="${DIST_DIR}/${SAFE_NAME}.sif"

if [[ "${SKIP_DOCKER_PULL:-0}" != "1" ]]; then
  docker pull "${DOCKER_IMAGE}"
fi

docker save "${DOCKER_IMAGE}" -o "${TAR_PATH}"

APPTAINER_BIN="${APPTAINER_BIN:-apptainer}"
APPTAINER_ARGS=()
if [[ "${APPTAINER_FAKEROOT:-0}" == "1" ]]; then
  APPTAINER_ARGS+=(--fakeroot)
fi

"${APPTAINER_BIN}" build "${APPTAINER_ARGS[@]}" "${SIF_PATH}" "docker-archive://${TAR_PATH}"

echo "Built ${SIF_PATH} from ${DOCKER_IMAGE}"