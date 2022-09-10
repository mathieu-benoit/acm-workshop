---
title: "Create Memorystore"
weight: 10
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will create a Memorystore (redis) instance for the Online Boutique's `cartservice` app to connect to. We will also create a second Memorystore (redis) with TLS enabled.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_NAME=cart" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_TLS_NAME=cart-tls" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Create a folder dedicated for any resources related Online Boutique specifically: 
```Bash
mkdir ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Memorystore (redis)

Define the [Memorystore (redis) resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/redis/redisinstance):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/memorystore.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  name: ${REDIS_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
spec:
  authorizedNetworkRef:
    name: ${GKE_NAME}
  memorySizeGb: 1
  redisVersion: REDIS_6_X
  region: ${GKE_LOCATION}
  tier: BASIC
EOF
```

## Define Memorystore (redis) with TLS enabled

Define the [Memorystore (redis) resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/redis/redisinstance) with TLS enabled:
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/memorystore-tls.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  name: ${REDIS_TLS_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
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
git add . && git commit -m "Memorystore (redis) instance" && git push origin main
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
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

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