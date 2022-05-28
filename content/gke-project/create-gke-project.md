---
title: "Create GKE project"
weight: 1
description: "Duration: 10 min | Persona: Org Admin"
tags: ["kcc", "org-admin"]
---
_{{< param description >}}_

Define variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
GKE_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}-gke
echo "export GKE_PROJECT_ID=${GKE_PROJECT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_PROJECT_SA_EMAIL=${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Create a dedicated folder for this GKE project resources:
```Bash
mkdir ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects
mkdir ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID
```

## Define GCP project

Define the GCP project either at the Folder level or the Organization level:
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
At the Folder level:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/project.yaml
apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
kind: Project
metadata:
  annotations:
    cnrm.cloud.google.com/auto-create-network: "false"
  name: ${GKE_PROJECT_ID}
  namespace: config-control
spec:
  name: ${GKE_PROJECT_ID}
  billingAccountRef:
    external: "${BILLING_ACCOUNT_ID}"
  folderRef:
    external: "${ORG_OR_FOLDER_ID}"
  resourceID: ${GKE_PROJECT_ID}
EOF
```
{{% /tab %}}
{{% tab name="Org level" %}}
At the Organization level:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/project.yaml
apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
kind: Project
metadata:
  annotations:
    cnrm.cloud.google.com/auto-create-network: "false"
  name: ${GKE_PROJECT_ID}
  namespace: config-control
spec:
  name: ${GKE_PROJECT_ID}
  billingAccountRef:
    external: "${BILLING_ACCOUNT_ID}"
  organizationRef:
    external: "${ORG_OR_FOLDER_ID}"
  resourceID: ${GKE_PROJECT_ID}
EOF
```
{{% /tab %}}
{{< /tabs >}}

## Define GKE Project service account

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/service-account.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${GKE_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${GKE_PROJECT_ID}
spec:
  displayName: ${GKE_PROJECT_ID}
EOF
```

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: ${GKE_PROJECT_ID}-sa-wi-user
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${GKE_PROJECT_ID}
spec:
  resourceRef:
    name: ${GKE_PROJECT_ID}
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${CONFIG_CONTROLLER_PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager-${GKE_PROJECT_ID}]
EOF
```
{{% notice tip %}}
You could see that we use the annotation `config.kubernetes.io/depends-on`, [since the version 1.11 of Config Management](https://cloud.google.com/anthos-config-management/docs/release-notes#March_24_2022) we could declare [resource dependencies between resource objects](https://cloud.google.com/anthos-config-management/docs/how-to/declare-resource-dependency). KCC already handles dependencies with a retry loop with backoff, which can make things with long reconcile time even longer and generate warnings or errors on these resources. With that annotation we are optimizing these behaviors. We will use this annotation as much as we can throughout this workshop.
{{% /notice %}}

## Define GKE project namespace and ConfigConnectorContext

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
  name: ${GKE_PROJECT_ID}
EOF
```

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/config-connector-context.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnectorContext
metadata:
  name: configconnectorcontext.core.cnrm.cloud.google.com
  namespace: ${GKE_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${GKE_PROJECT_ID}
spec:
  googleServiceAccount: ${GKE_PROJECT_SA_EMAIL}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Setting up GKE namespace/project"
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
gcloud projects describe $GKE_PROJECT_ID
gcloud iam service-accounts describe $GKE_PROJECT_SA_EMAIL \
    --project $CONFIG_CONTROLLER_PROJECT_ID
```

List the GitHub runs for the **Org configs** repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Setting up GKE namespace/project          ci        main    push   1960908849  1m12s    1m
✓       Billing API in Config Controller project  ci        main    push   1960889246  1m0s     8m
✓       Initial commit                            ci        main    push   1960885850  1m8s     9m
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Org configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
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
│                                       │ Namespace              │ acm-workshop-463-gke            │                      │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext          │ acm-workshop-463-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-463-gke            │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-463-gke-sa-wi-user │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-463-gke            │ config-control       │
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
config-control   acm-workshop-463-gke     24m     True    UpToDate   21m
```

But if you have this output below, that's where you will need to take actions:
```Plaintext
NAMESPACE        NAME                     AGE     READY   STATUS        STATUS AGE
config-control   acm-workshop-463-gke     24m     True    UpdateFailed  21m
```

With a closer look at the error by running this command `kubectl descibe gcpproject -n config-control`, you will see that the error is similar too:
```Plaintext
Update call failed: error applying desired state: summary: Error setting billing account "XXX" for project "projects/acm-workshop-463-gke": googleapi: Error 403: The caller does not have permission, forbidden
```

You can resolve this issue by running by yourself this command below:
```Bash
gcloud beta billing projects link $GKE_PROJECT_ID \
    --billing-account $BILLING_ACCOUNT_ID
```

As Config Connector is still reconciling the resources, if you successfully ran this command, the error will disappear. You can run again the command `kubectl get gcpproject -n config-control` to make sure about that.

If you can't run the command above, the alternative is having someone in your organization (Billing Account or Organization admins) running it for you.