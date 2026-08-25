Elasticsearch Docker image hardening
====================================

This repository builds a hardened Elasticsearch image from the official
Elastic Wolfi image.

Current release
---------------

- Release tag: `hrafnox/elasticrune:2.2.1`
- Build Dockerfile: `Dockerfile.jackson-patched`
- Base image: `docker.elastic.co/elasticsearch/elasticsearch-wolfi:9.4.4`
- Elasticsearch: `9.4.4`
- Platform: `linux/amd64`
- Runtime user: `1000:0`
- Entrypoint and exposed ports: inherited from the official image
- Azure snapshot repositories: bundled `repository-azure` module

The release security gate is zero Critical and zero High vulnerabilities,
without Trivy ignores, severity changes, grace periods, or unfixed-finding
suppression.

Vulnerability remediation
-------------------------

Elasticsearch `9.4.4` supplies fixed direct Jackson `2.18.8` artifacts. Two
Parquet bundles still contained vulnerable shaded Jackson classes, the
distribution still supplied Netty `4.1.135.Final`, and its x-pack-core module
contained HttpComponents Core `5.3.5`. The bundled ingest-attachment module
also contained the aligned Apache Tika `3.2.3` family affected by
`CVE-2026-66755`.

`Dockerfile.jackson-patched` therefore makes five narrowly scoped distribution
patches:

- replaces both `parquet-hadoop-bundle-1.17.0.jar` copies with a repacked
  `1.17.1` bundle whose shaded Jackson components are `2.21.5`;
- replaces every Netty `4.1.135.Final` module with the corresponding
  `4.1.137.Final` artifact as one aligned set;
- replaces `httpcore5` and `httpcore5-h2` `5.3.5` with `5.4.3`;
- replaces all 11 Tika `3.2.3` artifacts in `ingest-attachment` with their
  aligned `3.3.2` counterparts;
- updates the five module-local Jackson families that include Databind from
  `2.18.8` to `2.18.9`, and rebuilds the shaded Parquet copies with Jackson
  `2.21.5`.

The build also overrides the base image's exact package pins with fixed minimum
versions for BusyBox `1.38.0-r0`, OpenSSL `3.6.3-r5`, and libnghttp2
`1.70.0-r0`.

Downloaded artifacts are checked before installation. The Tika, direct
Jackson, and Netty artifacts use pinned SHA-512 digests; the existing Parquet and
HttpComponents repairs use Maven Central checksum sidecars. The image build
fails if an expected replacement is missing, if no matching distribution JAR
is found, or if a stale vulnerable-version JAR remains.

Build
-----

The default build is a fresh `linux/amd64` build of the release tag and pulls
the current base-image manifest:

```sh
./scripts/build-elasticsearch-image.sh
```

Set `NO_CACHE=false` only for local development. The image name, tag,
Dockerfile, context, and platform remain overrideable through `IMAGE_NAME`,
`TAG`, `DOCKERFILE`, `CONTEXT`, and `PLATFORM`.

Scan
----

Trivy is required. The script scans Critical and High findings, includes
unfixed findings, and exits nonzero if any finding is detected:

```sh
./scripts/scan-elasticsearch-image.sh
```

Expected result for the release image: `0 CRITICAL`, `0 HIGH`.

Known Medium findings
---------------------

The release retains 11 Trivy Medium rows where an isolated JAR replacement is
not justified without upstream integration coverage:

- `CVE-2025-22227`: Reactor Netty HTTP `1.0.45` (three module copies); the
  available fix crosses to the `1.2.x` family and must remain aligned with
  Reactor Core.
- `CVE-2025-48924`: Commons Lang `3.9`; the fixed `3.18.0` is a large jump in
  the `x-pack-ent-search` module.
- `CVE-2026-45292`: OpenTelemetry API `1.47.0` (two module copies); the fixed
  `1.62.0` requires a coordinated OpenTelemetry family update.
- `CVE-2026-49844`: Log4j API `2.26.0` and an embedded `2.25.4` copy in the APM
  agent; one is core logging infrastructure and the other cannot be safely
  replaced independently inside the agent bundle.
- `CVE-2026-59949`: LZ4 Java `1.10.1`; the fixed `1.11.1` affects core
  compression and persistence paths.
- `CVE-2026-64607`: HttpClient 5 `5.5`; the fixed `5.6.3` is a larger minor
  update in `x-pack-core` than the separately aligned HttpCore repair.
- `CVE-2026-71497`: jsoup `1.21.2`; the scanner-fixed `1.23.1` is ahead of the
  version integrated by upstream Elasticsearch and is on the attachment parser
  path.

Smoke test
----------

```sh
docker run --rm --name elasticrune-smoke \
  -p 9200:9200 \
  -e 'discovery.type=single-node' \
  -e 'xpack.security.enabled=false' \
  -e 'ES_JAVA_OPTS=-Xms512m -Xmx512m' \
  hrafnox/elasticrune:2.2.1
```

Verify the root endpoint, cluster health, and installed plugins:

```sh
curl http://localhost:9200/
curl http://localhost:9200/_cluster/health
curl 'http://localhost:9200/_cat/plugins?format=json'
```

Compatibility note
------------------

Netty, HttpComponents Core, Apache Tika, and the shaded Parquet/Jackson
implementation are internal Elasticsearch distribution dependencies. Startup,
green cluster health, attachment parsing, module enumeration,
and index/document CRUD are validated for this release. Workloads using Azure,
gRPC, inference, or ESQL external data sources should retain targeted
integration coverage because those modules consume these replaced
dependencies.

Azure snapshot repositories
---------------------------

Elasticsearch `9.4.4` bundles the version-matched `repository-azure` module,
so this image does not install a duplicate plugin or add Azure SDK JARs. See
`AZURE_REPOSITORY.md` for secure deployment-time credential configuration,
repository registration, verification, snapshot, and identity examples.

Do not push `latest` or any rolling tag for this release.
