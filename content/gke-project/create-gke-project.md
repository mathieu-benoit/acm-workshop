---
title: "Create GKE project"
weight: 1
description: "Duration: 10 min | Persona: Org Admin"
---
_{{< param description >}}_

Define variables:
```Bash
echo "export GKE_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}-gke" >> ~/acm-workshop-variables.sh
echo "export GKE_PROJECT_SA_EMAIL=${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

Create a dedicated folder for this GKE project resources:
```Bash
mkdir ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects
mkdir ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID
```

## Define GCP project

Define the GCP project:
{{< tabs groupId="org-level">}}
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
    external: "${FOLDER_ID}"
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
spec:
  resourceRef:
    name: ${GKE_PROJECT_ID}
    apiVersion: iam.cnrm.cloud.google.com/v1beta1
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${CONFIG_CONTROLLER_PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager-${GKE_PROJECT_ID}]
EOF
```

## Define GKE project namespace and ConfigConnectorContext

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
  labels:
    owner: ${GKE_PROJECT_ID}
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
spec:
  googleServiceAccount: ${GKE_PROJECT_SA_EMAIL}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Setting up GKE namespace/project"
git push
```

## Check deployments

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

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
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