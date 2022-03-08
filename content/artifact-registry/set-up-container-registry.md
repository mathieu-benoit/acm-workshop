---
title: "Set up Artifact Registry"
weight: 2
---
- Persona: Platform Admin
- Duration: 5 min

Initialize variables:
```Bash
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
git push
```