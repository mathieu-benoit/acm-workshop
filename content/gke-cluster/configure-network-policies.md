---
title: "Configure Network Policy"
weight: 6
description: "Duration: 5 min | Persona: Platform Admin"
---
_{{< param description >}}_

Define variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define Network Policy logging

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

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Network Policies logging"
git push
```

## Enforce NetworkPolicy policies

### Required labels on Namespace and Deployment

As a best practice and in order to get the `NetworkPolicy` resources working in this workshop, we need to guarantee that that any `Namespace` has a `name` label and `Deployment` has an `app` label.

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/k8srequiredlabels.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  annotations:
    description: Requires resources to contain specified labels.
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
                  key:
                    description: The required label.
                    type: string
                type: object
              type: array
          type: object
  targets:
  - rego: |
      package k8srequiredlabels
      violation[{"msg": msg}] {
        not input.review.object.kind == "Deployment"
        provided := {label | input.review.object.metadata.labels[label]}
        required := {label | label := input.parameters.labels[_].key}
        missing := required - provided
        count(missing) > 0
        msg := sprintf("you must provide labels: %v", [missing])
      }
      violation[{"msg": msg}] {
        input.review.object.kind == "Deployment"
        provided := {label | input.review.object.spec.template.metadata.labels[label]}
        required := {label | label := input.parameters.labels[_].key}
        missing := required - provided
        count(missing) > 0
        msg := sprintf("you must provide labels: %v", [missing])
      }
    target: admission.k8s.gatekeeper.sh
EOF
```

Define the `Constraint` resource for the `Namespace` resources:
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
    - key: name
EOF
```

Define the `Constraint` resource for the `Deployment` resources:
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
      - ""
      kinds:
      - Pod
    - apiGroups:
      - apps
      kinds:
      - Deployment
    excludedNamespaces:
    - config-management-monitoring
    - config-management-system
    - default
    - gatekeeper-system
    - kube-node-lease
    - kube-public
    - kube-system
    - resource-group-system
  parameters:
    labels:
    - key: app
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Policies for NetworkPolicy resources"
git push
```

## Check deployments

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Policies for NetworkPolicy resources  ci        main    push   1971716019  1m14s    2m
✓       Network Policies logging              ci        main    push   1971353547  1m1s     1h
✓       Config Sync monitoring                ci        main    push   1971296656  1m9s     2h
✓       Initial commit                        ci        main    push   1970951731  57s      3h
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
┌───────────────────────────┬────────────────────┬──────────────────────────────┬──────────────────────────────┐
│           GROUP           │        KIND        │             NAME             │          NAMESPACE           │
├───────────────────────────┼────────────────────┼──────────────────────────────┼──────────────────────────────┤
│                           │ Namespace          │ config-management-monitoring │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels  │ deployment-required-labels   │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels  │ namespace-required-labels    │                              │
│ networking.gke.io         │ NetworkLogging     │ default                      │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate │ k8srequiredlabels            │                              │
│                           │ ServiceAccount     │ default                      │ config-management-monitoring │
└───────────────────────────┴────────────────────┴──────────────────────────────┴──────────────────────────────┘
```