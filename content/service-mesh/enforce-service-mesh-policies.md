---
title: "Enforce Service Mesh policies"
weight: 4
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "platform-admin", "policies", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAMESPACE=asm-ingress" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define "Automatic sidecar proxy injection" policies

https://cloud.google.com/service-mesh/docs/anthos-service-mesh-proxy-injection

Define the `namespaces-automatic-sidecar-injection-label` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/namespaces-automatic-sidecar-injection-label.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: namespaces-automatic-sidecar-injection-label
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Namespace
    excludedNamespaces:
    - config-management-monitoring
    - config-management-system
    - default
    - gatekeeper-system
    - istio-system
    - istio-config
    - kube-node-lease
    - kube-public
    - kube-system
    - resource-group-system
  parameters:
    labels:
    - key: istio-injection
EOF
```

Define the `pods-sidecar-injection-annotation` `Constraint` based on the [`AsmSidecarInjection`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmsidecarinjection) `ConstraintTemplate` for `Pods`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/pods-sidecar-injection-annotation.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmSidecarInjection
metadata:
  name: pods-sidecar-injection-annotation
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
    excludedNamespaces:
    - kube-system # to exclude istio-cni pods
  parameters:
    strictnessLevel: High
EOF
```

## Define "STRICT mTLS in the Mesh" policies

Define the `mesh-level-strict-mtls` `Constraint` based on the [`AsmPeerAuthnMeshStrictMtls`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmpeerauthnmeshstrictmtls) `ConstraintTemplate`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/mesh-level-strict-mtls.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmPeerAuthnMeshStrictMtls
metadata:
  name: mesh-level-strict-mtls
spec:
  enforcementAction: deny
  parameters:
    rootNamespace: istio-system
    strictnessLevel: High
EOF
```

Define the `peerauthentication-strict-mtls` `Constraint` based on the [`AsmPeerAuthnStrictMtls`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmpeerauthnstrictmtls) `ConstraintTemplate` for `PeerAuthentications`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/peerauthentication-strict-mtls.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmPeerAuthnStrictMtls
metadata:
  name: peerauthentication-strict-mtls
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - security.istio.io
      kinds:
      - PeerAuthentication
  parameters:
    rootNamespace: istio-system
    strictnessLevel: High
EOF
```

Define the `destination-rule-tls-enabled` `Constraint` based on the [`DestinationRuleTLSEnabled`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#destinationruletlsenabled) `ConstraintTemplate` for `DestinationRules`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/destinationrule-tls-enabled.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: DestinationRuleTLSEnabled
metadata:
  name: destinationrule-tls-enabled
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - networking.istio.io
      kinds:
      - DestinationRule
EOF
```

## Define AuthorizationPolicy policies

https://istio.io/latest/docs/reference/config/security/authorization-policy/

Define the `default-deny-authorization-policies` `Constraint` based on the [`AsmAuthzPolicyDefaultDeny`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmauthzpolicydefaultdeny) `ConstraintTemplate` for `DestinationRules`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/default-deny-authorization-policies.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmAuthzPolicyDefaultDeny
metadata:
  name: default-deny-authorization-policies
spec:
  enforcementAction: deny
  parameters:
    rootNamespace: istio-system
    strictnessLevel: High
EOF
```

Define the `authz-source-principals-not-all` `Constraint` based on the [`AsmAuthzPolicyEnforceSourcePrincipals`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmauthzpolicyenforcesourceprincipals) `ConstraintTemplate` for `DestinationRules`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/authz-source-principals-not-all.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmAuthzPolicyEnforceSourcePrincipals
metadata:
  name: authz-source-principals-not-all
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - security.istio.io
      kinds:
      - AuthorizationPolicy
    excludedNamespaces:
      - ${INGRESS_GATEWAY_NAMESPACE}
EOF
```

Define the `authz-source-principals-prefix-not-default` `Constraint` based on the [`AsmAuthzPolicyDisallowedPrefix`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmauthzpolicydisallowedprefix) `ConstraintTemplate` for `AuthorizationPolicies`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/authz-source-principals-prefix-not-default.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmAuthzPolicyDisallowedPrefix
metadata:
  name: authz-source-principals-prefix-not-default
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - security.istio.io
      kinds:
      - AuthorizationPolicy
  parameters:
    disallowedPrincipalPrefixes:
    - default
EOF
```

## Define Gatekeeper config for Referrential `Constraints`

Update the previously defined `config-referential-constraints` `Config`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/gatekeeper-system/config-referential-constraints.yaml
apiVersion: config.gatekeeper.sh/v1alpha1
kind: Config
metadata:
  name: config
  namespace: gatekeeper-system
spec:
  sync:
    syncOnly:
      - group: ""
        version: "v1"
        kind: "Namespace"
      - group: "networking.k8s.io"
        version: "v1"
        kind: "NetworkPolicy"
      - group: "security.istio.io"
        version: "v1beta1"
        kind: "PeerAuthentication"
      - group: "security.istio.io"
        version: "v1beta1"
        kind: "AuthorizationPolicy"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Policies for ASM/Istio"
git push origin main
```

## Check deployments

Here is what you should have at this stage:

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Enforce ASM/Istio Policies in GKE cluster             ci        main    push   1972257889  58s      4m
✓       ASM configs (mTLS, Sidecar, etc.) in GKE cluster      ci        main    push   1972234050  56s      17m
✓       ASM MCP for GKE cluster                               ci        main    push   1972222841  56s      22m
✓       Enforce Container Registries Policies in GKE cluster  ci        main    push   1972138349  55s      1h
✓       Policies for NetworkPolicy resources                  ci        main    push   1971716019  1m14s    3h
✓       Network Policies logging                              ci        main    push   1971353547  1m1s     5h
✓       Config Sync monitoring                                ci        main    push   1971296656  1m9s     6h
✓       Initial commit                                        ci        main    push   1970951731  57s      7h
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
│                           │ Namespace                 │ istio-system                    │                              │
│                           │ Namespace                 │ config-management-monitoring    │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos           │ allowed-container-registries    │                              │
│ constraints.gatekeeper.sh │ PolicyStrictOnly          │ policy-strict-only              │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ namespace-required-labels       │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ automatic-sidecar-injection     │                              │
│ constraints.gatekeeper.sh │ DestinationRuleTLSEnabled │ destination-rule-tls-enabled    │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels         │ deployment-required-labels      │                              │
│ constraints.gatekeeper.sh │ SourceNotAllAuthz         │ defined-authz-source-principals │                              │
│ constraints.gatekeeper.sh │ AllowedServicePortName    │ allowed-service-port-names      │                              │
│ networking.gke.io         │ NetworkLogging            │ default                         │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ sourcenotallauthz               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8sallowedrepos                 │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ destinationruletlsenabled       │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ k8srequiredlabels               │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ allowedserviceportname          │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate        │ policystrictonly                │                              │
│                           │ ServiceAccount            │ default                         │ config-management-monitoring │
│                           │ ConfigMap                 │ istio-asm-managed-rapid         │ istio-system                 │
│ mesh.cloud.google.com     │ ControlPlaneRevision      │ asm-managed-rapid               │ istio-system                 │
│ security.istio.io         │ PeerAuthentication        │ default                         │ istio-system                 │
└───────────────────────────┴───────────────────────────┴─────────────────────────────────┴──────────────────────────────┘
```