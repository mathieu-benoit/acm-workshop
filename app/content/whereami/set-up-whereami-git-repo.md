---
title: "Set up Whereami's Git repo"
weight: 2
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "gitops-tips", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up a dedicated GitHub repository which will contain all the Kubernetes manifests of the Whereami app. You will also have the opportunity to catch a policies violation.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export WHEREAMI_NAMESPACE=whereami" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export WHERE_AMI_DIR_NAME=acm-workshop-whereami-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir -p ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$WHEREAMI_NAMESPACE
```

## Create Namespace

Define a dedicated `Namespace` for the Whereami app:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$WHEREAMI_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    name: ${WHEREAMI_NAMESPACE}
    istio-injection: enabled
  name: ${WHEREAMI_NAMESPACE}
EOF
```

## Create GitHub repository

```Bash
cd ${WORK_DIR}
gh repo create $WHERE_AMI_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-app-template-repo
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME
git pull
git checkout main
WHERE_AMI_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RepoSync

Define a `RepoSync` linking this Git repository:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$WHEREAMI_NAMESPACE/repo-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RepoSync
metadata:
  name: repo-sync
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  sourceFormat: unstructured
  git:
    repo: ${WHERE_AMI_REPO_URL}
    revision: HEAD
    branch: main
    dir: staging
    auth: none
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$WHEREAMI_NAMESPACE/repo-sync-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: repo-sync
  namespace: ${WHEREAMI_NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ns-reconciler-${WHEREAMI_NAMESPACE}
  namespace: config-management-system
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF
```
{{% notice tip %}}
We are using the [`edit` user-facing role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) here, to follow the least privilege principle. Earlier in this workshop during the ASM installation, we extended the default `edit` role with more capabilities regarding to the Istio resources: `VirtualServices`, `Sidecars` and `AuthorizationPolicies` which will be leveraged in the Whereami's namespace.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "GitOps for Whereami app" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="gcloud" %}}
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{% tab name="UI" %}}
Alternatively, you could also see this from within the Cloud Console, by clicking on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/status?clusterName=${GKE_NAME}&id=${GKE_NAME}&project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `SYNCED`. And then you can also click on `View resources` to see the details.
{{% /tab %}}
{{< /tabs >}}

At this stage, the `namespaces-required-networkpolicies` `Constraint` should silently (`dryrun`) complain because we haven't yet deployed any `NetworkPolicies` in the `whereami` `Namespace`. There is different ways to see the detail of the violation. Here, we will navigate to the **Object browser** feature of GKE from within the Google Cloud Console. Click on the link displayed by the command below:
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
    message: Namespace <whereami> does not have a NetworkPolicy
    name: whereami
```