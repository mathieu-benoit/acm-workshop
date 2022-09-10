---
title: "Create GKE cluster"
weight: 3
description: "Duration: 20 min | Persona: Platform Admin"
tags: ["gke", "kcc", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up a secured GKE cluster including features like: workload identity, least privilege service account for the nodes, Dataplane V2, private nodes, confidential and shielded nodes, etc.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export TENANT_PROJECT_NUMBER=$(gcloud projects describe $TENANT_PROJECT_ID --format='get(projectNumber)')" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_SA=gke-primary-pool" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define GKE cluster

Define the GKE cluster with empty node pool:
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-cluster.yaml
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
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-primary-pool-sa.yaml
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
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/log-writer-gke-sa.yaml
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
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/metric-writer-gke-sa.yaml
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
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/monitoring-viewer-gke-sa.yaml
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
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/cloudtrace-agent-gke-sa.yaml
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
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-primary-pool.yaml
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
    oauthScopes:
      - https://www.googleapis.com/auth/cloud-platform
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
  IAMServiceAccount-.->Project
  ContainerNodePool-->ContainerCluster
  ContainerNodePool-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-.->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-.->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-.->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-.->Project
  ContainerCluster-.->ComputeSubnetwork
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.
{{% notice note %}}
The creation of the `ContainerCluster` and `ContainerNodePool` can take ~15 mins.
{{% /notice %}}

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

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
    --project $TENANT_PROJECT_ID \
    --region $GKE_LOCATION
```
Wait and re-run this command above until you see the resources created.