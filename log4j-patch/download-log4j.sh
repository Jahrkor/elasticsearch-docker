#!/usr/bin/env sh
set -eu

ARTIFACTS_FILE="${ARTIFACTS_FILE:-log4j-patch/artifacts.txt}"
DEST_DIR="${DEST_DIR:-log4j-patch/jars}"
MAVEN_BASE_URL="${MAVEN_BASE_URL:-https://repo1.maven.org/maven2}"

hash_file() {
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum "$1" | awk '{print $1}'
  else
    shasum -a 1 "$1" | awk '{print $1}'
  fi
}

mkdir -p "${DEST_DIR}"

while read -r group_id artifact_id version || [ -n "${group_id:-}" ]; do
  case "${group_id:-}" in
    ""|\#*) continue ;;
  esac

  group_path="$(printf '%s' "${group_id}" | tr . /)"
  jar_name="${artifact_id}-${version}.jar"
  artifact_url="${MAVEN_BASE_URL}/${group_path}/${artifact_id}/${version}/${jar_name}"
  target="${DEST_DIR}/${jar_name}"

  echo "Downloading ${jar_name}"
  curl -fL --retry 3 --retry-delay 2 -o "${target}" "${artifact_url}"

  expected_sha1="$(curl -fsSL "${artifact_url}.sha1" | tr -d '[:space:]')"
  actual_sha1="$(hash_file "${target}")"

  if [ "${expected_sha1}" != "${actual_sha1}" ]; then
    echo "Checksum mismatch for ${jar_name}" >&2
    echo "expected: ${expected_sha1}" >&2
    echo "actual:   ${actual_sha1}" >&2
    exit 1
  fi
done < "${ARTIFACTS_FILE}"
