---
title: "Set up DNS"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME='onlineboutique.endpoints.${TENANT_PROJECT_ID}.cloud.goog'" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create FQDN

Create an FQDN with Cloud Ednpoints for Online Boutique:
```Bash
cat <<EOF > ~/dns-spec.yaml
swagger: "2.0"
info:
  description: "Online Boutique Cloud Endpoints DNS"
  title: "Online Boutique Cloud Endpoints DNS"
  version: "1.0.0"
paths: {}
host: "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
x-google-endpoints:
- name: "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
  target: "${INGRESS_GATEWAY_PUBLIC_IP}"
EOF
gcloud endpoints services deploy ~/dns-spec.yaml \
    --project ${TENANT_PROJECT_ID}
rm ~/dns-spec.yaml
```

## Define ManagedCertificate resource

Define the `ManagedCertificate` for Online Boutique in the Ingress Gateway namespace:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/managedcertificate-onlineboutique.yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: onlineboutique
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  domains:
    - "${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
EOF
```

## Update Ingress

Configure Online Boutique `ManagedCertificate` on the Ingress Gateway's `Ingress` resource:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE
kpt fn eval . \
    -i set-annotations:v0.1 \
    --match-kind Ingress \
    -- networking.gke.io/managed-certificates=whereami,onlineboutique
```
{{% notice note %}}
The annotation `networking.gke.io/managed-certificates` has 2 values, `whereami` configured previously and the new `onlineboutique` we are configuring with this page. Very important to keep both here.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Online Boutique ManagedCertificate" && git push origin main
```

## Check deployments

List the Google Cloud resources created:
```Bash
gcloud endpoints services list \
    --project $TENANT_PROJECT_ID
gcloud compute ssl-certificates list \
    --project $TENANT_PROJECT_ID
```
```Plaintext
NAME                                                      TITLE
onlineboutique.endpoints.acm-workshop-464-tenant.cloud.goog
whereami.endpoints.acm-workshop-464-tenant.cloud.goog
NAME                                       TYPE     CREATION_TIMESTAMP             EXPIRE_TIME                    MANAGED_STATUS
mcrt-3a2c928d-719c-4ec7-bec1-0d93b521f99d  MANAGED  2022-03-13T19:54:54.288-07:00  2022-06-11T18:54:56.000-07:00  ACTIVE
    onlineboutique.endpoints.acm-workshop-464-tenant.cloud.goog: ACTIVE
mcrt-cad09973-2b95-4124-866a-afa7c609e10e  MANAGED  2022-03-12T20:28:00.139-08:00  2022-06-10T20:28:01.000-07:00  ACTIVE
    whereami.endpoints.acm-workshop-464-tenant.cloud.goog: ACTIVE
```
{{% notice note %}}
Wait for the `ManagedCertificate` to be provisioned. This usually takes about 30 minutes.
{{% /notice %}}

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Online Boutique ManagedCertificate                    ci        main    push   1978403663  10s      0m
✓       GitOps for Online Boutique apps                       ci        main    push   1976985906  1m5s     5m
✓       Whereami ManagedCertificate                           ci        main    push   1975354137  1m1s     10m
✓       GitOps for Whereami app                               ci        main    push   1975326305  1m16s    20m
✓       Ingress Gateway Authorization Policies                ci        main    push   1975262483  1m9s     39m
✓       Ingress Gateway Network Policies                      ci        main    push   1975253466  1m11s    6m
✓       ASM Ingress Gateway in GKE cluster                    ci        main    push   1975240395  1m14s    10m
✓       Enforce ASM/Istio Policies in GKE cluster             ci        main    push   1972244827  59s      23h
✓       ASM configs (mTLS, Sidecar, etc.) in GKE cluster      ci        main    push   1972234050  56s      23h
✓       ASM MCP for GKE cluster                               ci        main    push   1972185200  1m8s     23h
✓       Enforce Container Registries Policies in GKE cluster  ci        main    push   1972138349  55s      23h
✓       Policies for NetworkPolicy resources                  ci        main    push   1971716019  1m14s    1d
✓       Network Policies logging                              ci        main    push   1971353547  1m1s     1d
✓       Config Sync monitoring                                ci        main    push   1971296656  1m9s     1d
✓       Initial commit                                        ci        main    push   1970951731  57s      1d
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬───────────────────────────┬─────────────────────────────────┬──────────────────────────────┐
│           GROUP           │            KIND           │               NAME              │          NAMESPACE           │
├───────────────────────────┼───────────────────────────┼─────────────────────────────────┼──────────────────────────────┤
│                           │ Namespace                 │ istio-config                    │                              │
│                           │ Namespace                 │ config-management-monitoring    │                              │
│                           │ Namespace                 │ whereami                        │                              │
│                           │ Namespace                 │ onlineboutique                  │                              │
│                           │ Namespace                 │ istio-system                    │                              │
│                           │ Namespace                 │ asm-ingress                     │                              │
│ constraints.gatekeeper.sh │ PolicyStrictOnly          │ policy-strict-only              │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ deployment-required-labels      │                              │
│ constraints.gatekeeper.sh │ SourceNotAllAuthz         │ defined-authz-source-principals │                              │
│ constraints.gatekeeper.sh │ DestinationRuleTLSEnabled │ destination-rule-tls-enabled    │                              │
│ constraints.gatekeeper.sh │ AllowedServicePortName    │ allowed-service-port-names      │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ automatic-sidecar-injection     │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos           │ allowed-container-registries    │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ namespace-required-labels       │                              │
│ networking.gke.io         │ NetworkLogging            │ default                         │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ sourcenotallauthz               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ allowedserviceportname          │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ destinationruletlsenabled       │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ policystrictonly                │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8sallowedrepos                 │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8srequiredlabels               │                              │
│                           │ ServiceAccount            │ asm-ingressgateway              │ asm-ingress                  │
│                           │ Service                   │ asm-ingressgateway              │ asm-ingress                  │
│ apps                      │ Deployment                │ asm-ingressgateway              │ asm-ingress                  │
│ cloud.google.com          │ BackendConfig             │ asm-ingressgateway              │ asm-ingress                  │
│ networking.gke.io         │ ManagedCertificate        │ onlineboutique                  │ asm-ingress                  │
│ networking.gke.io         │ FrontendConfig            │ asm-ingressgateway              │ asm-ingress                  │
│ networking.gke.io         │ ManagedCertificate        │ whereami                        │ asm-ingress                  │
│ networking.istio.io       │ Gateway                   │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ Ingress                   │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ NetworkPolicy             │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ NetworkPolicy             │ denyall                         │ asm-ingress                  │
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