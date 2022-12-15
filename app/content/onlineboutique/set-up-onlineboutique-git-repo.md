---
title: "Set up Online Boutique's Git repo"
weight: 2
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "gitops-tips", "platform-admin", "shift-left"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up a dedicated GitHub repository which will contain all the Kubernetes manifests of the Online Boutique apps. You will also have the opportunity to catch a policies violation.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINEBOUTIQUE_NAMESPACE=onlineboutique" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_DIR_NAME=acm-workshop-onlineboutique-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir -p ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Namespace

Define a dedicated `Namespace` for the Online Boutique apps:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
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
We are using the [`edit` user-facing role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) here, to follow the least privilege principle. Earlier in this workshop during the ASM installation, we extended the default `edit` role with more capabilities regarding to the Istio resources: `VirtualServices`, `Sidecars` and `AuthorizationPolicies` which will be leveraged in the OnlineBoutique's namespace.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "GitOps for Online Boutique apps" && git push origin main
```

## Check Policies violation

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

At this stage, the `namespaces-required-networkpolicies` `Constraint` should silently (`dryrun`) complain because we haven't yet deployed any `NetworkPolicies` in the `onlineboutique` `Namespace`. There is different ways to see the detail of the violation. Here, we will navigate to the **Object browser** feature of GKE from within the Google Cloud Console. Click on the link displayed by the command below:
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

## Shift-left Policies evaluation

Another way to see the `Constraints` violations is to evaluate as early as possible the `Constraints` against the Kubernetes manifests before they are actually applied in the Kubernetes cluster. When you created the GitHub repository for the Online Boutique apps, you used a predefined template containing a GitHub actions workflow running Continuous Integration checks for every commit. See the content of this file by running this command:
```Bash
cat ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/.github/workflows/ci.yml
```
{{% notice info %}}
We are leveraging the [Kpt's `gatekeeper` function](https://catalog.kpt.dev/gatekeeper/v0.2/) in order to accomplish this. Another way to do that could be to leverage the [`gator test`](https://open-policy-agent.github.io/gatekeeper/website/docs/gator/#the-gator-test-subcommand) command too.
{{% /notice %}}

See the details of the last GitHub actions run:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME
gh run view $(gh run list -L 1 --json databaseId --jq .[].databaseId) --log | grep violatedConstraint
```
The output contains the details of the error:
```Plaintext
build   gatekeeper      2022-06-06T00:53:51.7286839Z     [info] v1/Namespace/onlineboutique: Namespace <onlineboutique> does not have a NetworkPolicy violatedConstraint: namespaces-required-networkpolicies
```
{{% notice tip %}}
In the context of this workshop, we are doing direct commits in the `main` branch but it's highly encouraged that you follow the Git flow process by creating branches and opening pull requests. With this process in place and this GitHub actions definition, your pull requests will be blocked if there is any `Constraint` violations and won't be merged into `main` branch. This will avoid any issues when actually deploying the Kubernetes manifests in the Kubernetes cluster.
{{% /notice %}}