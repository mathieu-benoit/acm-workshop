---
title: "Allow Config Sync"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["gitops-tips", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will bind the workload identity capability from the Online Boutique's `RepoSync` Kubernetes Service Account to the Artifact Registry reader Google Service Account created earlier.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINEBOUTIQUE_NAMESPACE=onlineboutique" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE
```

## Bind the Artifact Registry reader GSA to the Online Boutique's RepoSync

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/artifactregistry-charts-reader-workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: ${HELM_CHARTS_READER_GSA}-${ONLINEBOUTIQUE_NAMESPACE}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${HELM_CHARTS_READER_GSA}
spec:
  resourceRef:
    name: ${HELM_CHARTS_READER_GSA}
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${TENANT_PROJECT_ID}.svc.id.goog[config-management-system/ns-reconciler-${ONLINEBOUTIQUE_NAMESPACE}]
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Artifact Registry viewer for Online Boutique's RepoSync" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMPartialPolicy-.->IAMServiceAccount
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