---
title: "Allow GKE"
weight: 1
description: "Duration: 5 min | Persona: Org Admin"
tags: ["gke", "kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will enable and grant the appropriate APIs in the Tenant project and the IAM role for the Tenant project's service account. This will allow later this service account to provision the GKE cluster.

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

## Define APIs

Define the Cloud Resources Manager API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the Tenant project:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/cloudresourcemanager-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}-cloudresourcemanager
  namespace: config-control
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  resourceID: cloudresourcemanager.googleapis.com
EOF
```

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

Later in the workshop, you can optionally leverage the GKE Security Posture features ([Scan workloads configurations](https://cloud.google.com/kubernetes-engine/docs/how-to/protect-workload-configuration) and [Scan container images for known vulnerabilities](https://cloud.google.com/kubernetes-engine/docs/how-to/security-posture-vulnerability-scanning)) in order to scan the configurations of your GKE workloads. Define the GKE Security Posture API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the Tenant project:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/containersecurity-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}-containersecurity
  namespace: config-control
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  resourceID: containersecurity.googleapis.com
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Allow GKE and GKE Security Posture for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMPolicyMember-.->IAMServiceAccount
  IAMPolicyMember-.->Project
  IAMPolicyMember-.->IAMServiceAccount
  IAMPolicyMember-.->Project
  IAMPolicyMember-.->IAMServiceAccount
  IAMPolicyMember-.->Project
  IAMPolicyMember-.->IAMServiceAccount
  IAMPolicyMember-.->Project
  Service-.->Project
  Service-.->Project
  Service-.->Project
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Host project configs** repository:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud services list \
    --enabled \
    --project ${TENANT_PROJECT_ID} \
    | grep -E 'container'
gcloud projects get-iam-policy $TENANT_PROJECT_ID \
    --filter="bindings.members:${TENANT_PROJECT_SA_EMAIL}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
Wait and re-run this command above until you see the resources created.