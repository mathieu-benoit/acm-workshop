---
title: "Set up Whereami's Git repo"
weight: 2
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "platform-admin", "shift-left"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will set up a dedicated GitHub repository which will contain all the Kubernetes manifests of the Whereami app. You will also have the opportunity to catch and fix a policies violation.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export WHEREAMI_NAMESPACE=whereami" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export WHERE_AMI_DIR_NAME=acm-workshop-whereami-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$WHEREAMI_NAMESPACE
```

## Create Namespace

Define a dedicated `Namespace` for the Whereami app:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$WHEREAMI_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    mesh.cloud.google.com/proxy: '{"managed": true}'
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
We are using the [`edit` user-facing role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) here, to follow the least privilege principle. Earlier in this workshop during the ASM installation, we extended the default `edit` role with more capabilities regarding to the Istio resources: `VirtualService`, `Sidecar` and `Authorization` which will be leveraged in the Whereami's namespace.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "GitOps for Whereami app" && git push origin main
```

## Check Policies violation

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

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
build   gatekeeper      2022-06-06T00:53:51.7286839Z     [info] v1/Namespace/whereami: Namespace <whereami> does not have a NetworkPolicy violatedConstraint: namespaces-required-networkpolicies
```
{{% notice tip %}}
In the context of this workshop, we are doing direct commits in the `main` branch but it's highly encouraged that you follow the Git flow process by creating branches and opening pull requests. With this process in place and this GitHub actions definition, your pull requests will be blocked if there is any `Constraint` violations and won't be merged into `main` branch. This will avoid any issues when actually deploying the Kubernetes manifests in the Kubernetes cluster.
{{% /notice %}}

## Deploy default NetworkPolicy

Let's deploy a default `deny-all` `NetworkPolicy` in the `whereami` `Namespace` in order to fix this `Constraint` violation.

Define a default `deny-all` `NetworkPolicy`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$WHEREAMI_NAMESPACE/network-policy-deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

Deploy this Kubernetes manifest:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Default deny-all NetworkPolicy for Whereami" && git push origin main
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
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RootSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Whereami apps** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

You will deploy the `NetworkPolicies` in the `whereami` `Namespace` in the following sections in order to fix this issue.

List the GitHub runs for the **Whereami app** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```

If you check again with the previous **Check Policies violation**, you won't see any `Constraint` violations now.