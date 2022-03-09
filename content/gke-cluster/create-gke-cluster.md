---
title: "Create the GKE cluster"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
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

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
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
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```