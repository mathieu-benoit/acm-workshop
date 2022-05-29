---
title: "Install ASM"
weight: 2
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "kcc", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
ASM_CHANNEL=rapid
ASM_LABEL=asm-managed
echo "export ASM_CHANNEL=${ASM_CHANNEL}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ASM_LABEL=${ASM_LABEL}" >> ${WORK_DIR}acm-workshop-variables.sh
ASM_VERSION=$ASM_LABEL
if [ $ASM_CHANNEL = "rapid" ] || [ $ASM_CHANNEL = "stable" ] ; then ASM_VERSION=$ASM_LABEL-$ASM_CHANNEL; fi
echo "export ASM_VERSION=${ASM_VERSION}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice note %}}
The possible values for `ASM_CHANNEL` are `regular`, `stable` or `rapid`.
{{% /notice %}}

## Define GKE ASM feature

Define the ASM [`GKEHubFeature`](https://cloud.google.com/config-connector/docs/reference/resource-docs/gkehub/gkehubfeature) resource:
```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/config-sync/gke-hub-feature-asm.yaml
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
cd ~/$TENANT_PROJECT_DIR_NAME/
git add .
git commit -m "ASM MCP for Tenant project"
git push origin main
```

## Define ASM ControlPlaneRevision

Create a dedicated `istio-system` folder in the GKE configs's Git repo:
```Bash
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system
```

Define the `istio-system` namespace:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: istio-system
EOF
```

Define ASM Managed Control Plane configs:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/control-plane-configs.yaml
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
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "ASM MCP for GKE cluster"
git push origin main
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

List the GitHub runs for the **Tenant project configs** repository `cd ~/$TENANT_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                           WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       ASM MCP for Tenant project                                     ci        main    push   1972180913  8m20s    14m
✓       Artifact Registry for GKE cluster                              ci        main    push   1972095446  1m11s    12m
✓       GitOps for GKE cluster configs                                 ci        main    push   1970974465  53s      7h
✓       GKE cluster, primary nodepool and SA for Tenant project        ci        main    push   1963473275  1m16s    1d
✓       Network for Tenant project                                     ci        main    push   1961289819  1m13s    1d
✓       Initial commit                                                 ci        main    push   1961170391  56s      1d
```

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       ASM MCP for GKE cluster                               ci        main    push   1972222841  56s      1m
✓       Enforce Container Registries Policies in GKE cluster  ci        main    push   1972138349  55s      42m
✓       Policies for NetworkPolicy resources                  ci        main    push   1971716019  1m14s    3h
✓       Network Policies logging                              ci        main    push   1971353547  1m1s     5h
✓       Config Sync monitoring                                ci        main    push   1971296656  1m9s     5h
✓       Initial commit                                        ci        main    push   1970951731  57s      7h
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
│ artifactregistry.cnrm.cloud.google.com │ ArtifactRegistryRepository │ containers                                │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                        │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ servicemesh                               │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ configmanagement                          │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeatureMembership    │ gke-acm-membership                        │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                          │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-reader                   │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                             │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                         │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ gke-primary-pool-sa-cs-monitoring-wi-user │ acm-workshop-464-tenant │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬──────────────────────┬──────────────────────────────┬──────────────────────────────┐
│           GROUP           │         KIND         │             NAME             │          NAMESPACE           │
├───────────────────────────┼──────────────────────┼──────────────────────────────┼──────────────────────────────┤
│                           │ Namespace            │ istio-system                 │                              │
│                           │ Namespace            │ config-management-monitoring │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos      │ allowed-container-registries │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels    │ namespace-required-labels    │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels    │ deployment-required-labels   │                              │
│ networking.gke.io         │ NetworkLogging       │ default                      │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate   │ k8srequiredlabels            │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate   │ k8sallowedrepos              │                              │
│                           │ ServiceAccount       │ default                      │ config-management-monitoring │
│ mesh.cloud.google.com     │ ControlPlaneRevision │ asm-managed-rapid            │ istio-system                 │
└───────────────────────────┴──────────────────────┴──────────────────────────────┴──────────────────────────────┘
```