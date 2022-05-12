---
title: "Set up ASM configs"
weight: 3
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define ASM configs Mesh-wide

Define the optional Mesh configs:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/mesh-configs.yaml
apiVersion: v1
data:
  mesh: |-
    defaultConfig:
      image:
        imageType: distroless
    discoverySelectors:
    - matchLabels:
        istio-injection: enabled
kind: ConfigMap
metadata:
  name: istio-${ASM_VERSION}
  namespace: istio-system
EOF
```
{{% notice tip %}}
The [`distroless` base image ensures that the proxy image](https://cloud.google.com/service-mesh/docs/managed/enable-managed-anthos-service-mesh-optional-features#distroless_proxy_image) contains the minimal number of packages required to run the proxy. This improves security posture by reducing the overall attack surface of the image and gets cleaner results with CVE scanners.
{{% /notice %}}
{{% notice tip %}}
[`discoverySelectors`](https://istio.io/latest/blog/2021/discovery-selectors/) is a way to dynamically restrict the set of namespaces that are part of the mesh so that the Istio control plane only processes resources in those namespaces.
{{% /notice %}}

## Define mTLS STRICT Mesh-wide

Define the mTLS `STRICT` policy Mesh-wide:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/mesh-mtls.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF
```
{{% notice tip %}}
Here we are locking down [mutual TLS to `STRICT` for the entire mesh](https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/#lock-down-mutual-tls-for-the-entire-mesh).
{{% /notice %}}

## Define Sidecar Mesh-wide

Create a dedicated `istio-config` folder in the GKE configs's Git repo:
```Bash
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-config
```

Define the `istio-config` namespace:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-config/sidecar.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
  namespace: istio-config
spec:
  egress:
  - hosts:
    - ./*
    - istio-system/*
EOF
```
{{% notice tip %}}
A [`Sidecar`](https://istio.io/latest/docs/reference/config/networking/sidecar/) configuration in the `MeshConfig` root namespace will be applied by default to all namespaces.
{{% /notice %}}

## Define default deny AuthorizationPolicy Mesh-wide

Define `deny` `AuthorizationPolicy` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-config/authorizationpolicy_denyall.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: istio-system
spec: {}
EOF
```

## Define new ClusterRole with Istio capabilities for ConfigSync

Define the extended [`edit` user-facing role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) with more Istio resources capabilities:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/custom-edit-clusterrole-istio.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
  name: custom:aggregate-to-edit:istio
rules:
- apiGroups:
  - "networking.istio.io"
  - "security.istio.io"
  resources:
  - "virtualservices"
  - "authorizationpolicies"
  - "sidecars"
  verbs:
  - "*"
EOF
```
{{% notice tip %}}
Later in this workshop, for each app namespace, we will define a Config Sync's `RepoSync` which will be bound to the `edit` `ClusterRole`. With that new extension, it will allow each namespace to deploy Istio resources such as `Sidecar`, `VirtualService` and `AuthorizationPolicy` while meeting with the least privilege principle requirement.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "ASM Mesh configs in GKE cluster"
git push origin main
```

## Check deployments

Here is what you should have at this stage:

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       ASM Mesh configs in GKE cluster                       ci        main    push   1972234050  56s      2m
✓       ASM MCP for GKE cluster                               ci        main    push   1972222841  56s      7m
✓       Enforce Container Registries Policies in GKE cluster  ci        main    push   1972138349  55s      49m
✓       Policies for NetworkPolicy resources                  ci        main    push   1971716019  1m14s    3h
✓       Network Policies logging                              ci        main    push   1971353547  1m1s     5h
✓       Config Sync monitoring                                ci        main    push   1971296656  1m9s     5h
✓       Initial commit                                        ci        main    push   1970951731  57s      7h
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
┌───────────────────────────┬──────────────────────┬────────────────────────────────┬──────────────────────────────┐
│           GROUP           │         KIND         │             NAME               │          NAMESPACE           │
├───────────────────────────┼──────────────────────┼────────────────────────────────┼──────────────────────────────┤
│                           │ Namespace            │ istio-system                   │                              │
│                           │ Namespace            │ config-management-monitoring   │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels    │ deployment-required-labels     │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels    │ namespace-required-labels      │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos      │ allowed-container-registries   │                              │
│ networking.gke.io         │ NetworkLogging       │ default                        │                              │
| rbac.authorization.k8s.io │ ClusterRole          │ custom:aggregate-to-edit:istio │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate   │ k8sallowedrepos                │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate   │ k8srequiredlabels              │                              │
│                           │ ServiceAccount       │ default                        │ config-management-monitoring │
│ security.istio.io         │ AuthorizationPolicy  │ deny-all                       │ istio-system                 │
│                           │ ConfigMap            │ istio-asm-managed-rapid        │ istio-system                 │
│ mesh.cloud.google.com     │ ControlPlaneRevision │ asm-managed-rapid              │ istio-system                 │
│ security.istio.io         │ PeerAuthentication   │ default                        │ istio-system                 │
└───────────────────────────┴──────────────────────┴────────────────────────────────┴──────────────────────────────┘
```