---
title: "Enforce Artifact Registry policies"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["platform-admin", "policies", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will enforce policies in order to make sure that the containers in your clusters are coming from a restricted list of container registries.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define "Allowed container registries" policy

Define the `Constraint` based on the [`K8sAllowedRepos`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#k8sallowedrepos) `ConstraintTemplate` for `Pods`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/pod-allowed-container-registries.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: pod-allowed-container-registries
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires container images to begin with a string from the specified list.',
        remediation: 'Any container images should begin with a string from the specified list, they are the only container registries allowed.'
      }"
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
  parameters:
    repos:
    - auto
    - gcr.io/config-management-release
    - gcr.io/gke-release
    - gke.gcr.io
    - k8s.gcr.io
    - ${CONTAINER_REGISTRY_REPOSITORY}
EOF
```
{{% notice tip %}}
We are restricting the source of the container images in the GKE cluster. Only system container images and the images from your own private Artifact Registry can be deployed in your GKE cluster.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Policies for Artifact Registry" && git push origin main
```

## Check deployments

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