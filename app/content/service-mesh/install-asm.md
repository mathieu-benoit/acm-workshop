---
title: "Install ASM"
weight: 2
description: "Duration: 15 min | Persona: Platform Admin"
tags: ["asm", "kcc", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will install a Managed Service Mesh for your GKE cluster. This will opt your cluster in a specific channel in order to get the upgrades handled by Google for the managed control plane and managed data plane.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define ASM feature for the tenant project

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
    name: ${TENANT_PROJECT_ID}
  location: global
  resourceID: servicemesh
EOF
```
{{% notice note %}}
The `resourceID` must be `servicemesh` if you want to use Managed Control Plane feature of Anthos Service Mesh.
{{% /notice %}}

## Define Managed ASM for the GKE cluster

Define the Managed ASM [`GKEHubFeatureMembership`](https://cloud.google.com/config-connector/docs/reference/resource-docs/gkehub/gkehubfeaturemembership) resource:
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/gke-mesh-membership.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeatureMembership
metadata:
  name: ${GKE_NAME}-mesh-membership
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: gkehub.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/GKEHubMembership/${GKE_NAME},gkehub.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/GKEHubFeature/servicemesh
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  location: global
  membershipRef:
    name: ${GKE_NAME}
  featureRef:
    name: servicemesh
  mesh:
    management: MANAGEMENT_AUTOMATIC
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Managed ASM for GKE cluster in Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  GKEHubFeature-.->Project
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
gcloud container fleet mesh describe \
    --project $TENANT_PROJECT_ID
```

For the result of the last command, in order to make sure the Managed ASM is successfully installed you should see something like this:
```Plaintext
createTime: '2022-12-30T05:07:47.372234169Z'
labels:
  managed-by-cnrm: 'true'
membershipSpecs:
  projects/827641929724/locations/global/memberships/gke:
    mesh:
      management: MANAGEMENT_AUTOMATIC
membershipStates:
  projects/827641929724/locations/global/memberships/gke:
    servicemesh:
      controlPlaneManagement:
        details:
        - code: REVISION_READY
          details: 'Ready: asm-managed-rapid'
        state: ACTIVE
      dataPlaneManagement:
        details:
        - code: OK
          details: Service is running.
        state: ACTIVE
    state:
      code: OK
      description: 'Revision(s) ready for use: asm-managed-rapid.'
      updateTime: '2022-12-30T05:20:57.379679757Z'
name: projects/acm-workshop-618-tenant/locations/global/features/servicemesh
resourceState:
  state: ACTIVE
spec: {}
state:
  state: {}
updateTime: '2022-12-30T05:21:02.601258121Z'
```
Wait and re-run this command above until you see both `controlPlaneManagement` and `dataPlaneManagement` with `state: ACTIVE`.

{{% notice note %}}
The Managed ASM provisioning could take around ~10 min.
{{% /notice %}}