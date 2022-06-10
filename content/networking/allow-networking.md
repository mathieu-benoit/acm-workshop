---
title: "Allow Networking"
weight: 1
description: "Duration: 2 min | Persona: Org Admin"
tags: ["kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will enable and grant the appropriate APIs in the Tenant project and the IAM role for the Tenant project's service account. This will allow later this service account to provision the networking services.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define role

Define the `compute.networkAdmin` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the Tenant project's service account:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/network-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: network-admin-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/compute.networkAdmin
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
```

## Define API

Define the Compute Engine API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the Tenant project:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/compute-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}-compute
  namespace: config-control
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  resourceID: compute.googleapis.com
EOF
```
{{% notice info %}}
Throughout this workshop, we are enabling the Google Cloud services APIs from the **Org Admin**, it allows more control and governance over which Google Cloud services APIs the **Platform Admin** could use or not.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Allow Networking for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-->Project
  IAMPartialPolicy-->IAMServiceAccount
  ConfigConnectorContext-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
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
gcloud projects get-iam-policy $TENANT_PROJECT_ID \
    --filter="bindings.members:${TENANT_PROJECT_SA_EMAIL}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
Wait and re-run this command above until you see the resources created.