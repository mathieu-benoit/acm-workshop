---
title: "Set up Online Boutique's Git repo"
weight: 1
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINEBOUTIQUE_NAMESPACE=onlineboutique" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_DIR_NAME=acm-workshop-onlineboutique-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Namespace

Define a dedicated `Namespace` for the Online Boutique apps:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    mesh.cloud.google.com/proxy: '{"managed": true}'
  labels:
    name: ${ONLINEBOUTIQUE_NAMESPACE}
    istio-injection: enabled
  name: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
```

## Create GitHub repository

```Bash
cd ${WORK_DIR}
gh repo create $ONLINE_BOUTIQUE_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-app-template-repo
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME
git pull
git checkout main
ONLINE_BOUTIQUE_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RepoSync

Define a `RepoSync` linking this Git repository:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/repo-sync.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/repo-sync-role-binding.yaml
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
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "GitOps for Online Boutique apps" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

At this stage, the `namespaces-required-networkpolicies` `Constraint` should complain because we haven't yet deployed any `NetworkPolicies` in the `onlineboutique` `Namespace`. There is different ways to see the detail of the violation. Here, we will navigate to the **Object browser** feature of GKE from within the Google Cloud Console. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/object/constraints.gatekeeper.sh/k8srequirenamespacenetworkpolicies/${GKE_LOCATION}/${GKE_NAME}/namespaces-required-networkpolicies?apiVersion=v1beta1&project=${TENANT_PROJECT_ID}"
```

At the very bottom of the object's description you should see:
```Plaintext
...
totalViolations: 1
  violations:
  - enforcementAction: dryrun
    kind: Namespace
    message: Namespace <onlineboutique> does not have a NetworkPolicy
    name: onlineboutique
```

You will deploy the `NetworkPolicies` in the `onlineboutique` `Namespace` in the following sections in order to fix this issue.

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```