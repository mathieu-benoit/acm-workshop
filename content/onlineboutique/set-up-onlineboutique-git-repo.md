---
title: "Set up Online Boutique's Git repo"
weight: 1
---
- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
echo "export ONLINEBOUTIQUE_NAMESPACE=onlineboutique" >> ~/acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_DIR_NAME=acm-workshop-onlineboutique-repo" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

```Bash
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/repo-syncs
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE
```

Define a dedicated `Namespace` for the Online Boutique apps:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${ONLINEBOUTIQUE_NAMESPACE}
  #annotations:
  #  mesh.cloud.google.com/proxy: '{"managed": true}'
  labels:
    name: ${ONLINEBOUTIQUE_NAMESPACE}
    istio.io/rev: ${ASM_VERSION}
EOF
```

```Bash
cd ~
gh repo create $ONLINE_BOUTIQUE_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd $ONLINE_BOUTIQUE_DIR_NAME
ONLINE_BOUTIQUE_REPO_URL=$(gh repo view --json url --jq .url)
```

Define a `RepoSync` linking this Git repository:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/repo-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RepoSync
metadata:
  name: repo-sync
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  sourceFormat: unstructured
  git:
    repo: ${ONLINE_BOUTIQUE_REPO_URL}
    revision: HEAD
    branch: main
    dir: config-sync
    auth: none
EOF
```

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/repo-sync-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: repo-sync
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ns-reconciler-${ONLINEBOUTIQUE_NAMESPACE}
  namespace: config-management-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```
{{% notice info %}}
We are using the `cluster-admin` role here, but in the future we will change this with a least privilege approach. It will be something with `edit` role and the the Istio resources like `VirtualService`, etc. leveraged in this workshop. See [more information about the user-facing roles here](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles).
{{% /notice %}}

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "GitOps for Online Boutique apps"
git push
```