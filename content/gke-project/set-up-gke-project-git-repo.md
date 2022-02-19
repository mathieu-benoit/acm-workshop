---
title: "Set up GKE project's Git repo"
weight: 2
---

- Persona: Org Admin
- Duration: 10 min
- Objectives:
  - FIXME

```Bash
GKE_PLATFORM_DIR_NAME=workshop-gke-platform-repo
cd ~
gh repo create $GKE_PLATFORM_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd $GKE_PLATFORM_DIR_NAME
git pull
git checkout main
GKE_PLATFORM_REPO_URL=$(gh repo view --json url --jq .url)
```

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

{{< tabs >}}
{{% tab name="git commit" %}}
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Setting up gitops for ${GKE_PROJECT_ID}'s platform config."
git push
```
{{% /tab %}}
{{% tab name="kubectl apply" %}}
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
kubectl apply -f .
```
{{% /tab %}}
{{< /tabs >}}