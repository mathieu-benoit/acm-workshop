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
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAMESPACE=asm-ingress" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define "Automatic sidecar proxy injection" policies

https://cloud.google.com/service-mesh/docs/anthos-service-mesh-proxy-injection

Define the `namespaces-automatic-sidecar-injection-label` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-automatic-sidecar-injection-label.yaml
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
    - allowedRegex: enabled
      key: istio-injection
EOF
```

Define the `pods-sidecar-injection-annotation` `Constraint` based on the [`AsmSidecarInjection`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmsidecarinjection) `ConstraintTemplate` for `Pods`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/pods-sidecar-injection-annotation.yaml
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

Define the `namespaces-managed-dataplance-annotation` `Constraint` based on the [`K8sRequiredAnnotations`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredannotations) `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-managed-dataplance-annotation.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredAnnotations
metadata:
  name: namespaces-managed-dataplance-annotation
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
    annotations:
    - allowedRegex: '{"managed": true}'
      key: mesh.cloud.google.com/proxy
EOF
```

## Define "STRICT mTLS in the Mesh" policies

Define the `mesh-level-strict-mtls` `Constraint` based on the [`AsmPeerAuthnMeshStrictMtls`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#asmpeerauthnmeshstrictmtls) `ConstraintTemplate`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/mesh-level-strict-mtls.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/peerauthentication-strict-mtls.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/destinationrule-tls-enabled.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/default-deny-authorization-policies.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/authz-source-principals-not-all.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/authz-source-principals-prefix-not-default.yaml
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

## Update Gatekeeper config for Referrential `Constraints`

Update the previously defined `config-referential-constraints` `Config`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/gatekeeper-system/config-referential-constraints.yaml
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
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Policies for ASM/Istio" && git push origin main
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