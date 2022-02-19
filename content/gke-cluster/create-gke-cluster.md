---
title: "Create the GKE cluster"
weight: 2
---

- Persona: Platform Admin
- Duration: 5 min
- Objectives:
  - FIXME

GKE cluster with empty node pool:
```Bash
GKE_PROJECT_NUMBER=$(gcloud projects describe $GKE_PROJECT_ID --format='get(projectNumber)')
cat <<EOF > ~/$GKE_PLATFORM_DIR_NAME/config-sync/gke-cluster.yaml
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerCluster
metadata:
  name: gke
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

GKE cluster's primary node pool:
```Bash
cat <<EOF > ~/$GKE_PLATFORM_DIR_NAME/config-sync/gke-primary-pool-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: gke-primary-pool
  namespace: ${GKE_PROJECT_ID}
spec:
  displayName: gke-primary-pool
EOF
```

```Bash
cat <<EOF > ~/$GKE_PLATFORM_DIR_NAME/config-sync/log-writer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: log-writer-gke
  namespace: ${GKE_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: gke-primary-pool
      namespace: ${GKE_PROJECT_ID}
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: ${GKE_PROJECT_ID}
  role: roles/logging.logWriter
EOF
```

```Bash
cat <<EOF > ~/$GKE_PLATFORM_DIR_NAME/config-sync/metric-writer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: metric-writer-gke
  namespace: ${GKE_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: gke-primary-pool
      namespace: ${GKE_PROJECT_ID}
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: ${GKE_PROJECT_ID}
  role: roles/monitoring.metricWriter
EOF
```

```Bash
cat <<EOF > ~/$GKE_PLATFORM_DIR_NAME/config-sync/monitoring-viewer-gke-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: monitoring-viewer-gke
  namespace: ${GKE_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: gke-primary-pool
      namespace: ${GKE_PROJECT_ID}
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: ${GKE_PROJECT_ID}
  role: roles/monitoring.viewer
EOF
```

```Bash
cat <<EOF > ~/$GKE_PLATFORM_DIR_NAME/config-sync/gke-primary-pool.yaml
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerNodePool
metadata:
  name: primary
  namespace: ${GKE_PROJECT_ID}
spec:
  clusterRef:
    name: gke
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
      name: gke-primary-pool
EOF
```

{{< tabs >}}
{{% tab name="git commit" %}}
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Create GKE cluster, GKE primary nodepool and associated sa for project ${GKE_PROJECT_ID}."
git push
```
{{% /tab %}}
{{% tab name="kubectl apply" %}}
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
kubectl apply -f .
```
{{% /tab %}}
{{< /tabs >}}