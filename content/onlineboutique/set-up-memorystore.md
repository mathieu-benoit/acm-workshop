---
title: "Set up Memorystore"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
echo "export REDIS_NAME=cart" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

```Bash
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
git commit -m "Memorystore (redis) instance"
git push
```

## Get Memorystore (redis) connection information

Make sure the Memorystore (redis) instance is successfully provisioned and grab its associated connection information we will leverage in the next section:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(port)')
echo $REDIS_IP
echo $REDIS_PORT
echo "export REDIS_IP=${REDIS_IP}" >> ~/acm-workshop-variables.sh
echo "export REDIS_PORT=${REDIS_PORT}" >> ~/acm-workshop-variables.sh
```

## Check deployments

List the GCP resources created:
```Bash
gcloud redis instances list \
    --region=$GKE_LOCATION \
    --project=$GKE_PROJECT_ID
```
```Plaintext
INSTANCE_NAME  VERSION    REGION    TIER   SIZE_GB  HOST            PORT  NETWORK  RESERVED_IP        STATUS  CREATE_TIME
cart           REDIS_6_X  us-east4  BASIC  1        10.234.239.235  6379  gke      10.234.239.232/29  READY   2022-03-14T02:40:24
```

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                          WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Memorystore (redis) instance                                  ci        main    push   1978366334  1m9s     1m
✓       Ingress Gateway's SSL policy                                  ci        main    push   1975231271  1m1s     23h
✓       Ingress Gateway's public static IP address                    ci        main    push   1974996579  59s      1d
✓       ASM MCP for GKE project                                       ci        main    push   1972180913  8m20s    1d
✓       GitOps for GKE cluster configs                                ci        main    push   1970974465  53s      2d
✓       GKE cluster, primary nodepool and SA for GKE project          ci        main    push   1963473275  1m16s    3d
✓       Network for GKE project                                       ci        main    push   1961289819  1m13s    3d
✓       Initial commit                                                ci        main    push   1961170391  56s      3d
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **GKE project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $GKE_PROJECT_ID
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌────────────────────────────────────────┬────────────────────────────┬───────────────────────────────────────────┬──────────────────────┐
│                 GROUP                  │            KIND            │                    NAME                   │      NAMESPACE       │
├────────────────────────────────────────┼────────────────────────────┼───────────────────────────────────────────┼──────────────────────┤
│ artifactregistry.cnrm.cloud.google.com │ ArtifactRegistryRepository │ containers                                │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSSLPolicy           │ gke-asm-ingressgateway                    │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSecurityPolicy      │ gke-asm-ingressgateway                    │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeAddress             │ gke-asm-ingressgateway                    │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeatureMembership    │ gke-acm-membership                        │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ gke-asm                                   │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                        │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ gke-acm                                   │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-reader                   │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                             │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ gke-primary-pool-sa-cs-monitoring-wi-user │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                          │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                │ acm-workshop-464-gke │
│ redis.cnrm.cloud.google.com            │ RedisInstance              │ cart                                      │ acm-workshop-464-gke │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```