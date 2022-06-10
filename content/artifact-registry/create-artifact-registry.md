---
title: "Create Artifact Registry"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up 

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
CONTAINER_REGISTRY_NAME=containers
echo "export CONTAINER_REGISTRY_NAME=${CONTAINER_REGISTRY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONTAINER_REGISTRY_REPOSITORY=${GKE_LOCATION}-docker.pkg.dev/${TENANT_PROJECT_ID}/${CONTAINER_REGISTRY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Artifact Registry resource

Define the [Artifact Registry resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/artifactregistry/artifactregistryrepository):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/artifactregistry.yaml
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
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/artifactregistry-reader.yaml
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
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Artifact Registry for GKE cluster" && git push origin main
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

List the Google Cloud resources created:
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