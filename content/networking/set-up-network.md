---
title: "Set up Network"
weight: 1
description: "Duration: 15 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
echo "export GKE_LOCATION=us-east4" >> ~/acm-workshop-variables.sh
echo "export GKE_NAME=gke" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
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
git push
```

## Check deployments

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Allow Networking for GKE project          ci        main    push   1960975064  1m11s    2m
✓       Enforce policies for GKE project          ci        main    push   1960968253  1m4s     4m
✓       GitOps for GKE project                    ci        main    push   1960959789  1m5s     7m
✓       Setting up GKE namespace/project          ci        main    push   1960908849  1m12s    21m
✓       Billing API in Config Controller project  ci        main    push   1960889246  1m0s     28m
✓       Initial commit                            ci        main    push   1960885850  1m8s     29m
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                     WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Network for GKE project  ci        main    push   1961289819  10s      1m
✓       Initial commit           ci        main    push   1961170391  56s      41m
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
getting 2 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                NAME                │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ acm-workshop-464-gke               │                      │
│                                       │ Namespace              │ config-control                     │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                  │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                     │                      │
│ compute.cnrm.cloud.google.com         │ ComputeRouterNAT       │ gke                                │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeSubnetwork      │ gke                                │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeNetwork         │ gke                                │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeRouter          │ gke                                │ acm-workshop-464-gke │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                          │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext             │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ network-admin-acm-workshop-464-gke │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-gke               │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-gke-sa-wi-user    │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-gke               │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com        │ config-control       │
└───────────────────────────────────────┴────────────────────────┴────────────────────────────────────┴──────────────────────┘
```