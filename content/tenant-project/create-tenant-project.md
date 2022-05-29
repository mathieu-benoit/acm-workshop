---
title: "Create Tenant project"
weight: 1
description: "Duration: 10 min | Persona: Org Admin"
tags: ["kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

Define variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
TENANT_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}-tenant
echo "export TENANT_PROJECT_ID=${TENANT_PROJECT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_PROJECT_SA_EMAIL=${TENANT_PROJECT_ID}@${HOST_PROJECT_ID}.iam.gserviceaccount.com" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Create a dedicated folder for this Tenant project resources:
```Bash
mkdir ~/$HOST_PROJECT_DIR_NAME/config-sync/projects
mkdir ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID
```

## Define GCP project

Define the GCP project either at the Folder level or the Organization level:
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
At the Folder level:
```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/project.yaml
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
    external: "${ORG_OR_FOLDER_ID}"
  resourceID: ${TENANT_PROJECT_ID}
EOF
```
{{% /tab %}}
{{% tab name="Org level" %}}
At the Organization level:
```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/project.yaml
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
    external: "${ORG_OR_FOLDER_ID}"
  resourceID: ${TENANT_PROJECT_ID}
EOF
```
{{% /tab %}}
{{< /tabs >}}

## Define Tenant project service account

```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/service-account.yaml
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
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/workload-identity-user.yaml
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
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}
EOF
```

```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/config-connector-context.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnectorContext
metadata:
  name: configconnectorcontext.core.cnrm.cloud.google.com
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID}
spec:
  googleServiceAccount: ${GKE_PROJECT_SA_EMAIL}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$HOST_PROJECT_DIR_NAME/
git add .
git commit -m "Setting up Tenant namespace/project"
git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-->Project
  IAMPartialPolicy-->IAMServiceAccount
  ConfigConnectorContext-->IAMServiceAccount
{{< /mermaid >}}

List the GCP resources created:
```Bash
gcloud projects describe $TENANT_PROJECT_ID
gcloud iam service-accounts describe $GKE_PROJECT_SA_EMAIL \
    --project $HOST_PROJECT_ID
```

List the GitHub runs for the **Host project configs** repository `cd ~/$HOST_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Setting up Tenant namespace/project       ci        main    push   1960908849  1m12s    1m
✓       Billing API in Host project               ci        main    push   1960889246  1m0s     8m
✓       Initial commit                            ci        main    push   1960885850  1m8s     9m
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬─────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │               NAME              │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼─────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ config-control                  │                      │
│                                       │ Namespace              │ acm-workshop-464-tenant            │                      │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext          │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-tenant            │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-tenant-sa-wi-user │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-tenant            │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com     │ config-control       │
└───────────────────────────────────────┴────────────────────────┴─────────────────────────────────┴──────────────────────┘
```

Here, if you skipped the assignment of the `billing.user` role earlier while you were setting up your Config Controller instance, you will have an error with the creation of the `Project`. A simple way to make sure you don't have any error is to run this command below:
```Bash
kubectl get gcpproject -n config-control
```

If the output is similar to this below, you are good:
```Plaintext
NAMESPACE        NAME                     AGE     READY   STATUS     STATUS AGE
config-control   acm-workshop-464-tenant     24m     True    UpToDate   21m
```

But if you have this output below, that's where you will need to take actions:
```Plaintext
NAMESPACE        NAME                     AGE     READY   STATUS        STATUS AGE
config-control   acm-workshop-464-tenant     24m     True    UpdateFailed  21m
```

With a closer look at the error by running this command `kubectl descibe gcpproject -n config-control`, you will see that the error is similar too:
```Plaintext
Update call failed: error applying desired state: summary: Error setting billing account "XXX" for project "projects/acm-workshop-464-tenant": googleapi: Error 403: The caller does not have permission, forbidden
```

You can resolve this issue by running by yourself this command below:
```Bash
gcloud beta billing projects link $TENANT_PROJECT_ID \
    --billing-account $BILLING_ACCOUNT_ID
```

As Config Connector is still reconciling the resources, if you successfully ran this command, the error will disappear. You can run again the command `kubectl get gcpproject -n config-control` to make sure about that.

If you can't run the command above, the alternative is having someone in your organization (Billing Account or Organization admins) running it for you.