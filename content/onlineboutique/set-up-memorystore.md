---
title: "Set up Memorystore"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_NAME=cart" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir ~/$TENANT_PROJECT_DIR_NAME/config-sync/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Memorystore (redis)

Define the [Memorystore (redis) resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/redis/redisinstance):
```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/config-sync/$ONLINEBOUTIQUE_NAMESPACE/memorystore.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  name: ${REDIS_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
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
cd ~/$TENANT_PROJECT_DIR_NAME/
git add .
git commit -m "Memorystore (redis) instance"
git push origin main
```

## Get Memorystore (redis) connection information

Make sure the Memorystore (redis) instance is successfully provisioned and get its associated connection information we will leverage in the next section:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(port)')
echo $REDIS_IP
echo $REDIS_PORT
echo "export REDIS_IP=${REDIS_IP}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_PORT=${REDIS_PORT}" >> ${WORK_DIR}acm-workshop-variables.sh
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeNetwork-.->Project
  IAMServiceAccount-.->Project
  GKEHubFeature-.->Project
  ArtifactRegistryRepository-.->Project
  GKEHubFeature-.->Project
  ComputeAddress-.->Project
  ComputeSecurityPolicy-.->Project
  ComputeSSLPolicy-.->Project
  ComputeSubnetwork-->ComputeNetwork
  ComputeRouterNAT-->ComputeSubnetwork
  ComputeRouterNAT-->ComputeRouter
  ComputeRouter-->ComputeNetwork
  ContainerNodePool-->ContainerCluster
  ContainerNodePool-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPartialPolicy-->IAMServiceAccount
  ContainerCluster-->ComputeSubnetwork
  GKEHubFeatureMembership-->GKEHubMembership
  GKEHubFeatureMembership-->GKEHubFeature
  GKEHubMembership-->ContainerCluster
  IAMPolicyMember-->ArtifactRegistryRepository
  IAMPolicyMember-->IAMServiceAccount
  RedisInstance-.->Project
  RedisInstance-->ComputeNetwork
{{< /mermaid >}}

List the GCP resources created:
```Bash
gcloud redis instances list \
    --region=$GKE_LOCATION \
    --project=$TENANT_PROJECT_ID
```
```Plaintext
INSTANCE_NAME  VERSION    REGION    TIER   SIZE_GB  HOST            PORT  NETWORK  RESERVED_IP        STATUS  CREATE_TIME
cart           REDIS_6_X  us-east4  BASIC  1        10.234.239.235  6379  gke      10.234.239.232/29  READY   2022-03-14T02:40:24
```

List the GitHub runs for the **Tenant project configs** repository `cd ~/$TENANT_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                          WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Memorystore (redis) instance                                  ci        main    push   1978366334  1m9s     1m
✓       Ingress Gateway's SSL policy                                  ci        main    push   1975231271  1m1s     23h
✓       Ingress Gateway's public static IP address                    ci        main    push   1974996579  59s      1d
✓       ASM MCP for Tenant project                                    ci        main    push   1972180913  8m20s    1d
✓       GitOps for GKE cluster configs                                ci        main    push   1970974465  53s      2d
✓       GKE cluster, primary nodepool and SA for Tenant project       ci        main    push   1963473275  1m16s    3d
✓       Network for Tenant project                                    ci        main    push   1961289819  1m13s    3d
✓       Initial commit                                                ci        main    push   1961170391  56s      3d
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌────────────────────────────────────────┬────────────────────────────┬───────────────────────────────────────────┬──────────────────────┐
│                 GROUP                  │            KIND            │                    NAME                   │      NAMESPACE       │
├────────────────────────────────────────┼────────────────────────────┼───────────────────────────────────────────┼──────────────────────┤
│ artifactregistry.cnrm.cloud.google.com │ ArtifactRegistryRepository │ containers                                │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeSSLPolicy           │ gke-asm-ingressgateway                    │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeSecurityPolicy      │ gke-asm-ingressgateway                    │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeAddress             │ gke-asm-ingressgateway                    │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeatureMembership    │ gke-acm-membership                        │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ servicemesh                               │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                        │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ configmanagement                          │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-reader                   │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                             │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ gke-primary-pool-sa-cs-monitoring-wi-user │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                         │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                          │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                │ acm-workshop-464-tenant │
│ redis.cnrm.cloud.google.com            │ RedisInstance              │ cart                                      │ acm-workshop-464-tenant │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```