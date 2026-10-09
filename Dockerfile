ARG BASE_IMAGE=docker.elastic.co/elasticsearch/elasticsearch-wolfi:9.4.8-amd64@sha256:8f501c3cee2553e2acc4383554f0ab59e28789a1066f5969eea5118e7966225e
FROM ${BASE_IMAGE}

USER 0

RUN set -eu; \
    apk update; \
    apk upgrade --no-cache; \
    rm -rf /var/cache/apk/*

USER 1000:0
