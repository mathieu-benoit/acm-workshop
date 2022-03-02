---
title: "Configure Network Policy"
weight: 5
---
- Persona: Platform Admin
- Duration: 5 min
- Objectives:
  - FIXME

Define variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Network Policy logging

https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/networkpolicies-logging.yaml
kind: NetworkLogging
apiVersion: networking.gke.io/v1alpha1
metadata:
  name: default
spec:
  cluster:
    allow:
      log: false
      delegate: false
    deny:
      log: true
      delegate: false
EOF
```

Deploy this `NetworkLogging` resource via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Network Policies logging"
git push
```

## Enforce NetworkPolicy policies

### Required labels on Namespace and Deployment

As a best practice and in order to get the `NetworkPolicy` resources working in this workshop, we need to guarantee that any `Deployment` has an `app` label and that any `Namespace` has an `name` label.

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/k8srequiredlabels.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Requires resources to contain specified labels, with values matching provided regular expressions.
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
      validation:
        legacySchema: true
        openAPIV3Schema:
          properties:
            labels:
              description: A list of labels and values the object must specify.
              items:
                properties:
                  allowedRegex:
                    description: If specified, a regular expression the annotation's
                      value must match. The value must contain at least one match
                      for the regular expression.
                    type: string
                  key:
                    description: The required label.
                    type: string
                type: object
              type: array
            message:
              type: string
          type: object
  targets:
  - rego: |
      package k8srequiredlabels
      get_message(parameters, _default) = msg {
        not parameters.message
        msg := _default
      }
      get_message(parameters, _default) = msg {
        msg := parameters.message
      }
      violation[{"msg": msg, "details": {"missing_labels": missing}}] {
        provided := {label | input.review.object.metadata.labels[label]}
        required := {label | label := input.parameters.labels[_].key}
        missing := required - provided
        count(missing) > 0
        def_msg := sprintf("you must provide labels: %v", [missing])
        msg := get_message(input.parameters, def_msg)
      }
      violation[{"msg": msg}] {
        value := input.review.object.metadata.labels[key]
        expected := input.parameters.labels[_]
        expected.key == key
        # do not match if allowedRegex is not defined, or is an empty string
        expected.allowedRegex != ""
        not re_match(expected.allowedRegex, value)
        def_msg := sprintf("Label <%v: %v> does not satisfy allowed regex: %v", [key, value, expected.allowedRegex])
        msg := get_message(input.parameters, def_msg)
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `Constraint` resource for the `Deployment` resources:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/namespace-required-labels.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: namespace-required-labels
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Namespace
    excludedNamespaces:
      - cnrm-system
      - 
      - istio-system
  parameters:
    labels:
      - key: name
EOF
```

Define the `Constraint` resource for the `Namespace` resources:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/deployment-required-labels.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: deployment-required-labels
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - apps
      kinds:
      - Deployment
  parameters:
    labels:
      - key: app
EOF
```

### Requireed NetworPolicy in Namespace

FIXME - https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequirenamespacenetworkpolicies

Deploy these Kubernetes resources via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Policies for NetworkPolicy resources"
git push
```