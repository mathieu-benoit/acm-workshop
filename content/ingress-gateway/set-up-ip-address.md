---
title: "Set up IP address"
weight: 1
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_PUBLIC_IP_NAME=${GKE_NAME}-asm-ingressgateway" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define IP address

Define the Ingress Gateway's public static IP address resource:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/public-ip-address.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeAddress
metadata:
  name: ${INGRESS_GATEWAY_PUBLIC_IP_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  location: global
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Ingress Gateway's public static IP address"
git push origin main
```

## Get the provisioned IP address

```Bash
INGRESS_GATEWAY_PUBLIC_IP=$(gcloud compute addresses describe $INGRESS_GATEWAY_PUBLIC_IP_NAME --global --project ${GKE_PROJECT_ID} --format "value(address)")
echo ${INGRESS_GATEWAY_PUBLIC_IP}
echo "export INGRESS_GATEWAY_PUBLIC_IP=${INGRESS_GATEWAY_PUBLIC_IP}" >> ${WORK_DIR}acm-workshop-variables.sh
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
{{< /mermaid >}}

List the GCP resources created:
```Bash
gcloud compute addresses list \
    --project $GKE_PROJECT_ID
```
```Plaintext
NAME                                    ADDRESS/RANGE  TYPE      PURPOSE   NETWORK  REGION    SUBNET  STATUS
gke-asm-ingressgateway                  34.110.242.88  EXTERNAL                                       IN_USE
nat-auto-ip-5398467-6-1646921274443878  35.245.29.122  EXTERNAL  NAT_AUTO           us-east4          IN_USE
```

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                        WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Ingress Gateway's public static IP address                  ci        main    push   1974996579  59s      4m
✓       ASM MCP for GKE project                                     ci        main    push   1972180913  8m20s    21h
✓       GitOps for GKE cluster configs                              ci        main    push   1970974465  53s      1d
✓       GKE cluster, primary nodepool and SA for GKE project        ci        main    push   1963473275  1m16s    2d
✓       Network for GKE project                                     ci        main    push   1961289819  1m13s    2d
✓       Initial commit                                              ci        main    push   1961170391  56s      2d
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
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeAddress             │ gke-asm-ingressgateway                    │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                        │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ servicemesh                               │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ configmanagement                          │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeatureMembership    │ gke-acm-membership                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                          │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-reader                   │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                             │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ gke-primary-pool-sa-cs-monitoring-wi-user │ acm-workshop-464-gke │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```