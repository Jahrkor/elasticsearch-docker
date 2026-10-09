# ElasticRune

ElasticRune is an independently versioned, security-maintained Elasticsearch
container distribution built from Elastic's official Wolfi image. It is a
community project maintained by `hrafnox`; it is not an official Elastic
product and is not endorsed by Elastic.

## Current release

| Component | Version |
| --- | --- |
| ElasticRune | `2.2.2` |
| Image | `hrafnox/elasticrune:2.2.2` |
| Elasticsearch | `9.4.8` |
| Bundled OpenJDK | `27` |
| Platform | `linux/amd64` |
| Runtime user | `1000:0` (`elasticsearch`) |
| Base | Official Elasticsearch Wolfi `9.4.8-amd64` image, digest-pinned |

ElasticRune tags are distribution releases, not Elasticsearch engine
versions. A patch release may adopt a compatible Elasticsearch patch release,
but it does not silently change the Elasticsearch major or minor contract.
Only `linux/amd64` is validated. Older ElasticRune tags are retained as
immutable historical releases; they do not receive fixes in place.

The image inherits the official entrypoint, command, ports, configuration,
data paths, security defaults, and bundled modules. Elasticsearch 9.4.8
provides the `repository-azure` module; no separate plugin is installed.

## Security maintenance

The release gate is zero Critical and zero High findings in the merged runtime
filesystem, with no ignored vulnerabilities, severity overrides, grace
periods, or unfixed-finding suppression. Downloads used by the custom patch
stage have pinned SHA-512 digests. The base and builder images are pinned by
digest, and the build fails if expected replacement targets or counts change.

Release 2.2.2 moves the engine from 9.4.4 to the compatible 9.4.8 patch release,
upgrades installed Wolfi packages, and applies these targeted repairs:

- Bouncy Castle `1.84` to `1.85` through the official Elasticsearch base;
- LZ4 Java `1.11.1` to `1.11.4`;
- jsoup `1.21.2` to `1.23.2`;
- both Parquet `1.18.1` bundles rebuilt with shaded Jackson `2.22.3`;
- the aligned 11-artifact Apache Tika family from `3.2.3` to `3.3.2`.

Trivy reports 27 Medium rows representing seven unique CVEs:

- `CVE-2025-48924`, Commons Lang `3.9`: upstream module dependency; replacing
  it alone would bypass Elasticsearch integration and compatibility testing.
- `CVE-2026-49844`, Log4j API `2.25.4`: embedded in the Elastic APM agent and
  not safely replaceable as a standalone JAR.
- `CVE-2026-77420`, JLine Reader `3.21.0`: upstream CLI dependency; the risk is
  limited to local history configuration processing.
- `CVE-2026-8674`, `CVE-2026-86805`, `CVE-2026-89092`, and
  `CVE-2026-95818`, glibc `2.44-r7`: the scanner advertises `r8`, but `r8` is
  not available from the digest-pinned image's configured Wolfi snapshot after
  a full package upgrade. These primarily require local execution or unusual
  resolver/loader inputs; retain non-root execution and constrained container
  privileges until a compatible base publishes the fixed packages.

Docker Scout's image-history analysis can report the superseded JARs from the
immutable lower base layer. A Scout scan of the exported merged filesystem and
a Trivy runtime-filesystem scan both report zero Critical and zero High; the
old JARs are absent from the runnable filesystem. This distinction must be
revalidated for every release and is not a suppression.

## Build and scan

Build the default release for `linux/amd64`:

```sh
./scripts/build-elasticsearch-image.sh
```

Set `NO_CACHE=false` only for local development. `IMAGE_REPOSITORY`,
`IMAGE_VERSION`, `DOCKERFILE`, `CONTEXT`, and `PLATFORM` are overrideable.

Run the Critical/High release gate:

```sh
./scripts/scan-elasticsearch-image.sh
```

The scanner includes fixed and unfixed findings and exits nonzero for any
Critical or High result.

## Run

Elasticsearch security remains enabled. Supply a strong bootstrap password and
mount a named volume for data:

```sh
docker run --name elasticrune \
  -p 9200:9200 \
  -e 'discovery.type=single-node' \
  -e 'ELASTIC_PASSWORD=replace-with-a-secret' \
  -e 'ES_JAVA_OPTS=-Xms1g -Xmx1g' \
  -v elasticrune-data:/usr/share/elasticsearch/data \
  hrafnox/elasticrune:2.2.2
```

Copy `/usr/share/elasticsearch/config/certs/http_ca.crt` from the container and
use it to validate HTTPS. Do not disable TLS or authentication merely for
deployment convenience. Keep credentials out of Dockerfiles, labels, image
environment defaults, and source control.

## Compatibility and limitations

The 2.2.2 validation covers startup, HTTPS/authentication, green cluster
health, index/document CRUD, persistence across restart, attachment ingestion,
non-root permissions, bundled module discovery, and graceful shutdown. The
entrypoint, command, ports, paths, architecture, and Elasticsearch 9.4
major/minor contract are unchanged from 2.2.1. The official base now bundles
OpenJDK 27 instead of 26, and internal libraries and OS packages have moved to
their 9.4.8-compatible versions.

Azure repository connectivity, multi-node rolling upgrades, ESQL external data
sources, inference, custom plugins, and workload-specific performance are not
covered by the local release smoke test. Exercise targeted integration tests
before production adoption. See [AZURE_REPOSITORY.md](AZURE_REPOSITORY.md) for
secure Azure snapshot configuration.

Do not use `latest` as a release selector. Pin `2.2.2` or, preferably, the
published registry digest.

## Licensing

Repository source remains under the included Apache License 2.0. The image
contains Elasticsearch binaries governed by Elastic License 2.0 and
third-party components under their respective licenses. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). No upstream copyright or
license notices are removed.
