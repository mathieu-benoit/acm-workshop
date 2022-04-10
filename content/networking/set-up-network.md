---
title: "Set up Network"
weight: 1
description: "Duration: 15 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_LOCATION=us-east4" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_NAME=gke" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define VPC and Subnet

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/vpc.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeNetwork
metadata:
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  routingMode: REGIONAL
  autoCreateSubnetworks: false
EOF
```

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/subnet.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeSubnetwork
metadata:
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${GKE_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
spec:
  ipCidrRange: 10.2.0.0/20
  region: ${GKE_LOCATION}
  networkRef:
    name: ${GKE_NAME}
  secondaryIpRange:
  - rangeName: servicesrange
    ipCidrRange: 10.3.0.0/20
  - rangeName: clusterrange
    ipCidrRange: 10.4.0.0/20
EOF
```

## Define Cloud NAT

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/router.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouter
metadata:
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${GKE_PROJECT_ID}/ComputeNetwork/${GKE_NAME}
spec:
  networkRef:
    name: ${GKE_NAME}
  region: ${GKE_LOCATION}
EOF
```

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/router-nat.yaml
apiVersion: compute.cnrm.cloud.google.com/v1beta1
kind: ComputeRouterNAT
metadata:
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${GKE_PROJECT_ID}/ComputeSubnetwork/${GKE_NAME},compute.cnrm.cloud.google.com/namespaces/${GKE_PROJECT_ID}/ComputeRouter/${GKE_NAME}
spec:
  natIpAllocateOption: AUTO_ONLY
  region: ${GKE_LOCATION}
  routerRef:
    name: ${GKE_NAME}
  sourceSubnetworkIpRangesToNat: LIST_OF_SUBNETWORKS
  subnetwork:
  - subnetworkRef:
      name: ${GKE_NAME}
    sourceIpRangesToNat:
    - ALL_IP_RANGES
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Network for GKE project"
git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeNetwork-.->Project
  ComputeSubnetwork-->ComputeNetwork
  ComputeRouterNAT-->ComputeSubnetwork
  ComputeRouterNAT-->ComputeRouter
  ComputeRouter-->ComputeNetwork
{{< /mermaid >}}

List the GCP resources created:
```Bash
gcloud compute networks list \
    --project $GKE_PROJECT_ID
gcloud compute networks subnets list \
    --project $GKE_PROJECT_ID
gcloud compute routers list \
    --project $GKE_PROJECT_ID
gcloud compute routers nats list \
    --router $GKE_NAME \
    --region $GKE_LOCATION \
    --project $GKE_PROJECT_ID
```
```Plaintext
NAME  SUBNET_MODE  BGP_ROUTING_MODE  IPV4_RANGE  GATEWAY_IPV4
gke   CUSTOM       REGIONAL
NAME  REGION    NETWORK  RANGE        STACK_TYPE  IPV6_ACCESS_TYPE  IPV6_CIDR_RANGE  EXTERNAL_IPV6_CIDR_RANGE
gke   us-east4  gke      10.2.0.0/20  IPV4_ONLY
NAME  REGION    NETWORK
gke   us-east4  gke
NAME  NAT_IP_ALLOCATE_OPTION  SOURCE_SUBNETWORK_IP_RANGES_TO_NAT
gke   AUTO_ONLY               LIST_OF_SUBNETWORKS
```

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                     WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Network for GKE project  ci        main    push   1961289819  10s      1m
✓       Initial commit           ci        main    push   1961170391  56s      41m
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
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-gke │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```