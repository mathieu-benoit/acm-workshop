---
title: "Set up GKE project's Git repo"
weight: 2
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin"]
---
_{{< param description >}}_

Define variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_PROJECT_DIR_NAME=acm-workshop-gke-project-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create GitHub repository

Create a dedicated GitHub repository to store any Kubernetes manifests associated to the GKE project:
```Bash
cd ~
gh repo create $GKE_PROJECT_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ~/$GKE_PROJECT_DIR_NAME
git pull
git checkout main
GKE_PLATFORM_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RepoSync

Define a `RepoSync` linking this Git repository:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/gke-config-repo-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RepoSync
metadata:
  name: repo-sync
  namespace: ${GKE_PROJECT_ID}
spec:
  sourceFormat: unstructured
  git:
   repo: ${GKE_PLATFORM_REPO_URL}
   revision: HEAD
   branch: main
   dir: "config-sync"
   auth: none
EOF
```

```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/gke-config-repo-sync-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: syncs-repo
  namespace: ${GKE_PROJECT_ID}
subjects:
- kind: ServiceAccount
  name: ns-reconciler-${GKE_PROJECT_ID}
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
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "GitOps for GKE project"
git push origin main
```

## Check deployments

List the GitHub runs for the **Org configs** repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GitOps for GKE project                    ci        main    push   1960959789  1m5s     1m
✓       Setting up GKE namespace/project          ci        main    push   1960908849  1m12s    16m
✓       Billing API in Config Controller project  ci        main    push   1960889246  1m0s     22m
✓       Initial commit                            ci        main    push   1960885850  1m8s     24m
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
┌───────────────────────────────────────┬────────────────────────┬────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                NAME                │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ acm-workshop-464-gke               │                      │
│                                       │ Namespace              │ config-control                     │                      │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                          │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext             │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-gke               │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-gke-sa-wi-user    │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-gke               │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com        │ config-control       │
└───────────────────────────────────────┴────────────────────────┴────────────────────────────────────┴──────────────────────┘
```