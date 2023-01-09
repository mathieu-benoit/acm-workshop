---
title: "Allow Monitoring"
weight: 4
description: "Duration: 2 min | Persona: Org Admin"
tags: ["kcc", "monitoring", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will grant the appropriate the IAM roles for the Tenant project's service account. This will allow later this service account to provision some monitoring features.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define roles

Define the `monitoring.uptimeCheckConfigEditor` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the Tenant project's service account:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/uptime-check-config-editor.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: uptime-check-config-editor-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/monitoring.uptimeCheckConfigEditor
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
```

Define the `monitoring.notificationChannelEditor` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the Tenant project's service account:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/notification-channel-editor.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: notification-channel-editor-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/monitoring.notificationChannelEditor
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
```

Define the `monitoring.alertPolicyEditor` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the Tenant project's service account:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/alert-policy-editor.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: alert-policy-editor-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/monitoring.alertPolicyEditor
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Allow Monitoring for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMPolicyMember-.->Project
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
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
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` too.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **Host project configs** repository:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud projects get-iam-policy $TENANT_PROJECT_ID \
    --filter="bindings.members:${TENANT_PROJECT_SA_EMAIL}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    | grep -E 'uptimeCheckConfigEditor|notificationChannelEditor|alertPolicyEditor'
```
Wait and re-run this command above until you see the resources created.