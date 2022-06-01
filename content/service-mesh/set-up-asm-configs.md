---
title: "Set up ASM configs"
weight: 3
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["asm", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define ASM configs Mesh-wide

Define the optional Mesh configs:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system/mesh-configs.yaml
apiVersion: v1
data:
  mesh: |-
    defaultConfig:
      image:
        imageType: distroless
      tracing:
        stackdriver: {}
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system/mesh-mtls.yaml
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
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-config
```

Define the `istio-config` namespace:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-config/sidecar.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-config/authorizationpolicy_denyall.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/custom-edit-clusterrole-istio.yaml
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
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "ASM Mesh configs in GKE cluster" && git push origin main
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