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

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list -L 1`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GitOps for Online Boutique apps                       ci        main    push   1976985906  1m5s     1m
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬───────────────────────────┬─────────────────────────────────┬──────────────────────────────┐
│           GROUP           │            KIND           │               NAME              │          NAMESPACE           │
├───────────────────────────┼───────────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│                           │ Namespace                 │ asm-ingress                     │                              │
│                           │ Namespace                 │ istio-config                    │                              │
│                           │ Namespace                 │ onlineboutique                  │                              │
│                           │ Namespace                 │ config-management-monitoring    │                              │
│                           │ Namespace                 │ whereami                        │                              │
│                           │ Namespace                 │ istio-system                    │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ automatic-sidecar-injection     │                              │
│ constraints.gatekeeper.sh │ AllowedServicePortName    │ allowed-service-port-names      │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos           │ allowed-container-registries    │                              │
│ constraints.gatekeeper.sh │ PolicyStrictOnly          │ policy-strict-only              │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ deployment-required-labels      │                              │
│ constraints.gatekeeper.sh │ SourceNotAllAuthz         │ defined-authz-source-principals │                              │
│ constraints.gatekeeper.sh │ DestinationRuleTLSEnabled │ destination-rule-tls-enabled    │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ namespace-required-labels       │                              │
│ networking.gke.io         │ NetworkLogging            │ default                         │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ policystrictonly                │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ sourcenotallauthz               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8srequiredlabels               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ allowedserviceportname          │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8sallowedrepos                 │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ destinationruletlsenabled       │                              │
│                           │ Service                   │ asm-ingressgateway              │ asm-ingress                  │
│                           │ ServiceAccount            │ asm-ingressgateway              │ asm-ingress                  │
│ apps                      │ Deployment                │ asm-ingressgateway              │ asm-ingress                  │
│ cloud.google.com          │ BackendConfig             │ asm-ingressgateway              │ asm-ingress                  │
│ networking.gke.io         │ ManagedCertificate        │ whereami                        │ asm-ingress                  │
│ networking.gke.io         │ FrontendConfig            │ asm-ingressgateway              │ asm-ingress                  │
│ networking.istio.io       │ Gateway                   │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ NetworkPolicy             │ denyall                         │ asm-ingress                  │
│ networking.k8s.io         │ NetworkPolicy             │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ Ingress                   │ asm-ingressgateway              │ asm-ingress                  │
│ rbac.authorization.k8s.io │ Role                      │ asm-ingressgateway              │ asm-ingress                  │
│ rbac.authorization.k8s.io │ RoleBinding               │ asm-ingressgateway              │ asm-ingress                  │
│ security.istio.io         │ AuthorizationPolicy       │ asm-ingressgateway              │ asm-ingress                  │
│ security.istio.io         │ AuthorizationPolicy       │ deny-all                        │ asm-ingress                  │
│                           │ ServiceAccount            │ default                         │ config-management-monitoring │
│ networking.istio.io       │ Sidecar                   │ default                         │ istio-config                 │
│                           │ ConfigMap                 │ istio-asm-managed-rapid         │ istio-system                 │
│ mesh.cloud.google.com     │ ControlPlaneRevision      │ asm-managed-rapid               │ istio-system                 │
│ security.istio.io         │ PeerAuthentication        │ default                         │ istio-system                 │
│ configsync.gke.io         │ RepoSync                  │ repo-sync                       │ onlineboutique               │
│ rbac.authorization.k8s.io │ RoleBinding               │ repo-sync                       │ onlineboutique               │
│ configsync.gke.io         │ RepoSync                  │ repo-sync                       │ whereami                     │
│ rbac.authorization.k8s.io │ RoleBinding               │ repo-sync                       │ whereami                     │
└───────────────────────────┴───────────────────────────┴─────────────────────────────────┴──────────────────────────────┘
```