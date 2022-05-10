---
title: "Set up Projects management"
weight: 3
description: "Duration: 10 min | Persona: Org Admin"
---
_{{< param description >}}_

Define variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
PROJECTS_NAMESPACE=projects
echo "export PROJECTS_NAMESPACE=${PROJECTS_NAMESPACE}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export PROJECTS_SA_EMAIL=${PROJECTS_NAMESPACE}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Projects namespace

Create a dedicated folder for this GKE project resources:
```Bash
mkdir ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects
```

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${PROJECTS_NAMESPACE}
EOF
```

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/service-account.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${PROJECTS_NAMESPACE}
  namespace: config-control
spec:
  displayName: ${PROJECTS_NAMESPACE}
EOF
```

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: ${PROJECTS_NAMESPACE}-sa-wi-user
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${PROJECTS_NAMESPACE}
spec:
  resourceRef:
    name: ${PROJECTS_NAMESPACE}
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${CONFIG_CONTROLLER_PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager-${PROJECTS_NAMESPACE}]
EOF
```

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/config-connector-context.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnectorContext
metadata:
  name: configconnectorcontext.core.cnrm.cloud.google.com
  namespace: ${PROJECTS_NAMESPACE}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${PROJECTS_NAMESPACE}
spec:
  googleServiceAccount: ${PROJECTS_SA_EMAIL}
EOF
```

Set the `resourcemanager.projectCreator` role either at the Folder level or the Organization level:
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
Create this resource at a Folder level:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/project-creator.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: project-creator-${PROJECTS_NAMESPACE}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${PROJECTS_NAMESPACE}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${PROJECTS_NAMESPACE}
  role: roles/resourcemanager.projectCreator
  resourceRef:
    kind: Folder
    external: ${ORG_OR_FOLDER_ID}
EOF
```
{{% /tab %}}
{{% tab name="Org level" %}}
Alternatively, you could also create this resource at the Organization level:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/project-creator.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: project-creator-${PROJECTS_NAMESPACE}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${PROJECTS_NAMESPACE}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${PROJECTS_NAMESPACE}
  role: roles/resourcemanager.projectCreator
  resourceRef:
    kind: Organization
    external: ${ORG_OR_FOLDER_ID}
EOF
```
{{% /tab %}}
{{< /tabs >}}

Define the `billing.user` role:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/billing-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: billing-user-${PROJECTS_NAMESPACE}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${PROJECTS_NAMESPACE}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${PROJECTS_NAMESPACE}
  role: roles/billing.user
  resourceRef:
    kind: BillingAccount
    external: ${BILLING_ACCOUNT_ID}
EOF
```

{{% notice tip %}}
You could see that we use the annotation `config.kubernetes.io/depends-on`, [since the version 1.11 of Config Management](https://cloud.google.com/anthos-config-management/docs/release-notes#March_24_2022) we could declare [resource dependencies between resource objects](https://cloud.google.com/anthos-config-management/docs/how-to/declare-resource-dependency). KCC already handles dependencies with a retry loop with backoff, which can make things with long reconcile time even longer and generate warnings or errors on these resources. With that annotation we are optimizing these behaviors. We will use this annotation as much as we can throughout this workshop.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Set up Projects namespace and service account"
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
gcloud iam service-accounts describe $PROJECTS_SA_EMAIL \
    --project $CONFIG_CONTROLLER_PROJECT_ID
gcloud projects get-iam-policy $CONFIG_CONTROLLER_PROJECT_ID \
    --filter="bindings.members:${PROJECTS_NAMESPACE}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud beta billing accounts get-iam-policy ${BILLING_ACCOUNT_ID} \
    --filter="bindings.members:${PROJECTS_NAMESPACE}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
```Plaintext
ROLE
roles/resourcemanager.projectCreator
ROLE
roles/billing.user
```

{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
```Bash
gcloud resource-manager folders get-iam-policy $ORG_OR_FOLDER_ID \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
{{% /tab %}}
{{% tab name="Org level" %}}
```Bash
gcloud organizations get-iam-policy $ORG_OR_FOLDER_ID \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
{{% /tab %}}
{{< /tabs >}}
```Plaintext
ROLE
roles/resourcemanager.projectCreator
```

List the GitHub runs for the Org configs repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                           WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Set up Projects namespace and service account  ci        main    push   2298085291  1m10s    9m
✓       Billing API in Config Controller project       ci        main    push   2297919157  1m1s     59m
✓       Initial commit                                 ci        main    push   2297897719  1m3s     1h
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
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                    managed_resources                                             │
├────────────────────────────────────┬────────────────────────┬───────────────────────────────────────────────────┬────────────────┤
│               GROUP                │          KIND          │                        NAME                       │   NAMESPACE    │
├────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────┼────────────────┤
│                                    │ Namespace              │ projects                                          │                │
│ iam.cnrm.cloud.google.com          │ IAMPartialPolicy       │ projects-sa-wi-user                               │ config-control │
│ iam.cnrm.cloud.google.com          │ IAMServiceAccount      │ projects                                          │ config-control │
│ serviceusage.cnrm.cloud.google.com │ Service                │ cloudbilling.googleapis.com                       │ config-control │
│ core.cnrm.cloud.google.com         │ ConfigConnectorContext │ configconnectorcontext.core.cnrm.cloud.google.com │ projects       │
└────────────────────────────────────┴────────────────────────┴───────────────────────────────────────────────────┴────────────────┘
```