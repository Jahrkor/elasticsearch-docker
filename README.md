Elasticsearch Docker image hardening
====================================

This repository builds a hardened Elasticsearch image from the official
Elastic Wolfi image.

Current release
---------------

- Release tag: `hrafnox/elasticrune:2.2.0`
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
Parquet bundles still contained vulnerable shaded Jackson classes, and the
distribution still supplied Netty `4.1.135.Final`.

`Dockerfile.jackson-patched` therefore makes two narrowly scoped distribution
patches:

- replaces both `parquet-hadoop-bundle-1.17.0.jar` copies with a repacked
  `1.17.1` bundle whose shaded Jackson components are `2.21.4`;
- replaces every Netty `4.1.135.Final` module with the corresponding
  `4.1.136.Final` artifact as one aligned set.

Downloaded artifacts are checked against their Maven Central SHA-1 files.
The image build fails if an expected replacement is missing, if no matching
distribution JAR is found, or if a stale vulnerable-version JAR remains.

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

Smoke test
----------

```sh
docker run --rm --name elasticrune-smoke \
  -p 9200:9200 \
  -e 'discovery.type=single-node' \
  -e 'xpack.security.enabled=false' \
  -e 'ES_JAVA_OPTS=-Xms512m -Xmx512m' \
  hrafnox/elasticrune:2.2.0
```

Verify the root endpoint, cluster health, and installed plugins:

```sh
curl http://localhost:9200/
curl http://localhost:9200/_cluster/health
curl 'http://localhost:9200/_cat/plugins?format=json'
```

Compatibility note
------------------

Netty and the shaded Parquet/Jackson implementation are internal
Elasticsearch distribution dependencies. Startup, green cluster health,
authentication, plugin enumeration, and index/document CRUD are validated for
this release. Workloads using Azure, gRPC, inference, or ESQL external data
sources should retain targeted integration coverage because those modules also
consume the aligned Netty replacement set.

Azure snapshot repositories
---------------------------

Elasticsearch `9.4.4` bundles the version-matched `repository-azure` module,
so this image does not install a duplicate plugin or add Azure SDK JARs. See
`AZURE_REPOSITORY.md` for secure deployment-time credential configuration,
repository registration, verification, snapshot, and identity examples.

Do not push `latest` or any rolling tag for this release.
