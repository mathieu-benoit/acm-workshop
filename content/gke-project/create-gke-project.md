---
title: "Create GKE project"
weight: 1
description: "Duration: 10 min | Persona: Org Admin"
---
Define variables:
```Bash
echo "export GKE_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}-gke" >> ~/acm-workshop-variables.sh
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
  name: configconnectorcontext
  namespace: ${GKE_PROJECT_ID}
spec:
  googleServiceAccount: ${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
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

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
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
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```