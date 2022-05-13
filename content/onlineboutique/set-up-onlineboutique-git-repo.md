---
title: "Set up Online Boutique's Git repo"
weight: 1
description: "Duration: 10 min | Persona: Platform Admin"
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
WORK_DIR=~/
touch ${WORK_DIR}acm-workshop-variables.sh
chmod +x ${WORK_DIR}acm-workshop-variables.sh
GKE_PROJECT_ID=acm-workshop-464-gke
echo "export GKE_PROJECT_ID=${GKE_PROJECT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_CONFIGS_DIR_NAME=acm-workshop-gke-configs-repo" >> ${WORK_DIR}acm-workshop-variables.sh
ONLINEBOUTIQUE_NAMESPACE=ob-team1
echo "export ONLINEBOUTIQUE_NAMESPACE=${ONLINEBOUTIQUE_NAMESPACE}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_DIR_NAME=acm-workshop-${ONLINEBOUTIQUE_NAMESPACE}-repo" >> ${WORK_DIR}acm-workshop-variables.sh
echo "gcloud config set accessibility/screen_reader false" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
cd ~
git clone https://github.com/mathieu-benoit/$GKE_CONFIGS_DIR_NAME
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Namespace

Define a dedicated `Namespace` for the Online Boutique apps:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${ONLINEBOUTIQUE_NAMESPACE}
  labels:
    name: ${ONLINEBOUTIQUE_NAMESPACE}
    istio-injection: enabled
EOF
```

## Create GitHub repository

```Bash
cd ~
gh repo create $ONLINE_BOUTIQUE_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-app-template-repo
cd ~/$ONLINE_BOUTIQUE_DIR_NAME
git pull
git checkout main
ONLINE_BOUTIQUE_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RepoSync

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
    dir: staging
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
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF
```
{{% notice tip %}}
We are using the [`edit` user-facing role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) here, to follow the least privilege principle. Earlier in this workshop during the ASM installation, we extended the default `edit` role with more capabilities regarding to the Istio resources: `VirtualService`, `Sidecar` and `Authorization` which will be leveraged in the OnlineBoutique's namespace.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "GitOps for ${ONLINEBOUTIQUE_NAMESPACE}"
git push origin main
```

## Check deployments

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE`:
```Plaintext
completed       GitOps for Online Boutique apps                       ci        main    push   1976985906  1m5s     1m
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system \
    | grep $ONLINEBOUTIQUE_NAMESPACE
```
```Plaintext
getting 1 RepoSync and RootSync from projects/acm-workshop-464-gke/locations/global/memberships/gke-hub-membership
│                           │ Namespace                 │ ob-team1                            │                              │ Current │
│ configsync.gke.io         │ RepoSync                  │ repo-sync                           │ ob-team1                     │ Current │
│ rbac.authorization.k8s.io │ RoleBinding               │ repo-sync                           │ ob-team1                     │ Current │
```