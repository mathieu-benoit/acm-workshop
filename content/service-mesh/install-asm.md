---
title: "Install ASM"
weight: 2
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "kcc", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will install a Managed Service Mesh for your GKE cluster. This will opt your cluster in a specific channel in order to get the upgrades handled by Google for the managed control plane.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
ASM_CHANNEL=rapid
ASM_VERSION=asm-managed-rapid
echo "export ASM_VERSION=${ASM_VERSION}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice info %}}
The possible values for `ASM_CHANNEL` are `regular`, `stable` or `rapid` and for `ASM_VERSION` are respectively `asm-managed`, `asm-managed-stable` or `asm-managed-rapid`.
{{% /notice %}}

## Define GKE ASM feature

Define the ASM [`GKEHubFeature`](https://cloud.google.com/config-connector/docs/reference/resource-docs/gkehub/gkehubfeature) resource:
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-hub-feature-asm.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeature
metadata:
  name: servicemesh
  namespace: ${TENANT_PROJECT_ID}
spec:
  projectRef:
    external: ${TENANT_PROJECT_ID}
  location: global
  resourceID: servicemesh
EOF
```
{{% notice note %}}
The `resourceID` must be `servicemesh` if you want to use Managed Control Plane feature of Anthos Service Mesh.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "ASM MCP for Tenant project" && git push origin main
```

## Define ASM ControlPlaneRevision

Create a dedicated `istio-system` folder in the GKE configs's Git repo:
```Bash
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system
```

Define the `istio-system` namespace:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
EOF
```

Define ASM Managed Control Plane configs:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system/control-plane-configs.yaml
apiVersion: mesh.cloud.google.com/v1beta1
kind: ControlPlaneRevision
metadata:
  name: ${ASM_VERSION}
  namespace: istio-system
  labels:
    mesh.cloud.google.com/managed-cni-enabled: "true"
spec:
  type: managed_service
  channel: ${ASM_CHANNEL}
EOF
```
{{% notice tip %}}
We are using `mesh.cloud.google.com/managed-cni-enabled: "true"` in order to leverage the Istio CNI has a best practice for security and performance perspectives. It's also mandatory when using the Managed Data Plane feature of ASM.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "ASM MCP for GKE cluster" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeNetwork-.->Project
  IAMServiceAccount-.->Project
  GKEHubFeature-.->Project
  ArtifactRegistryRepository-.->Project
  GKEHubFeature-.->Project
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

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud container fleet mesh describe \
    --project $TENANT_PROJECT_ID
```

For the result of the last command, in order to make sure the Managed ASM is successfully installed you should see something like this:
```Plaintext
createTime: '2022-06-01T13:09:24.580141475Z'
labels:
  managed-by-cnrm: 'true'
membershipStates:
  projects/561098358875/locations/global/memberships/gke:
    servicemesh:
      controlPlaneManagement:
        state: DISABLED
    state:
      code: OK
      description: 'Revision(s) ready for use: asm-managed-rapid.'
      updateTime: '2022-06-01T21:23:29.751309908Z'
name: projects/acm-workshop-742-tenant/locations/global/features/servicemesh
resourceState:
  state: ACTIVE
spec: {}
updateTime: '2022-06-01T21:23:39.459742087Z'
```