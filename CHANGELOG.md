# Changelog

## 2.2.2 - 2026-10-08

Security maintenance release preserving the Elasticsearch 9.4 major/minor
runtime contract.

### Changed

- Updated the digest-pinned official Wolfi base from Elasticsearch 9.4.4 to
  9.4.8 and the bundled OpenJDK from 26 to 27.
- Applied all upgrades available from the base image's configured package
  repositories.
- Updated LZ4 Java to 1.11.4 and jsoup to 1.23.2.
- Rebuilt both Parquet 1.18.1 bundles with shaded Jackson 2.22.3.
- Updated the aligned Apache Tika attachment-parser family to 3.3.2.
- Added digest and checksum pinning plus strict target/count checks for custom
  dependency patches.
- Added OCI source, revision, version, license, vendor, and base-image labels.

### Security

The 2.2.1 baseline contained 1 Critical, 52 High, 36 Medium, 11 Low, and 0
secret findings. Release 2.2.2 contains 0 Critical, 0 High, 27 Medium, 0 Low,
and 0 secret findings in the merged runtime filesystem with the current Trivy
databases used for the release.

Remediated findings:

- `CVE-2026-8763` and `CVE-2026-13506` in Bouncy Castle;
- `CVE-2026-106451` in LZ4 Java;
- `CVE-2026-75140` in jsoup;
- `CVE-2026-68497`, `CVE-2026-89407`, `CVE-2026-89425`,
  `CVE-2026-91776`, and `CVE-2026-91777` in direct or shaded Jackson.

Remaining Medium findings and their mitigations are documented in the README.

### Compatibility

- Unchanged: `linux/amd64`, runtime UID/GID `1000:0`, entrypoint, command,
  ports, configuration/data/log/plugin paths, TLS/authentication defaults,
  Elasticsearch 9.4 REST contract, and bundled `repository-azure` module.
- Changed: Elasticsearch patch 9.4.4 to 9.4.8, bundled OpenJDK 26 to 27,
  supported internal libraries, and Wolfi packages.
- No `latest` tag is published or updated by this release.
