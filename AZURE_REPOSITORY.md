Azure snapshot repositories
============================

Elasticrune `2.2.1` exposes the `repository-azure` module bundled with
Elasticsearch `9.4.4`. It is located at:

```text
/usr/share/elasticsearch/modules/repository-azure
```

Do not install `repository-azure` again and do not add it to
`elasticsearch-plugins.yml`. The module is part of the Elasticsearch
distribution and its descriptor is version-matched to Elasticsearch `9.4.4`.

Credential handling
-------------------

No Azure account information or credential is stored in this image. Configure
the account at deployment time in the Elasticsearch keystore:

```sh
docker exec -it <container> \
  /usr/share/elasticsearch/bin/elasticsearch-keystore \
  add azure.client.default.account
```

For shared-key authentication, also add:

```sh
docker exec -it <container> \
  /usr/share/elasticsearch/bin/elasticsearch-keystore \
  add azure.client.default.key
```

For SAS authentication, add `azure.client.default.sas_token` instead of the
key. Do not configure both a key and a SAS token for the same client.

When no key or SAS token is configured, Elasticsearch can use supported Azure
environment credentials, including Managed Identity on Azure VMs and Workload
Identity on AKS. The account setting remains a secure keystore setting.

For production, populate a writable keystore from a Docker/Kubernetes secret
before Elasticsearch starts, typically with an init container. Alternatively,
use Managed Identity or Workload Identity and mount only the required account
configuration. Do not pass secrets as Docker build arguments, image
environment defaults, labels, or repository settings.

Secure settings are reloadable. After updating the keystore on every node,
reload them through the Elasticsearch secure-settings API or restart the
nodes according to the deployment's normal change procedure.

Repository registration
-----------------------

After the client is configured, explicitly register the repository:

```http
PUT _snapshot/azure-backups
Content-Type: application/json

{
  "type": "azure",
  "settings": {
    "client": "default",
    "container": "elasticsearch-backups",
    "base_path": "elasticrune"
  }
}
```

Verify connectivity and permissions:

```http
POST _snapshot/azure-backups/_verify
```

Create a snapshot:

```http
PUT _snapshot/azure-backups/smoke-test?wait_for_completion=true
```

List snapshots:

```http
GET _snapshot/azure-backups/_all
```

Restore only after reviewing the target cluster and snapshot contents:

```http
POST _snapshot/azure-backups/smoke-test/_restore
{
  "indices": "example-index"
}
```

The image entrypoint does not edit the keystore, register repositories, or
create snapshots automatically.
