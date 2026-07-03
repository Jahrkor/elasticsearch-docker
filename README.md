Elasticsearch Docker image hardening
====================================

This repository builds hardened Elasticsearch images from official Elastic
images.

Current security-gate image
---------------------------

- Final tag: `jahrkor/elasticsearch-docker:9.4.3-wolfi-no-high-20260703`
- Dockerfile: `Dockerfile.jackson-patched`
- Base image: `docker.elastic.co/elasticsearch/elasticsearch-wolfi:9.4.3`
- Elasticsearch: `9.4.3`
- OS family: Wolfi/Chainguard, using `apk`
- Runtime user: `1000:0`
- Entrypoint/CMD: inherited from the official image
- Exposed ports: inherited from the official image, `9200` and `9300`

The strict security gate for this repository is:

- `0` Critical vulnerabilities
- `0` High vulnerabilities
- No Trivy suppression, allowlist, or `.trivyignore`

See `SECURITY_VALIDATION.md` for the full validation evidence, official image
scan matrix, compatibility notes, and rollout instructions.

Vulnerability remediation
-------------------------

The original image findings were:

- OpenSSL scanner findings against `3.6.2-r2`
- BusyBox `CVE-2023-39810` against `1.37.0-r57`
- Netty findings against `4.1.133.Final`

The official Elasticsearch `9.4.3` Wolfi image remediated those original
findings by moving to newer Wolfi packages and Netty `4.1.135.Final`, but it
still reported upstream Jackson HIGH findings:

- `CVE-2026-54512`
- `CVE-2026-54513`

No official Elastic image tested passed the `0 Critical / 0 High` gate. The
final gate-passing image therefore uses `Dockerfile.jackson-patched`, based on
`docker.elastic.co/elasticsearch/elasticsearch-wolfi:9.4.3`, and makes the
minimum Jackson-related internal JAR replacements needed to clear the gate.

Manual JAR replacements in `Dockerfile.jackson-patched`:

- `jackson-databind-2.15.0.jar` to `jackson-databind-2.18.8.jar`
- `parquet-hadoop-bundle-1.17.0.jar` to a patched
  `parquet-hadoop-bundle-1.17.1.jar`
- Shaded Jackson classes inside the Parquet bundle rebuilt to Jackson `2.21.4`
  with `jackson-annotations` `2.21`

The default `Dockerfile` remains the official-image hardening path without
manual Jackson replacement. Use `Dockerfile.jackson-patched` for the strict
security-gate image.

Build
-----

```sh
DOCKERFILE=Dockerfile.jackson-patched \
IMAGE_NAME=jahrkor/elasticsearch-docker \
TAG=9.4.3-wolfi-no-high-20260703 \
./scripts/build-elasticsearch-image.sh
```

Equivalent direct command:

```sh
docker build -f Dockerfile.jackson-patched \
  -t jahrkor/elasticsearch-docker:9.4.3-wolfi-no-high-20260703 \
  .
```

Scan
----

```sh
TRIVY_EXIT_CODE=1 \
IMAGE_NAME=jahrkor/elasticsearch-docker \
TAG=9.4.3-wolfi-no-high-20260703 \
./scripts/scan-elasticsearch-image.sh
```

Equivalent direct command:

```sh
trivy image \
  --severity CRITICAL,HIGH \
  --exit-code 1 \
  --ignore-unfixed=false \
  jahrkor/elasticsearch-docker:9.4.3-wolfi-no-high-20260703
```

Expected result: Trivy exits `0` with `0 CRITICAL` and `0 HIGH`.

Smoke test
----------

```sh
docker run --rm --name elasticsearch-no-high-test \
  -p 9200:9200 \
  -e "discovery.type=single-node" \
  -e "xpack.security.enabled=false" \
  jahrkor/elasticsearch-docker:9.4.3-wolfi-no-high-20260703
```

In another shell:

```sh
curl http://localhost:9200
curl http://localhost:9200/_cluster/health
```

Expected result: the root endpoint returns Elasticsearch `9.4.3`, and the
cluster health endpoint returns `status: green`.

Push to DockerHub
-----------------

Do not tag or push `latest` for this release.

```sh
docker login
docker push jahrkor/elasticsearch-docker:9.4.3-wolfi-no-high-20260703
```

Build-and-push equivalent for a fresh linux/amd64 build:

```sh
docker buildx build --platform linux/amd64 \
  -f Dockerfile.jackson-patched \
  -t jahrkor/elasticsearch-docker:9.4.3-wolfi-no-high-20260703 \
  --push .
```

Rollback
--------

For deployment rollback:

1. Restore the previous Elasticsearch image tag in the deployment config.
2. Redeploy the workload.
3. Verify the root and cluster health endpoints:

```sh
curl http://localhost:9200
curl http://localhost:9200/_cluster/health
```

The root endpoint should respond, and `/_cluster/health` should return an
acceptable status for the environment.

Compatibility note
------------------

The final image manually replaces internal Elasticsearch Jackson-related JARs
because no official Elasticsearch image passed the strict gate. The container
starts, the root API responds, cluster health is green, and Trivy reports
`0 CRITICAL` and `0 HIGH`.

Before production rollout, run workload-specific tests for any used modules
that depend on the replaced JARs, especially GeoIP, Azure repository or Azure
ESQL data sources, Enterprise Search, inference, and ESQL Parquet/Iceberg data
source workflows.
