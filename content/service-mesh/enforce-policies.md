---
title: "Enforce policies"
weight: 4
---
- Persona: Platform Admin
- Duration: 10 min

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
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
  parameters:
    labels:
      - allowedRegex: (asm-managed|asm-managed-rapid|asm-managed-stable)
        key: "istio.io/rev"
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
git push
```

## Check deployments

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```