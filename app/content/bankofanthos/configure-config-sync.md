---
title: "Configure Config Sync"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "gitops-tips", "platform-admin", "security-tips"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will set up a dedicated GitHub repository which will contain all the Kubernetes manifests of the Bank of Anthos apps. You will also have the opportunity to catch a policies violation.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export BANKOFANTHOS_NAMESPACE=bankofanthos" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export BANK_OF_ANTHOS_DIR_NAME=acm-workshop-bankofanthos-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir -p ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$BANKOFANTHOS_NAMESPACE
```

## Define Namespace

Define a dedicated `Namespace` for the Bank of Anthos apps:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$BANKOFANTHOS_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    istio-injection: enabled
    pod-security.kubernetes.io/enforce: baseline
  name: ${BANKOFANTHOS_NAMESPACE}
EOF
```
{{% notice note %}}
In addition to the `istio-injection` to include this `Namespace` into our Service Mesh, we are also adding the `pod-security.kubernetes.io/enforce` label as the `baseline` [Pod Security Standards policy](https://kubernetes.io/docs/concepts/security/pod-security-standards/).
{{% /notice %}}

## Create GitHub repository

```Bash
cd ${WORK_DIR}
gh repo create $BANK_OF_ANTHOS_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-app-template-repo
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME
git pull
git checkout main
BANK_OF_ANTHOS_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RepoSync

Define a `RepoSync` linking this Git repository:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$BANKOFANTHOS_NAMESPACE/repo-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RepoSync
metadata:
  name: repo-sync
  namespace: ${BANKOFANTHOS_NAMESPACE}
spec:
  sourceFormat: unstructured
  git:
    repo: ${BANK_OF_ANTHOS_REPO_URL}
    revision: HEAD
    branch: main
    dir: staging
    auth: none
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$BANKOFANTHOS_NAMESPACE/repo-sync-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: repo-sync
  namespace: ${BANKOFANTHOS_NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ns-reconciler-${BANKOFANTHOS_NAMESPACE}
  namespace: config-management-system
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF
```
{{% notice tip %}}
We are using the [`edit` user-facing role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) here, to follow the least privilege principle. Earlier in this workshop during the ASM installation, we extended the default `edit` role with more capabilities regarding to the Istio resources: `VirtualServices`, `Sidecars` and `AuthorizationPolicies` which will be leveraged in the Bank of Anthos's namespace.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Configure Config Sync for Bank of Anthos" && git push origin main
```

## Check Policies violation

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```