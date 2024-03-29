---
title: "Enforce Service Mesh policies"
weight: 4
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["asm", "platform-admin", "policies", "security-tips"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will enforce policies in order to make sure that your clusters, namespaces and apps are well configured to be secured by your Service Mesh.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAMESPACE=asm-ingress" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define "Automatic sidecar proxy injection" policies

https://cloud.google.com/service-mesh/docs/anthos-service-mesh-proxy-injection

Define the `namespaces-automatic-sidecar-injection-label` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-automatic-sidecar-injection-label.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: namespaces-automatic-sidecar-injection-label
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires Namespaces to have the "istio-injection" label in order to be included in the Service Mesh.',
        remediation: 'Any Namespaces should have the "istio-injection" label with the "enabled" value.'
      }"
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
    - kube-node-lease
    - kube-public
    - kube-system
    - resource-group-system
    - poco-trial
  parameters:
    labels:
    - allowedRegex: enabled
      key: istio-injection
EOF
```

Define the `pods-sidecar-injection-annotation` `Constraint` based on the [`AsmSidecarInjection`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#asmsidecarinjection) `ConstraintTemplate` for `Pods`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/pods-sidecar-injection-annotation.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmSidecarInjection
metadata:
  name: pods-sidecar-injection-annotation
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Enforce the istio proxy sidecar always been injected to workload pods.',
        remediation: 'Any Pods shouldn't have the "sidecar.istio.io/inject" annotation set to "false".'
      }"
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

Define the `mesh-level-strict-mtls` `Constraint` based on the [`AsmPeerAuthnMeshStrictMtls`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#asmpeerauthnmeshstrictmtls) `ConstraintTemplate`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/mesh-level-strict-mtls.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmPeerAuthnMeshStrictMtls
metadata:
  name: mesh-level-strict-mtls
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Enforce the mesh level strict mtls PeerAuthentication.',
        remediation: 'The istio-system namespace should have a default PeerAuthentication with STRICT mTLS.'
      }"
spec:
  enforcementAction: deny
  parameters:
    rootNamespace: istio-system
    strictnessLevel: High
EOF
```

Define the `peerauthentication-strict-mtls` `Constraint` based on the [`AsmPeerAuthnStrictMtls`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#asmpeerauthnstrictmtls) `ConstraintTemplate` for `PeerAuthentications`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/peerauthentication-strict-mtls.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmPeerAuthnStrictMtls
metadata:
  name: peerauthentication-strict-mtls
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Enforce all PeerAuthentications cannot overwrite strict mtls.',
        remediation: 'Any PeerAuthentications should have STRICT mTLS.'
      }"
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

Define the `destination-rule-tls-enabled` `Constraint` based on the [`DestinationRuleTLSEnabled`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#destinationruletlsenabled) `ConstraintTemplate` for `DestinationRules`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/destinationrule-tls-enabled.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: DestinationRuleTLSEnabled
metadata:
  name: destinationrule-tls-enabled
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Prohibits disabling TLS for all hosts and host subsets in Istio DestinationRules.',
        remediation: 'Any DestinationRules should not disable TLS.'
      }"
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

Define the `default-deny-authorization-policies` `Constraint` based on the [`AsmAuthzPolicyDefaultDeny`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#asmauthzpolicydefaultdeny) `ConstraintTemplate` for `DestinationRules`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/default-deny-authorization-policies.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmAuthzPolicyDefaultDeny
metadata:
  name: default-deny-authorization-policies
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Enforce the mesh level default deny AuthorizationPolicy. Reference to https://istio.io/latest/docs/ops/best-practices/security/#use-default-deny-patterns.',
        remediation: 'The istio-system namespace should have a default deny-all AuthorizationPolicy for the entire mesh.'
      }"
spec:
  enforcementAction: deny
  parameters:
    rootNamespace: istio-system
    strictnessLevel: High
EOF
```

Define the `authz-source-principals-not-all` `Constraint` based on the [`AsmAuthzPolicyEnforceSourcePrincipals`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#asmauthzpolicyenforcesourceprincipals) `ConstraintTemplate` for `DestinationRules`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/authz-source-principals-not-all.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmAuthzPolicyEnforceSourcePrincipals
metadata:
  name: authz-source-principals-not-all
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires that Istio AuthorizationPolicy "from" field, when defined, has source principles, which must be set to something other than "*".',
        remediation: 'Any AuthorizationPolicies shouldn't define the "from" field with "*".'
      }"
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

Define the `authz-source-principals-prefix-not-default` `Constraint` based on the [`AsmAuthzPolicyDisallowedPrefix`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#asmauthzpolicydisallowedprefix) `ConstraintTemplate` for `AuthorizationPolicies`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/authz-source-principals-prefix-not-default.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AsmAuthzPolicyDisallowedPrefix
metadata:
  name: authz-source-principals-prefix-not-default
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires that principals and namespaces in Istio AuthorizationPolicy rules not have a prefix from a specified list.',
        remediation: 'Any AuthorizationPolicies shouldn't have the principal as "default".'
      }"
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

## Define K8sBlockAllIngress policy

Define the `block-all-ingress` `Constraint` based on the [`K8sBlockAllIngress`](https://cloud.google.com/anthos-config-management/docs/latest/reference/constraint-template-library#k8sblockallingress) `ConstraintTemplate` to only allow public ingress from the ASM Ingress Gateway:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/block-all-ingress.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sBlockAllIngress
metadata:
  name: block-all-ingress
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Disallows the creation of Ingress objects (Ingress, Gateway, and Service types of NodePort and LoadBalancer).',
        remediation: 'Any Ingress objects (Ingress, Gateway, and Service) should go through the ASM Ingress Gateway instead.'
      }"
spec:
  enforcementAction: deny
  match:
    excludedNamespaces:
    - kube-system # default-http-backend as NodePort
    - ${INGRESS_GATEWAY_NAMESPACE} # asm-ingressgateway as LoadBalancer
EOF
```

## Define VirtualServiceWithHost policy

Define the `ConstraintTemplate`:
```bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/templates/virtualservicewithhost.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: virtualservicewithhost
  annotations:
    description: "VirtualService shouldn't define the hosts with *."
spec:
  crd:
    spec:
      names:
        kind: VirtualServiceWithHost
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package virtualservicewithhost
        # spec.hosts does not exist
        violation[{"msg": msg}] {
          is_virtualservice(input.review.kind)
          not contains_hosts(input.review.object.spec)
          msg := "hosts does not exist"
        }
        # spec.hosts does not contain '*'
        violation[{"msg": msg}] {
          is_virtualservice(input.review.kind)
          principal := input.review.object.spec.hosts[_]
          principal == "*"
          msg := "hosts[] cannot be '*'"
        }
        is_virtualservice(kind) {
          kind.kind == "VirtualService"
          kind.group == "networking.istio.io"
        }
        contains_hosts(spec) {
          spec.hosts
        }
EOF
```

Define the `virtual-service-with-host` `Constraint` based on the `VirtualServiceWithHost` `ConstraintTemplate` just defined:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/virtual-service-with-host.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: VirtualServiceWithHost
metadata:
  name: virtual-service-with-host
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires that Istio VirtualService "hosts" must be set to something other than "*".',
        remediation: 'Any VirtualService shouldn't define the "hosts" with "*".'
      }"
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - networking.istio.io
      kinds:
      - VirtualService
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

See the Policy Controller `Constraints` without any violations in the **GKE cluster**, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```