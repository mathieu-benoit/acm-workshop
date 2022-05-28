---
title: "Set up Network Policies"
weight: 5
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define NetworkPolicy resources

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_denyall.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_ingress-gateway.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: ${INGRESS_GATEWAY_NAME}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Ingress Gateway Network Policies"
git push origin main
```

## Check deployments

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Ingress Gateway Network Policies                      ci        main    push   1975253466  1m11s    3m
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
│                           │ Namespace                 │ config-management-monitoring    │                              │
│                           │ Namespace                 │ istio-system                    │                              │
│                           │ Namespace                 │ asm-ingress                     │                              │
│ constraints.gatekeeper.sh │ PolicyStrictOnly          │ policy-strict-only              │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ automatic-sidecar-injection     │                              │
│ constraints.gatekeeper.sh │ SourceNotAllAuthz         │ defined-authz-source-principals │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ deployment-required-labels      │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos           │ allowed-container-registries    │                              │
│ constraints.gatekeeper.sh │ AllowedServicePortName    │ allowed-service-port-names      │                              │
│ constraints.gatekeeper.sh │ DestinationRuleTLSEnabled │ destination-rule-tls-enabled    │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ namespace-required-labels       │                              │
│ networking.gke.io         │ NetworkLogging            │ default                         │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ sourcenotallauthz               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8srequiredlabels               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ destinationruletlsenabled       │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ allowedserviceportname          │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8sallowedrepos                 │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ policystrictonly                │                              │
│                           │ ServiceAccount            │ asm-ingressgateway              │ asm-ingress                  │
│                           │ Service                   │ asm-ingressgateway              │ asm-ingress                  │
│ apps                      │ Deployment                │ asm-ingressgateway              │ asm-ingress                  │
│ cloud.google.com          │ BackendConfig             │ asm-ingressgateway              │ asm-ingress                  │
│ networking.gke.io         │ FrontendConfig            │ asm-ingressgateway              │ asm-ingress                  │
│ networking.istio.io       │ Gateway                   │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ Ingress                   │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ NetworkPolicy             │ asm-ingressgateway              │ asm-ingress                  │
│ networking.k8s.io         │ NetworkPolicy             │ denyall                         │ asm-ingress                  │
│ rbac.authorization.k8s.io │ Role                      │ asm-ingressgateway              │ asm-ingress                  │
│ rbac.authorization.k8s.io │ RoleBinding               │ asm-ingressgateway              │ asm-ingress                  │
│                           │ ServiceAccount            │ default                         │ config-management-monitoring │
│                           │ ConfigMap                 │ istio-asm-managed-rapid         │ istio-system                 │
│ mesh.cloud.google.com     │ ControlPlaneRevision      │ asm-managed-rapid               │ istio-system                 │
│ security.istio.io         │ PeerAuthentication        │ default                         │ istio-system                 │
└───────────────────────────┴───────────────────────────┴─────────────────────────────────┴──────────────────────────────┘
```