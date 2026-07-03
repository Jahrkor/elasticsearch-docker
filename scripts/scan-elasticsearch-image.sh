#!/usr/bin/env sh
set -eu

IMAGE_NAME="${IMAGE_NAME:-elasticsearch}"
TAG="${TAG:-patched-elasticsearch}"
SEVERITY="${SEVERITY:-CRITICAL,HIGH}"
IGNORE_UNFIXED="${IGNORE_UNFIXED:-false}"
SCANNERS="${SCANNERS:-vuln}"
TRIVY_EXIT_CODE="${TRIVY_EXIT_CODE:-0}"

if ! command -v trivy >/dev/null 2>&1; then
  echo "trivy is required to scan the image" >&2
  exit 127
fi

trivy image \
  --scanners "${SCANNERS}" \
  --severity "${SEVERITY}" \
  --ignore-unfixed="${IGNORE_UNFIXED}" \
  --exit-code "${TRIVY_EXIT_CODE}" \
  "${IMAGE_NAME}:${TAG}"
