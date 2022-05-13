---
title: "Set up Memorystore"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_PROJECT_ID=acm-workshop-463" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_PROJECT_DIR_NAME=acm-workshop-gke-project-repo" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_LOCATION=us-east4" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_NAME=gke" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_NAME=cart-${ONLINEBOUTIQUE_NAMESPACE}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
cd ~
git clone https://github.com/mathieu-benoit/$GKE_PROJECT_DIR_NAME
mkdir ~/$GKE_PROJECT_DIR_NAME/config-sync/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Memorystore (redis)

Define the [Memorystore (redis) resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/redis/redisinstance):
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/$ONLINEBOUTIQUE_NAMESPACE/memorystore.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  name: ${REDIS_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  region: ${GKE_LOCATION}
  tier: BASIC
  memorySizeGb: 1
  redisVersion: REDIS_6_X
  authorizedNetworkRef:
    name: ${GKE_NAME}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Memorystore (redis) instance for ${ONLINEBOUTIQUE_NAMESPACE}"
git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeNetwork-.->Project
  RedisInstance-.->Project
  RedisInstance-->ComputeNetwork
{{< /mermaid >}}

List the GCP resources created:
```Bash
gcloud redis instances list \
    --region=$GKE_LOCATION \
    --project=$GKE_PROJECT_ID \
    | grep $ONLINEBOUTIQUE_NAMESPACE
```
```Plaintext
INSTANCE_NAME  VERSION    REGION    TIER   SIZE_GB  HOST            PORT  NETWORK  RESERVED_IP        STATUS  CREATE_TIME
cart-ob-team1  REDIS_6_X  us-east4  BASIC  1        10.234.239.235  6379  gke      10.234.239.232/29  READY   2022-03-14T02:40:24
```

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE`:
```Plaintext
completed       Memorystore (redis) instance for ob-team1                     ci        main    push   1978366334  1m9s     1m
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **GKE project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $GKE_PROJECT_ID \
    | grep $ONLINEBOUTIQUE_NAMESPACE
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
│ redis.cnrm.cloud.google.com            │ RedisInstance              │ cart-ob-team1                             │ acm-workshop-464-gke │
```

## Get Memorystore (redis) connection information

Make sure the Memorystore (redis) instance is successfully provisioned and get its associated connection information we will leverage in the next section:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(port)')
echo $REDIS_IP
echo $REDIS_PORT
echo "export REDIS_IP=${REDIS_IP}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_PORT=${REDIS_PORT}" >> ${WORK_DIR}acm-workshop-variables.sh
```