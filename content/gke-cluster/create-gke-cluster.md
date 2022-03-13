---
title: "Create the GKE cluster"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
echo "export GKE_PROJECT_NUMBER=$(gcloud projects describe $GKE_PROJECT_ID --format='get(projectNumber)')" >> ~/acm-workshop-variables.sh
echo "export GKE_SA=gke-primary-pool" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Define GKE cluster

Define the GKE cluster with empty node pool:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-cluster.yaml
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerCluster
metadata:
  name: ${GKE_NAME}
  namespace: ${GKE_PROJECT_ID}
  annotations:
    cnrm.cloud.google.com/remove-default-node-pool: "true"
  labels:
    mesh_id: proj-${GKE_PROJECT_NUMBER}
spec:
  addonsConfig:
    dnsCacheConfig:
      enabled: true
    gcePersistentDiskCsiDriverConfig:
      enabled: true
    httpLoadBalancing:
      disabled: false
  confidentialNodes:
    enabled: true
  datapathProvider: ADVANCED_DATAPATH
  enableShieldedNodes: true
  initialNodeCount: 1
  ipAllocationPolicy:
    servicesSecondaryRangeName: servicesrange
    clusterSecondaryRangeName: clusterrange
  location: ${GKE_LOCATION}
  loggingConfig:
    enableComponents:
      - "SYSTEM_COMPONENTS"
      - "WORKLOADS"
  monitoringConfig:
    enableComponents:
      - "SYSTEM_COMPONENTS"
  networkingMode: VPC_NATIVE
  networkRef:
    name: gke
  nodeConfig:
    machineType: n2d-standard-4
  privateClusterConfig:
    enablePrivateEndpoint: false
    enablePrivateNodes: true
    masterIpv4CidrBlock: 172.16.0.0/28
  releaseChannel:
    channel: RAPID
  subnetworkRef:
    name: gke
  workloadIdentityConfig:
    workloadPool: ${GKE_PROJECT_ID}.svc.id.goog
EOF
```

## Define GKE primary node pool's service account

Define the GKE primary node pool's service account:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-primary-pool-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${GKE_SA}
  namespace: ${GKE_PROJECT_ID}
spec:
  displayName: ${GKE_SA}
EOF
```

Define the `logging.logWriter`, `monitoring.metricWriter` and `monitoring.viewer` roles with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) resource for the GKE primary node pool's service account:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/log-writer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: log-writer
  namespace: ${GKE_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${GKE_PROJECT_ID}
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: ${GKE_PROJECT_ID}
  role: roles/logging.logWriter
EOF
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/metric-writer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: metric-writer
  namespace: ${GKE_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${GKE_PROJECT_ID}
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: ${GKE_PROJECT_ID}
  role: roles/monitoring.metricWriter
EOF
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/monitoring-viewer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: monitoring-viewer
  namespace: ${GKE_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${GKE_PROJECT_ID}
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: ${GKE_PROJECT_ID}
  role: roles/monitoring.viewer
EOF
```

## Define GKE primary node pool

Define the GKE primary node pool:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-primary-pool.yaml
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerNodePool
metadata:
  name: primary
  namespace: ${GKE_PROJECT_ID}
spec:
  clusterRef:
    name: ${GKE_NAME}
  initialNodeCount: 1
  location: ${GKE_LOCATION}
  management:
    autoRepair: true
    autoUpgrade: true
  nodeConfig:
    imageType: COS_CONTAINERD
    diskSizeGb: 100
    diskType: pd-ssd
    labels:
      gke.io/nodepool: primary
    machineType: n2d-standard-4
    shieldedInstanceConfig:
      enableIntegrityMonitoring: true
      enableSecureBoot: true
    serviceAccountRef:
      name: ${GKE_SA}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "GKE cluster, primary nodepool and SA for GKE project"
git push
```

## Check deployments

List the GCP resources created:
```Bash
gcloud projects get-iam-policy $GKE_PROJECT_ID \
    --filter="bindings.members:${GKE_SA}@${GKE_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud container clusters list \
    --project $GKE_PROJECT_ID
gcloud container node-pools list \
    --cluster $GKE_NAME \
    --project $GKE_PROJECT_ID
```
```Plaintext
ROLE
roles/logging.logWriter
roles/monitoring.metricWriter
roles/monitoring.viewer
NAME  LOCATION  MASTER_VERSION  MASTER_IP    MACHINE_TYPE    NODE_VERSION    NUM_NODES  STATUS
gke   us-east4  1.22.6-gke.300  34.86.8.164  n2d-standard-4  1.22.6-gke.300  3          RUNNING
NAME     MACHINE_TYPE    DISK_SIZE_GB  NODE_VERSION
primary  n2d-standard-4  100           1.22.6-gke.300
```

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GKE cluster, primary nodepool and SA for GKE project  ci        main    push   1963473275  1m16s    11h
✓       Network for GKE project                               ci        main    push   1961289819  1m13s    20h
✓       Initial commit                                        ci        main    push   1961170391  56s      20h
```

List the Kubernetes resources managed by Config Sync in **Config Controller**:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
    --managed-resources all \
    --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
```Plaintext
getting 2 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬───────────────────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                        NAME                       │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ acm-workshop-464-gke                              │                      │
│                                       │ Namespace              │ config-control                                    │                      │
│ constraints.gatekeeper.sh             │ LimitGKECluster        │ allowed-gke-cluster                               │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                                 │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                                    │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitgkecluster                                   │                      │
│ compute.cnrm.cloud.google.com         │ ComputeSubnetwork      │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeRouterNAT       │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeRouter          │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeNetwork         │ gke                                               │ acm-workshop-464-gke │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                                         │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com       │ ContainerCluster       │ gke                                               │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com       │ ContainerNodePool      │ primary                                           │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ log-writer                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ metric-writer                                     │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ monitoring-viewer                                 │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ gke-primary-pool                                  │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ iam-admin-acm-workshop-464-gke                    │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-gke-sa-wi-user                   │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ network-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-gke                              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-admin-acm-workshop-464-gke        │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ container-admin-acm-workshop-464-gke              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-user-acm-workshop-464-gke         │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-gke                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com                       │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ container.googleapis.com                          │ config-control       │
└───────────────────────────────────────┴────────────────────────┴───────────────────────────────────────────────────┴──────────────────────┘
```