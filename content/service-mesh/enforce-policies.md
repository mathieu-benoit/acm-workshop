---
title: "Enforce policies"
weight: 4
description: "Duration: 10 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAMESPACE=asm-ingress" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define "Automatic sidecar injection" policies

https://cloud.google.com/service-mesh/docs/anthos-service-mesh-proxy-injection

We already defined the `k8srequiredlabels` `ConstraintTemplate` resource in a previous section, we will reuse it here.

Define the `automatic-sidecar-injection` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/automatic-sidecar-injection.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: automatic-sidecar-injection
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
    - key: istio-discovery
EOF
```

Define the `PodSidecarInjection` `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/podsidecarinjection.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Enforce the istio proxy sidecar always been injected to workload.
  name: podsidecarinjection
spec:
  crd:
    spec:
      names:
        kind: PodSidecarInjection
  targets:
  - rego: |-
      package istio.security.workloadpolicy
      resource = input.review.object
      spec = resource.spec
      # Annotation sidecar.istio.io/inject: false should not be applied on workload pods which will bypass istio proxy.
      forbidden_injection_annotation := {"key": "sidecar.istio.io/inject", "value": "false"}
      violation[{"msg": msg}] {
          is_pod(input.review.kind)
          contains(resource.metadata.annotations[forbidden_injection_annotation["key"]], forbidden_injection_annotation["value"])
          msg := sprintf("The annotation %v: %v should not be applied on workload pods", [forbidden_injection_annotation["key"], forbidden_injection_annotation["value"]])
      }
      is_pod(kind) {
          kind.kind == "Pod"
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `pod-sidecar-injection` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/pod-sidecar-injection.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: PodSidecarInjection
metadata:
  name: pod-sidecar-injection
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
    excludedNamespaces:
    - kube-system # to exclude istio-cni pods.
EOF
```

## Define "STRICT mTLS in the Mesh" policies

Define the `PeerAuthnStrictMtls` `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/peerauthnmeshstrictmtls.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Enforce the mesh level strict mtls PeerAuthentication.
  name: peerauthnmeshstrictmtls
spec:
  crd:
    spec:
      names:
        kind: PeerAuthnMeshStrictMtls
      validation:
        openAPIV3Schema:
          type: object
          properties:
            rootNamespace:
              description: Istio root namespace, default value is "istio-system" if not specified.
              type: string
  targets:
  - rego: |-
      package istio.security.peerauthentication
      violation[{"msg": msg}] {
        is_peer_authn_mesh_strict_mtls(input.review.kind)
        root_ns := object.get(object.get(input, "parameters", {}), "rootNamespace", "istio-system")
        not namespace_has_default_strict_mtls_pa(root_ns)
        msg := sprintf("Root namespace <%v> does not have a strict mTLS PeerAuthentication", [root_ns])
      }
      namespace_has_default_strict_mtls_pa(ns) {
        pa := data.inventory.namespace[ns][_].PeerAuthentication[_]
        pa.spec.mtls.mode == "STRICT"
      }
      is_peer_authn_mesh_strict_mtls(kind) {
        kind.kind == "PeerAuthnMeshStrictMtls"
        kind.group == "constraints.gatekeeper.sh"
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `mesh-level-strict-mtls` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/mesh-level-strict-mtls.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: PeerAuthnMeshStrictMtls
metadata:
  name: mesh-level-strict-mtls
spec:
  enforcementAction: deny
EOF
```

Define the `PeerAuthnStrictMtls` `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/peerauthnstrictmtls.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Enforce all PeerAuthentications cannot overwrite strict mtls.
  name: peerauthnstrictmtls
spec:
  crd:
    spec:
      names:
        kind: PeerAuthnStrictMtls
  targets:
  - rego: |-
      package istio.security.peerauthentication
      spec = input.review.object.spec
      valid_modes := {"UNSET", "STRICT"}
      violation[{"msg": msg}] {
          is_peerauthentication(input.review.kind)
          count({spec.mtls.mode} - valid_modes) > 0
          msg := "PeerAuthentication mtls mode can only be set to UNSET or STRICT"
      }
      violation[{"msg": msg}] {
          is_peerauthentication(input.review.kind)
          count({spec.portLevelMtls[port].mode} - valid_modes) > 0
          msg := sprintf("PeerAuthentication port <%v> has invalid mtls mode <%v>, it can only be set to UNSET or STRICT", [port, spec.portLevelMtls[port].mode])
      }
      is_peerauthentication(kind) {
          kind.kind == "PeerAuthentication"
          kind.group == "security.istio.io"
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `peerauthentication-strict-mtls` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/peerauthentication-strict-mtls.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: PeerAuthnStrictMtls
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
EOF
```

Define the [`DestinationRuleTLSEnabled`](https://istio.io/latest/docs/reference/config/networking/destination-rule) `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/destinationruletlsenabled.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Prohibits disabling TLS for all hosts and host subsets in Istio DestinationRules.
  name: destinationruletlsenabled
spec:
  crd:
    spec:
      names:
        kind: DestinationRuleTLSEnabled
  targets:
  - rego: |
      package asm.guardrails.destinationruletlsenabled
      # spec.trafficPolicy.tls.mode == DISABLE
      violation[{"msg": msg}] {
        d := input.review.object
        startswith(d.apiVersion, "networking.istio.io/")
        d.kind == "DestinationRule"
        tpl := d.spec.trafficPolicy[_]
        tpl == {"mode": "DISABLE"}
        msg := sprintf("spec.trafficPolicy.tls.mode == DISABLE for host(s): %v", [d.spec.host])
      }
      # spec.subsets[].trafficPolicy.tls.mode == DISABLE
      violation[{"msg": msg}] {
        d := input.review.object
        startswith(d.apiVersion, "networking.istio.io/")
        d.kind == "DestinationRule"
        subset := d.spec.subsets[_]
        subset.trafficPolicy == {"tls": {"mode": "DISABLE"}}
        msg := sprintf("subsets[].trafficPolicy.tls.mode == DISABLE for host-subset: %v-%v", [d.spec.host, subset.name])
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `destination-rule-tls-enabled` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/destination-rule-tls-enabled.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: DestinationRuleTLSEnabled
metadata:
  name: destination-rule-tls-enabled
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

Define the `AuthzPolicyDefaultDeny` `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/authzpolicydefaultdeny.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Enforce the mesh level strict mtls PeerAuthentication.
  name: authzpolicydefaultdeny
spec:
  crd:
    spec:
      names:
        kind: AuthzPolicyDefaultDeny
      validation:
        openAPIV3Schema:
          type: object
          properties:
            rootNamespace:
              description: Istio root namespace, default value is "istio-system" if not specified.
              type: string
  targets:
  - rego: |-
      package istio.security.authorizationpolicy
      violation[{"msg": msg}] {
        is_authz_policy_default_deny(input.review.kind)
        # use input root namespace or default value istio-system
        root_ns := object.get(object.get(input, "parameters", {}), "rootNamespace", "istio-system")
        not namespace_has_default_deny_policy(root_ns)
        msg := sprintf("Root namespace <%v> does not have a default deny AuthorizationPolicy", [root_ns])
      }
      is_authz_policy_default_deny(kind) {
        kind.kind == "AuthzPolicyDefaultDeny"
        kind.group == "constraints.gatekeeper.sh"
      }
      namespace_has_default_deny_policy(ns) {
        ap := data.inventory.namespace[ns][_].AuthorizationPolicy[_]
        is_allow_action(ap)
        not ap.spec.rules
      }
      is_allow_action(ap) {
        ap.spec.action == "ALLOW"
      }
      is_allow_action(ap) {
        not ap.spec.action
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `default-deny-authorization-policies` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/default-deny-authorization-policies.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AuthzPolicyDefaultDeny
metadata:
  name: default-deny-authorization-policies
spec:
  enforcementAction: deny
EOF
```

Define the `SourceNotAllAuthz` `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/sourcenotallauthz.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Requires that Istio AuthorizationPolicy rules have source principals set to something other than "*".
  name: sourcenotallauthz
spec:
  crd:
    spec:
      names:
        kind: SourceNotAllAuthz
  targets:
  - rego: |
      package asm.guardrails.sourcenotallauthz
      # spec.rules[].from[].source.principal does not exist
      violation[{"msg": msg}] {
        p := input.review.object
        startswith(p.apiVersion, "security.istio.io/")
        p.kind == "AuthorizationPolicy"
        rule := p.spec.rules[_]
        sources := {i | rule.from[_].source[i]}
        not sources.principals
        msg := "source.principals does not exist"
      }
      # spec.rules[].from[].source.principal is set to '*'
      violation[{"msg": msg}] {
        p := input.review.object
        startswith(p.apiVersion, "security.istio.io/")
        p.kind == "AuthorizationPolicy"
        rule := p.spec.rules[_]
        principals := {v | v := rule.from[_].source.principals[_]}
        principals["*"]
        msg := "source.principals[] cannot be '*'"
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `defined-authz-source-principals` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/defined-authz-source-principals.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: SourceNotAllAuthz
metadata:
  name: defined-authz-source-principals
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

## Define "Allowed Service port names" policy

Define the [`AllowedServicePortName`](https://cloud.google.com/service-mesh/docs/naming-service-ports) `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/allowedserviceportname.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Requires that service port names have a prefix from a specified list.
  name: allowedserviceportname
spec:
  crd:
    spec:
      names:
        kind: AllowedServicePortName
      validation:
        openAPIV3Schema:
          type: object
          properties:
            prefixes:
              description: Prefixes of allowed service port names.
              items:
                type: string
              type: array
  targets:
  - rego: |
      package asm.guardrails.allowedserviceportname
      violation[{"msg": msg}] {
        service := input.review.object
        port := service.spec.ports[_]
        prefixes := input.parameters.prefixes
        not is_prefixed(port, prefixes)
        msg := "service port name missing prefix"
      }
      is_prefixed(port, prefixes) {
        prefix := prefixes[_]
        startswith(port.name, prefix)
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `allowed-service-port-names` `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/allowed-service-port-names.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AllowedServicePortName
metadata:
  name: allowed-service-port-names
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Service
  parameters:
    prefixes:
    - http
    - http2
    - grpc
EOF
```

## Define Gatekeeper config for Referrential `Constraints`

Create the `gatekeeper-system` folder:
```Bash
mkdir ~/$GKE_CONFIGS_DIR_NAME/config-sync/gatekeeper-system
```

Define the `gatekeeper-system` `Namespace`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/gatekeeper-system/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gatekeeper-system
EOF
```

Define the `config-referential-constraints` `Config`:
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
git commit -m "Enforce ASM/Istio Policies in GKE cluster"
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