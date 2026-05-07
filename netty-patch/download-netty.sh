#!/usr/bin/env sh
set -eu

NETTY_VERSION="${NETTY_VERSION:-4.1.133.Final}"
ARTIFACTS_FILE="${ARTIFACTS_FILE:-netty-patch/artifacts.txt}"
DEST_DIR="${DEST_DIR:-netty-patch/jars}"
MAVEN_BASE_URL="${MAVEN_BASE_URL:-https://repo1.maven.org/maven2/io/netty}"

hash_file() {
  if command -v sha1sum >/dev/null 2>&1; then
    sha1sum "$1" | awk '{print $1}'
  else
    shasum -a 1 "$1" | awk '{print $1}'
  fi
}

mkdir -p "${DEST_DIR}"

while IFS= read -r artifact_id || [ -n "${artifact_id}" ]; do
  case "${artifact_id}" in
    ""|\#*) continue ;;
  esac

  jar_name="${artifact_id}-${NETTY_VERSION}.jar"
  artifact_url="${MAVEN_BASE_URL}/${artifact_id}/${NETTY_VERSION}/${jar_name}"
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
