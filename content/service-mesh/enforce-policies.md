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

## Define "Automatic sidecar injection" policy

https://cloud.google.com/service-mesh/docs/anthos-service-mesh-proxy-injection

We already defined the `k8srequiredlabels` `ConstraintTemplate` resource in a previous section, we will reuse it here.

Define the `Constraint` resource:
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
    - key: istio.io/rev
    - key: istio-discovery
EOF
```

## Define "Allowed Service port names" policy

https://cloud.google.com/service-mesh/docs/naming-service-ports

Define the `ConstraintTemplate` resource:
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
        legacySchema: true
        openAPIV3Schema:
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

Define the `Constraint` resource:
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

## Define "Policy STRICT only" policy

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/policystrictonly.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: "Requires that STRICT Istio mutual TLS is always specified when
      using [PeerAuthentication](https://istio.io/latest/docs/reference/config/security/peer_authentication/).
      This constraint also ensures that the deprecated [Policy](https://istio.io/v1.4/docs/reference/config/security/istio.authentication.v1alpha1/#Policy)
      and MeshPolicy resources enforce STRICT mutual TLS. See: https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/#lock-down-mutual-tls-for-the-entire-mesh"
  name: policystrictonly
spec:
  crd:
    spec:
      names:
        kind: PolicyStrictOnly
      validation:
        legacySchema: true
        openAPIV3Schema: {}
  targets:
  - rego: |-
      package asm.guardrails.policystrictonly
      OLD_KINDS = ["Policy", "MeshPolicy"]
      strict_mtls {
        p := input.review.object
        count(p.spec.peers) == 1
        p.spec.peers[0].mtls.mode == "STRICT"
      }
      # VIOLATION peer authentication does not set mTLS correctly
      violation[{"msg": msg}] {
        p := input.review.object
        startswith(p.apiVersion, "authentication.istio.io/")
        p.kind == OLD_KINDS[_]
        not strict_mtls
        msg := "spec.peers does not include STRICT mTLS settings"
      }
      # VIOLATION spec.mtls must be set to STRICT
      violation[{"msg": msg}] {
        p := input.review.object
        startswith(p.apiVersion, "security.istio.io/")
        p.kind == "PeerAuthentication"
        not p.spec.mtls.mode == "STRICT"
        msg := "spec.mtls.mode must be set to STRICT"
      }
      # VIOLATION no ports can override STRICT mTLS mode
      violation[{"msg": msg}] {
        p := input.review.object
        startswith(p.apiVersion, "security.istio.io/")
        p.kind == "PeerAuthentication"
        valid_modes := {"UNSET", "STRICT"}
        count({p.spec.portLevelMtls[port].mode} - valid_modes) > 0
        msg := sprintf("port <%v> has invalid mtls mode <%v>", [port, p.spec.portLevelMtls[port].mode])
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/policy-strict-only.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: PolicyStrictOnly
metadata:
  name: policy-strict-only
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - authentication.istio.io
      kinds:
      - Policy
    - apiGroups:
      - security.istio.io
      kinds:
      - PeerAuthentication
EOF
```

## Define "Defined AuthorizationPolicy source principals" policy

https://istio.io/latest/docs/reference/config/security/authorization-policy/

Define the `ConstraintTemplate` resource:
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
      validation:
        legacySchema: true
        openAPIV3Schema: {}
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

Define the `Constraint` resource:
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

## Define "DestinationRule TLS enabled" policy

https://istio.io/latest/docs/reference/config/networking/destination-rule

Define the `ConstraintTemplate` resource:
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
      validation:
        legacySchema: true
        openAPIV3Schema: {}
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

Define the `Constraint` resource:
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