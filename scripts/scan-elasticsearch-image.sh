#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
. "${script_dir}/release-defaults.sh"

IMAGE_REPOSITORY="${IMAGE_REPOSITORY:-${IMAGE_NAME:-${DEFAULT_IMAGE_REPOSITORY}}}"
IMAGE_VERSION="${IMAGE_VERSION:-${TAG:-${DEFAULT_IMAGE_VERSION}}}"
IMAGE_REF="${IMAGE_REPOSITORY}:${IMAGE_VERSION}"
SEVERITY="${SEVERITY:-CRITICAL,HIGH}"
IGNORE_UNFIXED="${IGNORE_UNFIXED:-false}"
SCANNERS="${SCANNERS:-vuln}"
TRIVY_EXIT_CODE="${TRIVY_EXIT_CODE:-1}"

if ! command -v trivy >/dev/null 2>&1; then
  echo "trivy is required to scan the image" >&2
  exit 127
fi

trivy image \
  --scanners "${SCANNERS}" \
  --severity "${SEVERITY}" \
  --ignore-unfixed="${IGNORE_UNFIXED}" \
  --exit-code "${TRIVY_EXIT_CODE}" \
  "${IMAGE_REF}"
