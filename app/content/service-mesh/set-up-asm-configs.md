---
title: "Set up ASM configs"
weight: 3
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["asm", "gitops-tips", "platform-admin", "security-tips"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will set up some configurations in order to get more insights with Cloud Trace and use the `distroless` image for your sidecar proxies.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
ASM_VERSION=asm-managed-rapid
echo "export ASM_VERSION=${ASM_VERSION}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice info %}}
`ASM_VERSION` is set to `asm-managed-rapid` because the Managed ASM is following the GKE's channel: `rapid`.
{{% /notice %}}

Create a dedicated `istio-system` folder in the GKE configs's Git repo:
```Bash
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system
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

Define the default `Sidecar` in the `istio-system` `Namespace`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system/sidecar.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
  namespace: istio-system
spec:
  egress:
  - hosts:
    - ./*
    - istio-system/*
EOF
```
{{% notice tip %}}
A [`Sidecar`](https://istio.io/latest/docs/reference/config/networking/sidecar/) configuration in the `istio-system` `Namespace` will be applied by default to all `Namespaces`.
{{% /notice %}}

## Define default deny-all AuthorizationPolicy Mesh-wide

Define the default `deny-all` `AuthorizationPolicy` in the `istio-system` `Namespace`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/istio-system/authorizationpolicy_denyall.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: istio-system
spec: {}
EOF
```

## Define new ClusterRole with Istio capabilities for Config Sync

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
  - "serviceentries"
  - "destinationrules"
  verbs:
  - "*"
EOF
```
{{% notice tip %}}
Later in this workshop, for each app namespace, we will define a Config Sync's `RepoSync` which will be bound to the `edit` `ClusterRole`. With that new extension, it will allow each namespace to deploy Istio resources such as `Sidecar`, `VirtualService`, `AuthorizationPolicy`, `ServiceEntry` and `DestinationRule` while meeting with the least privilege principle requirement.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "ASM Mesh configs in GKE cluster" && git push origin main
```

## Check deployments

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