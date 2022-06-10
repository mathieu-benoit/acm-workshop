---
title: "Set up Tenant project's Git repo"
weight: 2
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin", "security-tips"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will set up a dedicated GitHub repository containing all the Kubernetes manifests which will be deployed by Config Sync and Config Connector in order to provision the Google Cloud services.

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export TENANT_PROJECT_DIR_NAME=acm-workshop-tenant-project-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create GitHub repository

Create a dedicated GitHub repository to store any Kubernetes manifests associated to the Tenant project:
```Bash
cd ${WORK_DIR}
gh repo create $TENANT_PROJECT_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME
git pull
git checkout main
GKE_PLATFORM_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RepoSync

Define a `RepoSync` linking this Git repository:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/gke-config-repo-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RepoSync
metadata:
  name: repo-sync
  namespace: ${TENANT_PROJECT_ID}
spec:
  sourceFormat: unstructured
  git:
   repo: ${GKE_PLATFORM_REPO_URL}
   revision: HEAD
   branch: main
   dir: "."
   auth: none
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/projects/$TENANT_PROJECT_ID/gke-config-repo-sync-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: syncs-repo
  namespace: ${TENANT_PROJECT_ID}
subjects:
- kind: ServiceAccount
  name: ns-reconciler-${TENANT_PROJECT_ID}
  namespace: config-management-system
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF
```
{{% notice info %}}
We are using the `edit` role here, see [more information about the user-facing roles here](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles).
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "GitOps for Tenant project" && git push origin main
```

## Check deployments

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