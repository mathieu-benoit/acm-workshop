---
title: "Create Artifact Registry"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["gitops-tips", "kcc", "platform-admin"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will set up your own private Artifact Registry to store both all the container images and the Helm charts required for this workshop. You will also grant viewer access to both: the GKE's GSA and Config Sync's GSA.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
CONTAINER_REGISTRY_NAME=containers
echo "export CONTAINER_REGISTRY_NAME=${CONTAINER_REGISTRY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
CHART_REGISTRY_NAME=charts
echo "export CHART_REGISTRY_NAME=${CHART_REGISTRY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
CONTAINER_REGISTRY_HOST_NAME=${GKE_LOCATION}-docker.pkg.dev
echo "export CONTAINER_REGISTRY_HOST_NAME=${CONTAINER_REGISTRY_HOST_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONTAINER_REGISTRY_REPOSITORY=${CONTAINER_REGISTRY_HOST_NAME}/${TENANT_PROJECT_ID}/${CONTAINER_REGISTRY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CHART_REGISTRY_REPOSITORY=${CONTAINER_REGISTRY_HOST_NAME}/${TENANT_PROJECT_ID}/${CHART_REGISTRY_NAME}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export HELM_CHARTS_READER_GSA=helm-charts-reader" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Artifact Registry `containers` repository

Define the [Artifact Registry `containers` repository](https://cloud.google.com/config-connector/docs/reference/resource-docs/artifactregistry/artifactregistryrepository):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/artifactregistry-containers.yaml
apiVersion: artifactregistry.cnrm.cloud.google.com/v1beta1
kind: ArtifactRegistryRepository
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${CONTAINER_REGISTRY_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  format: DOCKER
  location: ${GKE_LOCATION}
EOF
```

## Define Artifact Registry reader role for the GKE's GSA for the container images

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

## Define Artifact Registry `charts` repository

Define the [Artifact Registry `charts` repository](https://cloud.google.com/config-connector/docs/reference/resource-docs/artifactregistry/artifactregistryrepository):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/artifactregistry-charts.yaml
apiVersion: artifactregistry.cnrm.cloud.google.com/v1beta1
kind: ArtifactRegistryRepository
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${CHART_REGISTRY_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  format: DOCKER
  location: ${GKE_LOCATION}
EOF
```

## Define Artifact Registry reader role for the RepoSync's GSA for the Helm charts

Define the Helm charts registry's [Google Service Account](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamserviceaccount):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/repo-syncs-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${HELM_CHARTS_READER_GSA}
  namespace: ${TENANT_PROJECT_ID}
spec:
  displayName: ${HELM_CHARTS_READER_GSA}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/artifactregistry-charts-reader.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: artifactregistry-charts-reader
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${HELM_CHARTS_READER_GSA},artifactregistry.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ArtifactRegistryRepository/${CHART_REGISTRY_NAME}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${HELM_CHARTS_READER_GSA}
      namespace: ${TENANT_PROJECT_ID}
  resourceRef:
    kind: ArtifactRegistryRepository
    name: ${CHART_REGISTRY_NAME}
  role: roles/artifactregistry.reader
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Artifact Registry for containers and charts for GKE cluster" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  ArtifactRegistryRepository-.->Project
  IAMPolicyMember-->ArtifactRegistryRepository
  IAMPolicyMember-.->IAMServiceAccount
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${HOST_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` too.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud artifacts repositories get-iam-policy $CONTAINER_REGISTRY_NAME \
    --project $TENANT_PROJECT_ID \
    --location $GKE_LOCATION \
    --filter="bindings.members:${GKE_SA}@${TENANT_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud artifacts repositories list \
    --project $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see the resources created.