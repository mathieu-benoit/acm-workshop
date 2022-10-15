---
title: "Set up Workload Identity Federation"
weight: 4
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin", "security-tips", "wif"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up Workload Identity Federation for the Tenant project. Workload Identity Federation will be used later in this workshop by the GitHub actions building the containers for the applications like Whereami and Online Boutique and then will push them into the private Artifact Registry. This replaces the need to download the Google Service Account keys, so it's improving your security posture.

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export WORKLOAD_IDENTITY_POOL_NAME=container-images-builder-wi-pool" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONTAINERS_BUILDER_SERVICE_ACCOUNT_NAME=container-images-builder" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Configure the Workload Identity Federation

Define the [Workload Identity Pool](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamworkloadidentitypool):
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/workkloadidentitypool.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMWorkloadIdentityPool
metadata:
  name: ${WORKLOAD_IDENTITY_POOL_NAME}
spec:
  location: global
  displayName: ${WORKLOAD_IDENTITY_POOL_NAME}
  projectRef:
    external: projects/${TENANT_PROJECT_ID}
EOF
```

Define the [Workload Identity Pool Provider](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamworkloadidentitypoolprovider) for the GitHub repositories:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/workkloadidentitypoolprovider.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMWorkloadIdentityPoolProvider
metadata:
  name: ${WORKLOAD_IDENTITY_POOL_NAME}
spec:
  projectRef:
    external: projects/${TENANT_PROJECT_ID}
  location: global
  workloadIdentityPoolRef:
    name: ${WORKLOAD_IDENTITY_POOL_NAME}
  attributeMapping:
    google.subject: assertion.repository
    attribute.actor: assertion.actor
    attribute.aud: assertion.aud
    attribute.repository: assertion.repository
  oidc:
    issuerUri: "https://token.actions.githubusercontent.com"
EOF
```

## Configure the Google Service Account

Define a [Google Service Account](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamserviceaccount) which will used later by the GitHub actions in order to build the container images:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/containers-builder-sa.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${CONTAINERS_BUILDER_SERVICE_ACCOUNT_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  displayName: ${CONTAINERS_BUILDER_SERVICE_ACCOUNT_NAME}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Setting up Workload Identity Federation" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-.->Project
  IAMWorkloadIdentityPool-.->Project
  IAMWorkloadIdentityPoolProvider-->IAMWorkloadIdentityPool
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RootSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Host project configs** repository:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud iam workload-identity-pools describe $WORKLOAD_IDENTITY_POOL_NAME \
    --location global \
    --project $TENANT_PROJECT_ID
gcloud iam workload-identity-pools providers describe $WORKLOAD_IDENTITY_POOL_NAME \
    --workload-identity-pool $WORKLOAD_IDENTITY_POOL_NAME \
    --location global \
    --project $TENANT_PROJECT_ID
```