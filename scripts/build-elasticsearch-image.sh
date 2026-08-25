#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/release-defaults.sh"

IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-${IMAGE_NAME:-${DEFAULT_IMAGE_REPOSITORY}}}"
IMAGE_VERSION="${IMAGE_VERSION:-${TAG:-${DEFAULT_IMAGE_VERSION}}}"
IMAGE_REF="${IMAGE_REPOSITORY}:${IMAGE_VERSION}"
DOCKERFILE="${DOCKERFILE:-Dockerfile.jackson-patched}"
CONTEXT="${CONTEXT:-.}"
PLATFORM="${PLATFORM:-linux/amd64}"
NO_CACHE="${NO_CACHE:-true}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to build the image" >&2
  exit 127
fi

no_cache_arg=""

if [ "${NO_CACHE}" = "true" ]; then
  no_cache_arg="--no-cache"
fi

if [ -n "${PLATFORM}" ]; then
  docker build ${no_cache_arg} --pull --platform "${PLATFORM}" \
    --build-arg "RELEASE_VERSION=${IMAGE_VERSION}" \
    -f "${DOCKERFILE}" -t "${IMAGE_REF}" "${CONTEXT}"
else
  docker build ${no_cache_arg} --pull \
    --build-arg "RELEASE_VERSION=${IMAGE_VERSION}" \
    -f "${DOCKERFILE}" -t "${IMAGE_REF}" "${CONTEXT}"
fi

echo "Built ${IMAGE_REF}"
