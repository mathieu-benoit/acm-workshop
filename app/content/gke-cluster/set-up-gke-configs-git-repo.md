---
title: "Set up GKE configs's Git repo"
weight: 5
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["gitops-tips", "kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up Config Sync and Policy Controller for the GKE cluster. You will also configure a main/root GitHub repository for this GKE cluster.

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_CONFIGS_DIR_NAME=acm-workshop-gke-configs-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define ACM GKEHubFeature

Define the ACM [`GKEHubFeature`](https://cloud.google.com/config-connector/docs/reference/resource-docs/gkehub/gkehubfeature) resource:
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-hub-feature-acm.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeature
metadata:
  name: configmanagement
  namespace: ${TENANT_PROJECT_ID}
spec:
  projectRef:
    external: ${TENANT_PROJECT_ID}
  location: global
  resourceID: configmanagement
EOF
```
{{% notice note %}}
The `resourceID` must be `configmanagement` if you want to use Anthos Config Management feature.
{{% /notice %}}

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-hub-membership.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubMembership
metadata:
  name: ${GKE_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
    config.kubernetes.io/depends-on: container.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/ContainerCluster/${GKE_NAME}
spec:
  location: global
  authority:
    issuer: https://container.googleapis.com/v1/projects/${TENANT_PROJECT_ID}/locations/${GKE_LOCATION}/clusters/${GKE_NAME}
  endpoint:
    gkeCluster:
      resourceRef:
        name: ${GKE_NAME}
EOF
```

## Create a main GitHub repository for all GKE configs

Create a dedicated GitHub repository where we will commit all the configs, policies, etc. we want to deploy in this GKE cluster:
```Bash
cd ${WORK_DIR}
gh repo create $GKE_CONFIGS_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME
git pull
git checkout main
GKE_CONFIGS_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RootSync with this GitHub repository 

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-acm-membership.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeatureMembership
metadata:
  name: ${GKE_NAME}-acm-membership
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: gkehub.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/GKEHubMembership/${GKE_NAME},gkehub.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/GKEHubFeature/configmanagement
spec:
  projectRef:
    external: ${TENANT_PROJECT_ID}
  location: global
  membershipRef:
    name: ${GKE_NAME}
  featureRef:
    name: configmanagement
  configmanagement:
    configSync:
      sourceFormat: unstructured
      preventDrift: true
      git:
        policyDir: .
        secretType: none
        syncBranch: main
        syncRepo: ${GKE_CONFIGS_REPO_URL}
    policyController:
      enabled: true
      referentialRulesEnabled: true
      logDeniesEnabled: true
      templateLibraryInstalled: true
    version: "1.14.0"
EOF
```
{{% notice tip %}}
We explicitly set the Config Management's `version` field with the current version. It's a best practice to do this, as you are responsible to manually upgrade this component as [new versions are coming](https://cloud.google.com/anthos-config-management/docs/release-notes). So you will be able to update this file accordingly in order to trigger the upgrade of Config Management with the new version.
{{% /notice %}}

{{% notice info %}}
We explicitly set the Policy Controller's `templateLibraryInstalled` field to `true`, in order to install the [default library of `ConstraintTemplates`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library).
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "GitOps for GKE cluster configs" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  GKEHubFeature-.->Project
  GKEHubFeatureMembership-->GKEHubMembership
  GKEHubFeatureMembership-->GKEHubFeature
  GKEHubFeatureMembership-.->Project
  GKEHubMembership-->ContainerCluster
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="gcloud" %}}
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{% tab name="UI" %}}
Alternatively, you could also see this from within the Cloud Console, by clicking on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/status?clusterName=${GKE_NAME}&id=${GKE_NAME}&project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `SYNCED`. And then you can also click on `View resources` to see the details.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud container fleet memberships list \
    --project $TENANT_PROJECT_ID
gcloud beta container fleet config-management status \
    --project $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see the resources created.
