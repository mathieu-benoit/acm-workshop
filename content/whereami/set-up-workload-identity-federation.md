---
title: "Set up Workload Identity Federation"
weight: 3
description: "Duration: 3 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin", "security-tips", "wif"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up Workload Identity Federation for the Whereami GitHub repository.

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Configure the Workload Identity Federation

Define the [Workload Identity Pool](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iamworkloadidentitypool):
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/containers-builder-workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: containers-builder-sa-wi-user
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${CONTAINERS_BUILDER_SERVICE_ACCOUNT_NAME}
spec:
  resourceRef:
    name: ${CONTAINERS_BUILDER_SERVICE_ACCOUNT_NAME}
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: principalSet://iam.googleapis.com/projects/${TENANT_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WORKLOAD_IDENTITY_POOL_NAME}/attribute.repository/${WHERE_AMI_REPO_NAME_WITH_OWNER}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Setting up Workload Identity Federation for Whereami repository" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMPartialPolicy-.->IAMServiceAccount
  IAMPartialPolicy-.->Project
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