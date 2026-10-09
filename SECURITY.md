# Security policy

## Reporting a vulnerability

Do not open a public issue containing exploit details, credentials, or customer
data. Report suspected vulnerabilities privately to the repository owner
through GitHub's private vulnerability reporting feature when available. If
that feature is unavailable, open a minimal public issue requesting a private
contact channel without disclosing the vulnerability.

Include the affected ElasticRune tag or digest, scanner and database versions,
reproduction steps, impact, and any known upstream advisory. Never include live
secrets or production data.

## Supported releases

Security fixes are delivered as new immutable ElasticRune tags. Published tags
are not rebuilt or overwritten. The current release receives assessment;
historical tags remain available for reproducibility but should be treated as
unsupported unless explicitly stated otherwise.

## Release methodology

Each release is scanned with current Trivy vulnerability and secret databases.
Docker Scout is used as an independent corroborating scanner. The release gate
requires zero Critical and zero High findings in the merged runnable
filesystem without ignore files, severity changes, grace periods, or unfixed
suppression. Remaining findings are recorded with fix availability, runtime
relevance, mitigation, and the reason a patch is deferred.

Runtime tests cover default HTTPS/authentication, startup, cluster health,
CRUD, persistence, attachment parsing, permissions, non-root execution, and
shutdown. They do not replace workload-specific integration, performance,
multi-node, cloud-identity, or custom-plugin testing.

## Maintenance model

The historical `elastic/elasticsearch-docker` upstream is archived. ElasticRune
therefore follows compatible patch releases of Elastic's maintained official
Elasticsearch Wolfi image and reviews distribution-specific changes
independently. Custom JAR replacements are narrowly scoped, checksum-pinned,
validated against exact expected targets, and must be reassessed whenever the
base image changes.

Scanner results are time-specific. A clean release scan is not a guarantee
against later disclosures, configuration weaknesses, or application-layer
risk. Run the image as non-root, preserve Elasticsearch security defaults,
limit network exposure and Linux capabilities, use trusted TLS, protect the
keystore, and rescan the immutable digest continuously.
