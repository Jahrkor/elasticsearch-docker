#!/usr/bin/env sh
set -eu

IMAGE_NAME="${IMAGE_NAME:-elasticsearch}"
TAG="${TAG:-patched-elasticsearch}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
CONTEXT="${CONTEXT:-.}"
PLATFORM="${PLATFORM:-}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to build the image" >&2
  exit 127
fi

image_ref="${IMAGE_NAME}:${TAG}"

if [ -n "${PLATFORM}" ]; then
  docker build --platform "${PLATFORM}" -f "${DOCKERFILE}" -t "${image_ref}" "${CONTEXT}"
else
  docker build -f "${DOCKERFILE}" -t "${image_ref}" "${CONTEXT}"
fi

echo "Built ${image_ref}"
