---
title: "Set up ASM configs"
weight: 3
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define ASM configs Mesh-wide

Define the optional Mesh configs (`distroless` container image for the proxy):
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/istio-system/mesh-configs.yaml
apiVersion: v1
data:
  mesh: |-
    defaultConfig:
      image:
        imageType: distroless
kind: ConfigMap
metadata:
  name: istio-${ASM_VERSION}
  namespace: istio-system
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "ASM configs in GKE cluster"
git push
```

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

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "mTLS STRICT in GKE cluster"
git push
```

## Check deployments

Here is what you should have at this stage:

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       mTLS STRICT in GKE cluster                            ci        main    push   1972234050  56s      2m
✓       ASM configs in GKE cluster                            ci        main    push   1972232995  1m3s     2m
✓       ASM MCP for GKE cluster                               ci        main    push   1972222841  56s      7m
✓       Enforce Container Registries Policies in GKE cluster  ci        main    push   1972138349  55s      49m
✓       Policies for NetworkPolicy resources                  ci        main    push   1971716019  1m14s    3h
✓       Network Policies logging                              ci        main    push   1971353547  1m1s     5h
✓       Config Sync monitoring                                ci        main    push   1971296656  1m9s     5h
✓       Initial commit                                        ci        main    push   1970951731  57s      7h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster**:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬──────────────────────┬──────────────────────────────┬──────────────────────────────┐
│           GROUP           │         KIND         │             NAME             │          NAMESPACE           │
├───────────────────────────┼──────────────────────┼──────────────────────────────┼──────────────────────────────┤
│                           │ Namespace            │ istio-system                 │                              │
│                           │ Namespace            │ config-management-monitoring │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels    │ deployment-required-labels   │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels    │ namespace-required-labels    │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos      │ allowed-container-registries │                              │
│ networking.gke.io         │ NetworkLogging       │ default                      │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate   │ k8sallowedrepos              │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate   │ k8srequiredlabels            │                              │
│                           │ ServiceAccount       │ default                      │ config-management-monitoring │
│                           │ ConfigMap            │ istio-asm-managed-rapid      │ istio-system                 │
│ mesh.cloud.google.com     │ ControlPlaneRevision │ asm-managed-rapid            │ istio-system                 │
│ security.istio.io         │ PeerAuthentication   │ default                      │ istio-system                 │
└───────────────────────────┴──────────────────────┴──────────────────────────────┴──────────────────────────────┘
```