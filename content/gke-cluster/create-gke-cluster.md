---
title: "Create GKE cluster"
weight: 3
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export TENANT_PROJECT_NUMBER=$(gcloud projects describe $TENANT_PROJECT_ID --format='get(projectNumber)')" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_SA=gke-primary-pool" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define GKE cluster

Define the GKE cluster with empty node pool:
```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/gke-cluster.yaml
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerCluster
metadata:
  name: ${GKE_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    cnrm.cloud.google.com/remove-default-node-pool: "true"
    config.kubernetes.io/depends-on: compute.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ComputeSubnetwork/${GKE_NAME}
  labels:
    mesh_id: proj-${TENANT_PROJECT_NUMBER}
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
    workloadPool: ${TENANT_PROJECT_ID}.svc.id.goog
EOF
```

## Define GKE primary node pool's service account

Define the GKE primary node pool's service account:
```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/gke-primary-pool-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${GKE_SA}
  namespace: ${TENANT_PROJECT_ID}
spec:
  displayName: ${GKE_SA}
EOF
```

Define the `logging.logWriter`, `monitoring.metricWriter` and `monitoring.viewer` roles with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) resource for the GKE primary node pool's service account:
```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/log-writer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: log-writer
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${GKE_SA}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${TENANT_PROJECT_ID}
  resourceRef:
    kind: Project
    external: ${TENANT_PROJECT_ID}
  role: roles/logging.logWriter
EOF
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/metric-writer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: metric-writer
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${GKE_SA}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${TENANT_PROJECT_ID}
  resourceRef:
    kind: Project
    external: ${TENANT_PROJECT_ID}
  role: roles/monitoring.metricWriter
EOF
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/monitoring-viewer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: monitoring-viewer
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${GKE_SA}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${TENANT_PROJECT_ID}
  resourceRef:
    kind: Project
    external: ${TENANT_PROJECT_ID}
  role: roles/monitoring.viewer
EOF
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/cloudtrace-agent-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: cloudtrace-agent
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${GKE_SA}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${TENANT_PROJECT_ID}
  resourceRef:
    kind: Project
    external: ${TENANT_PROJECT_ID}
  role: roles/cloudtrace.agent
EOF
```

## Define GKE primary node pool

Define the GKE primary node pool:
```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/gke-primary-pool.yaml
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerNodePool
metadata:
  name: primary
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: container.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ContainerCluster/${GKE_NAME}
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
cd ~/$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "GKE cluster, primary nodepool and SA for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeNetwork-.->Project
  IAMServiceAccount-.->Project
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
{{< /mermaid >}}

List the Google Cloud resources created:
```Bash
gcloud projects get-iam-policy $TENANT_PROJECT_ID \
    --filter="bindings.members:${GKE_SA}@${TENANT_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud container clusters list \
    --project $TENANT_PROJECT_ID
gcloud container node-pools list \
    --cluster $GKE_NAME \
    --project $TENANT_PROJECT_ID
```
```Plaintext
ROLE
roles/cloudtrace.agent
roles/logging.logWriter
roles/monitoring.metricWriter
roles/monitoring.viewer
NAME  LOCATION  MASTER_VERSION  MASTER_IP    MACHINE_TYPE    NODE_VERSION    NUM_NODES  STATUS
gke   us-east4  1.22.6-gke.300  34.86.8.164  n2d-standard-4  1.22.6-gke.300  3          RUNNING
NAME     MACHINE_TYPE    DISK_SIZE_GB  NODE_VERSION
primary  n2d-standard-4  100           1.22.6-gke.300
```

List the GitHub runs for the **Tenant project configs** repository `cd ~/$TENANT_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                     WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GKE cluster, primary nodepool and SA for Tenant project  ci        main    push   1963473275  1m16s    11h
✓       Network for Tenant project                               ci        main    push   1961289819  1m13s    20h
✓       Initial commit                                           ci        main    push   1961170391  56s      20h
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
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                          │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                             │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                         │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ cloudtrace-agent                          │ acm-workshop-464-tenant │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```