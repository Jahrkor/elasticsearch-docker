ARG BASE_IMAGE=docker.elastic.co/elasticsearch/elasticsearch-wolfi:9.4.4
FROM ${BASE_IMAGE}

USER 0

RUN set -eu; \
    apk update; \
    packages=""; \
    for pkg in busybox libcrypto3 libssl3 libcurl-openssl4 openssl; do \
      if apk info -e "${pkg}" >/dev/null 2>&1; then \
        packages="${packages} ${pkg}"; \
      fi; \
    done; \
    if [ -n "${packages}" ]; then \
      apk upgrade --no-cache ${packages}; \
    fi; \
    rm -rf /var/cache/apk/*

USER 1000:0
