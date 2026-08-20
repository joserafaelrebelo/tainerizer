#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT_DIR}"

# Accept a Docker Hub image reference, e.g. rafaeljose/tainerized:cu13-runtime
DOCKER_IMAGE="${IMAGE_TAG_OVERRIDE:-${1:?Usage: $0 <dockerhub-image> (e.g. rafaeljose/tainerized:cu13-runtime)}}"
DIST_DIR="${DIST_DIR:-dist}"
mkdir -p "${DIST_DIR}"

# Safe output name for files
SAFE_NAME="$(echo "${DOCKER_IMAGE}" | tr '/:@' '___')"
SIF_PATH="${DIST_DIR}/${SAFE_NAME}.sif"

APPTAINER_BIN="${APPTAINER_BIN:-apptainer}"
APPTAINER_ARGS=()
if [[ "${APPTAINER_FAKEROOT:-0}" == "1" ]]; then
  APPTAINER_ARGS+=(--fakeroot)
fi

"${APPTAINER_BIN}" build "${APPTAINER_ARGS[@]}" "${SIF_PATH}" "docker://${DOCKER_IMAGE}"

echo "Built ${SIF_PATH} from ${DOCKER_IMAGE}"