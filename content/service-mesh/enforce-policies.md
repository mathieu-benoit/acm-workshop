---
title: "Enforce policies"
weight: 4
---
- Persona: Platform Admin
- Duration: 10 min
- Objectives:
  - FIXME

## Allowed Service port names

https://cloud.google.com/service-mesh/docs/naming-service-ports

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/allowed-service-port-names.yaml
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

## Policy STRICT only

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/policy-strict-only.yaml
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

Deploy this Kubernetes manifest via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Enforce ASM/Istio Policies in GKE cluster"
git push
```