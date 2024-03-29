---
title: "Create Memorystore"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will create a Memorystore (Redis) instance for the Online Boutique's `cartservice` app to connect to. We will also create a second Memorystore (Redis) with TLS enabled which will be leveraged in another section.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_NAME=cart" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_TLS_NAME=cart-tls" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Memorystore (Redis)

Define the [Memorystore (Redis) resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/redis/redisinstance):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/memorystore.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
  name: ${REDIS_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  authorizedNetworkRef:
    name: ${GKE_NAME}
  memorySizeGb: 1
  redisVersion: REDIS_6_X
  region: ${GKE_LOCATION}
  tier: BASIC
EOF
```

## Define Memorystore (Redis) with TLS enabled

Define the [Memorystore (Redis) resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/redis/redisinstance) with TLS enabled:
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/memorystore-tls.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
  name: ${REDIS_TLS_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  authorizedNetworkRef:
    name: ${GKE_NAME}
  memorySizeGb: 1
  redisVersion: REDIS_6_X
  region: ${GKE_LOCATION}
  tier: BASIC
  transitEncryptionMode: SERVER_AUTHENTICATION
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Memorystore (Redis) instance" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  RedisInstance-.->Project
  RedisInstance-.->ComputeNetwork
  RedisInstance-.->Project
  RedisInstance-.->ComputeNetwork
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${HOST_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` too.
{{% /tab %}}
{{< /tabs >}}

{{% notice note %}}
The creation of the `RedisInstance` can take ~10 mins.
{{% /notice %}}

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud redis instances list \
    --region=$GKE_LOCATION \
    --project=$TENANT_PROJECT_ID
```