---
title: "Set up GKE project's Git repo"
weight: 2
---
- Persona: Org Admin
- Duration: 10 min

Define variables:
```Bash
echo "export GKE_PROJECT_DIR_NAME=acm-workshop-gke-project-repo" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Create GitHub repository

Create a dedicated GitHub repository to store any Kubernetes manifests associated to the GKE project:
```Bash
gh repo create $GKE_PROJECT_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ~/$GKE_PROJECT_DIR_NAME
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
git push
```