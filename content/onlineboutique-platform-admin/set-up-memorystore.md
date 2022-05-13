---
title: "Set up Memorystore"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will provision a Memorystore (redis) instance. This database will be used by `cartservice` later.

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

A GitHub repository already exists where all the Kubernetes manifests to deploy the infrastructure are stored. Here you are cloning this repo in order to add the Memorystore (redis) manifest:
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
  redisVersion: REDIS_5
  authorizedNetworkRef:
    name: ${GKE_NAME}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Memorystore (redis) instance version 5 for ${ONLINEBOUTIQUE_NAMESPACE}"
git push origin main
```

## Check if there is any issue

In order to see the details of the associated GitHub action run, run this command below and follow the indication in order to get more information about the potential errors:
```
cd ~/$GKE_PROJECT_DIR_NAME && gh run view
```

The output of the logs should be similar to:
```Plaintext
build   gatekeeper      2022-05-13T15:17:03.1023978Z ##[group]Run kpt fn eval config-sync/ --results-dir tmp --image gcr.io/kpt-fn/gatekeeper:v0.2
build   gatekeeper      2022-05-13T15:17:03.1024579Z kpt fn eval config-sync/ --results-dir tmp --image gcr.io/kpt-fn/gatekeeper:v0.2
build   gatekeeper      2022-05-13T15:17:03.1075613Z shell: /usr/bin/bash -e {0}
build   gatekeeper      2022-05-13T15:17:03.1075931Z env:
build   gatekeeper      2022-05-13T15:17:03.1076410Z   CLOUDSDK_METRICS_ENVIRONMENT: github-actions-setup-gcloud
build   gatekeeper      2022-05-13T15:17:03.1076722Z ##[endgroup]
build   gatekeeper      2022-05-13T15:17:03.1794889Z [RUNNING] "gcr.io/kpt-fn/gatekeeper:v0.2"
build   gatekeeper      2022-05-13T15:17:05.9183639Z [FAIL] "gcr.io/kpt-fn/gatekeeper:v0.2" in 2.7s
build   gatekeeper      2022-05-13T15:17:05.9184033Z   Results:
build   gatekeeper      2022-05-13T15:17:05.9184679Z     [error] redis.cnrm.cloud.google.com/v1beta1/RedisInstance/acm-workshop-464-gke/cart-ob-team1: Memorystore (redis) cart-ob-team1's version should be REDIS_6_X instead of REDIS_5. violatedConstraint: allowed-memorystore-redis
build   gatekeeper      2022-05-13T15:17:05.9185352Z   Stderr:
build   gatekeeper      2022-05-13T15:17:05.9185975Z     "[error] redis.cnrm.cloud.google.com/v1beta1/RedisInstance/acm-workshop-464-gke/cart-ob-team1 : Memorystore (redis) cart-ob-team1's version should be REDIS_6_X instead of REDIS_5."
build   gatekeeper      2022-05-13T15:17:05.9186600Z     "violatedConstraint: allowed-memorystore-redis"
build   gatekeeper      2022-05-13T15:17:05.9186910Z   Exit code: 1
build   gatekeeper      2022-05-13T15:17:05.9187062Z
build   gatekeeper      2022-05-13T15:17:05.9190369Z
build   gatekeeper      2022-05-13T15:17:05.9190772Z For complete results, see tmp/results.yaml
build   gatekeeper      2022-05-13T15:17:05.9198377Z
build   gatekeeper      2022-05-13T15:17:05.9234887Z ##[error]Process completed with exit code 1.
```

## Fix the issue

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
git commit -m "Memorystore (redis) instance version 6 for ${ONLINEBOUTIQUE_NAMESPACE}"
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

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE -m 1`:
```Plaintext
completed       Memorystore (redis) instance version 6 for ob-team1                     ci        main    push   1978366334  1m9s     1m
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
{{% notice info %}}
There is an issue currently with this command, you will get this error message: `ERROR: Timed out getting ConfigManagement object from krmapihost-configcontroller` instead.
{{% /notice %}}