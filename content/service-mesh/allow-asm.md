---
title: "Allow ASM"
weight: 1
description: "Duration: 5 min | Persona: Org Admin"
tags: ["asm", "kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will enable and grant the appropriate APIs in the Tenant project and the IAM role for the Tenant project's service account to allow later this service account configure a Service Mesh for your GKE cluster. You will also enable the Anthos API in order to leverage the Service Mesh feature from within the Google Cloud console.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define APIs

Define the Mesh API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource in the Tenant project:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/mesh-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}-mesh
  namespace: config-control
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  resourceID: mesh.googleapis.com
EOF
```

Define the Anthos API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource in the Tenant project:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/anthos-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}-anthos
  namespace: config-control
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  resourceID: anthos.googleapis.com
EOF
```
{{% notice info %}}
We are enabling the Anthos API here because that's how you will access to Anthos Service Mesh (ASM) advanced features from within the Google Cloud console, such as ASM Topology, ASM Monitoring, etc.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Allow ASM for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-->Project
  IAMPartialPolicy-->IAMServiceAccount
  ConfigConnectorContext-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  Service-->Project
  Service-->Project
  Service-->Project
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