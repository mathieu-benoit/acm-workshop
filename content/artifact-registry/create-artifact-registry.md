---
title: "Create Artifact Registry"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export CONTAINER_REGISTRY_NAME=containers" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONTAINER_REGISTRY_REPOSITORY=${GKE_LOCATION}-docker.pkg.dev/${TENANT_PROJECT_ID}/${CONTAINER_REGISTRY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Artifact Registry resource

Define the [Artifact Registry resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/artifactregistry/artifactregistryrepository):
```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/config-sync/artifactregistry.yaml
apiVersion: artifactregistry.cnrm.cloud.google.com/v1beta1
kind: ArtifactRegistryRepository
metadata:
  name: ${CONTAINER_REGISTRY_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  format: DOCKER
  location: ${GKE_LOCATION}
EOF
```

## Define Artifact Registry reader role

```Bash
cat <<EOF > ~/$TENANT_PROJECT_DIR_NAME/config-sync/artifactregistry-reader.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: artifactregistry-reader
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${GKE_SA},artifactregistry.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ArtifactRegistryRepository/${CONTAINER_REGISTRY_NAME}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${TENANT_PROJECT_ID}
  resourceRef:
    kind: ArtifactRegistryRepository
    name: ${CONTAINER_REGISTRY_NAME}
  role: roles/artifactregistry.reader
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$TENANT_PROJECT_DIR_NAME/
git add .
git commit -m "Artifact Registry for GKE cluster"
git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ComputeNetwork-.->Project
  IAMServiceAccount-.->Project
  GKEHubFeature-.->Project
  ArtifactRegistryRepository-.->Project
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
gcloud projects get-iam-policy $TENANT_PROJECT_ID \
    --filter="bindings.members:${GKE_SA}@${TENANT_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud artifacts repositories get-iam-policy $CONTAINER_REGISTRY_NAME \
    --location $GKE_LOCATION \
    --filter="bindings.members:${GKE_SA}@${TENANT_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud artifacts repositories list \
    --project $TENANT_PROJECT_ID
```
```Plaintext
ROLE
roles/logging.logWriter
roles/monitoring.metricWriter
roles/monitoring.viewer
ROLE
roles/artifactregistry.reader
REPOSITORY  FORMAT  DESCRIPTION  LOCATION  LABELS                ENCRYPTION          CREATE_TIME          UPDATE_TIME
containers  DOCKER               us-east4  managed-by-cnrm=true  Google-managed key  2022-03-11T22:12:35  2022-03-11T22:12:35
```

List the GitHub runs for the **Tenant project configs** repository `cd ~/$TENANT_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                     WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Artifact Registry for GKE cluster                        ci        main    push   1972095446  1m11s    12m
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
│ artifactregistry.cnrm.cloud.google.com │ ArtifactRegistryRepository │ containers                                │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-tenant │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-tenant │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-tenant │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                        │ acm-workshop-464-tenant │
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