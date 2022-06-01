---
title: "Create Tenant project"
weight: 1
description: "Duration: 10 min | Persona: Org Admin"
tags: ["kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will create the Tenant project. 

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
TENANT_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}-tenant
echo "export TENANT_PROJECT_ID=${TENANT_PROJECT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export TENANT_PROJECT_SA_EMAIL=${TENANT_PROJECT_ID}@${HOST_PROJECT_ID}.iam.gserviceaccount.com" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Create a dedicated folder for this Tenant project resources:
```Bash
mkdir ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects
mkdir ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID
```

## Define GCP project

Define the GCP project either at the Folder level or the Organization level:
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
At the Folder level:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/project.yaml
apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
kind: Project
metadata:
  annotations:
    cnrm.cloud.google.com/auto-create-network: "false"
  name: ${TENANT_PROJECT_ID}
  namespace: config-control
spec:
  name: ${TENANT_PROJECT_ID}
  billingAccountRef:
    external: "${BILLING_ACCOUNT_ID}"
  folderRef:
    external: "${FOLDER_OR_ORG_ID}"
  resourceID: ${TENANT_PROJECT_ID}
EOF
```
{{% /tab %}}
{{% tab name="Org level" %}}
At the Organization level:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/project.yaml
apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
kind: Project
metadata:
  annotations:
    cnrm.cloud.google.com/auto-create-network: "false"
  name: ${TENANT_PROJECT_ID}
  namespace: config-control
spec:
  name: ${TENANT_PROJECT_ID}
  billingAccountRef:
    external: "${BILLING_ACCOUNT_ID}"
  organizationRef:
    external: "${FOLDER_OR_ORG_ID}"
  resourceID: ${TENANT_PROJECT_ID}
EOF
```
{{% /tab %}}
{{< /tabs >}}

## Define Tenant project service account

```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/service-account.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  displayName: ${TENANT_PROJECT_ID}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: ${TENANT_PROJECT_ID}-sa-wi-user
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID}
spec:
  resourceRef:
    name: ${TENANT_PROJECT_ID}
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${HOST_PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager-${TENANT_PROJECT_ID}]
EOF
```
{{% notice tip %}}
You could see that we use the annotation `config.kubernetes.io/depends-on`, [since the version 1.11 of Config Management](https://cloud.google.com/anthos-config-management/docs/release-notes#March_24_2022) we could declare [resource dependencies between resource objects](https://cloud.google.com/anthos-config-management/docs/how-to/declare-resource-dependency). KCC already handles dependencies with a retry loop with backoff, which can make things with long reconcile time even longer and generate warnings or errors on these resources. With that annotation we are optimizing these behaviors. We will use this annotation as much as we can throughout this workshop.
{{% /notice %}}

## Define Tenant project namespace and ConfigConnectorContext

```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/config-connector-context.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnectorContext
metadata:
  name: configconnectorcontext.core.cnrm.cloud.google.com
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID}
spec:
  googleServiceAccount: ${TENANT_PROJECT_SA_EMAIL}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Setting up Tenant namespace/project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-->Project
  IAMPartialPolicy-->IAMServiceAccount
  ConfigConnectorContext-->IAMServiceAccount
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
gcloud projects describe $TENANT_PROJECT_ID
gcloud iam service-accounts describe $TENANT_PROJECT_SA_EMAIL \
    --project $HOST_PROJECT_ID
```

## Resolve Tenant project creation issue

Let's make sure that the Tenant project has been successfully created.

Run this command below:
```Bash
kubectl get gcpproject -n config-control
```

If the output is similar to this below (`STATUS` `UpToDate`), you are good and you could move forward to the next page:
```Plaintext
NAME                      AGE   READY   STATUS     STATUS AGE
acm-workshop-742-tenant   50m   True    UpToDate   47m
```

But if you have this output below (`STATUS` `UpdateFailed`), that's where you will need to take actions:
```Plaintext
NAME                      AGE   READY   STATUS        STATUS AGE
acm-workshop-742-tenant   50m   True    UpdateFailed  47m
```

Run this command below to have a closer look at the details of the error:
```Bash
kubectl describe gcpproject -n config-control
```

The error you may have could be similar to:
```Plaintext
Update call failed: error applying desired state: summary: failed pre-requisites: missing permission on "billingAccounts/XXX": billing.resourceAssociations.create
```

We will resolve this issue by redeploying the `Project` resource by removing the `billingAccountRef` part.

Update the GCP project either at the Folder level or the Organization level:
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
At the Folder level:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/project.yaml
apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
kind: Project
metadata:
  annotations:
    cnrm.cloud.google.com/auto-create-network: "false"
  name: ${TENANT_PROJECT_ID}
  namespace: config-control
spec:
  name: ${TENANT_PROJECT_ID}
  folderRef:
    external: "${FOLDER_OR_ORG_ID}"
  resourceID: ${TENANT_PROJECT_ID}
EOF
```
{{% /tab %}}
{{% tab name="Org level" %}}
At the Organization level:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/project.yaml
apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
kind: Project
metadata:
  annotations:
    cnrm.cloud.google.com/auto-create-network: "false"
  name: ${TENANT_PROJECT_ID}
  namespace: config-control
spec:
  name: ${TENANT_PROJECT_ID}
  organizationRef:
    external: "${FOLDER_OR_ORG_ID}"
  resourceID: ${TENANT_PROJECT_ID}
EOF
```
{{% /tab %}}
{{< /tabs >}}

Re-deploy the `Project` resource:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Remove the billingAccountRef in order to create Tenant Project" && git push origin main
```

Wait for `status` `SYNCED` with this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```

And then, check that the Google Cloud project is created:
```Bash
gcloud projects describe $TENANT_PROJECT_ID
```

Then what you have to do is to manually assign the Billing Account to this project by running by yourself this command below:
```Bash
gcloud beta billing projects link $TENANT_PROJECT_ID \
    --billing-account $BILLING_ACCOUNT_ID
```

If you can't run the command above, the alternative is having someone in your organization (Billing Account or Organization admins) running it for you.