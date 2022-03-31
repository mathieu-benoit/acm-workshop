---
title: "Set up Artifact Registry"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
echo "export CONTAINER_REGISTRY_NAME=containers" >> ~/acm-workshop-variables.sh
echo "export CONTAINER_REGISTRY_REPOSITORY=${GKE_LOCATION}-docker.pkg.dev/${GKE_PROJECT_ID}/${CONTAINER_REGISTRY_NAME}" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Define Artifact Registry resource

Define the [Artifact Registry resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/artifactregistry/artifactregistryrepository):
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/artifactregistry.yaml
apiVersion: artifactregistry.cnrm.cloud.google.com/v1beta1
kind: ArtifactRegistryRepository
metadata:
  name: ${CONTAINER_REGISTRY_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  format: DOCKER
  location: ${GKE_LOCATION}
EOF
```

## Define Artifact Registry reader role

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/artifactregistry-reader.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: artifactregistry-reader
  namespace: ${GKE_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${GKE_PROJECT_ID}/IAMServiceAccount/${GKE_SA},artifactregistry.cnrm.cloud.google.com/namespaces/${GKE_PROJECT_ID}/ArtifactRegistryRepository/${CONTAINER_REGISTRY_NAME}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_SA}
      namespace: ${GKE_PROJECT_ID}
  resourceRef:
    apiVersion: artifactregistry.cnrm.cloud.google.com/v1beta1
    kind: ArtifactRegistryRepository
    name: ${CONTAINER_REGISTRY_NAME}
  role: roles/artifactregistry.reader
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Artifact Registry for GKE cluster"
git push origin main
```

## Check deployments

List the GCP resources created:
```Bash
gcloud projects get-iam-policy $GKE_PROJECT_ID \
    --filter="bindings.members:${GKE_SA}@${GKE_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud artifacts repositories get-iam-policy $CONTAINER_REGISTRY_NAME \
    --location $GKE_LOCATION \
    --filter="bindings.members:${GKE_SA}@${GKE_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud artifacts repositories list \
    --project $GKE_PROJECT_ID
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

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Artifact Registry for GKE cluster                     ci        main    push   1972095446  1m11s    12m
✓       GKE cluster, primary nodepool and SA for GKE project  ci        main    push   1963473275  1m16s    11h
✓       Network for GKE project                               ci        main    push   1961289819  1m13s    20h
✓       Initial commit                                        ci        main    push   1961170391  56s      20h
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
│ artifactregistry.cnrm.cloud.google.com │ ArtifactRegistryRepository │ containers                                │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                       │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                       │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                   │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                       │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                        │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ configmanagement                          │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeatureMembership    │ gke-acm-membership                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                          │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-reader                   │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                             │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ gke-primary-pool-sa-cs-monitoring-wi-user │ acm-workshop-464-gke │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────┴──────────────────────┘
```