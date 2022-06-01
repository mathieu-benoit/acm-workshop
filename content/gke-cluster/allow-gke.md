---
title: "Allow GKE"
weight: 1
description: "Duration: 5 min | Persona: Org Admin"
tags: ["kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define roles

Define the `container.admin`, `iam.serviceAccountAdmin`, `resourcemanager.projectIamAdmin` and `iam.serviceAccountUser` roles with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) resource for the Tenant project's service account:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/container-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: container-admin-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/container.admin
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/service-account-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: service-account-admin-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/iam.serviceAccountAdmin
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/iam-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: iam-admin-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/resourcemanager.projectIamAdmin
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/service-account-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: service-account-user-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/iam.serviceAccountUser
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
```

## Define GKE API

Define the GKE API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the Tenant project:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/container-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}-container
  namespace: config-control
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  resourceID: container.googleapis.com
EOF
```
{{% notice info %}}
We are enabling the GCP services APIs from the Org Admin, it allows more control and governance over which GCP services APIs the Platform Admin could use or not. If you want to give more autonomy to the Platform Admin, you could grant the `serviceusage.serviceUsageAdmin` role to the associated service account.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Allow GKE for Tenant project" && git push origin main
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