---
title: "Set up NetworkPolicies policies"
weight: 7
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin", "policies", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Define variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Enforce NetworkPolicies policies

### Require labels for Namespaces and Pods

As a best practice and in order to get the `NetworkPolicies` working in this workshop, we need to guarantee that that any `Namespaces` have a `name` label and `Pods` have an `app` label.

Define the `namespaces-required-labels` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-required-labels.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: namespaces-required-labels
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

Define the `pods-required-labels` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Pods`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/policies/constraints/pods-required-labels.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: pods-required-labels
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
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

### Require NetworkPolicies in Namespaces

Define the `namespaces-required-networkpolicies` `Constraint` based on the [`K8sRequireNamespaceNetworkPolicies`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequirenamespacenetworkpolicies) `ConstraintTemplate` for `Namespaces`. This `Constraint` requires that any `Namespaces` defined in the cluster has a `NetworkPolicy`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-required-labels.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireNamespaceNetworkPolicies
metadata:
  name: namespaces-required-networkpolicies
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
EOF
```

### Define Gatekeeper config for Referrential `Constraints`

Create the `gatekeeper-system` folder:
```Bash
mkdir ~/$GKE_CONFIGS_DIR_NAME/gatekeeper-system
```

Define the `gatekeeper-system` `Namespace`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/gatekeeper-system/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gatekeeper-system
EOF
```

Define the `config-referential-constraints` `Config`:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/gatekeeper-system/config-referential-constraints.yaml
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
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Policies for NetworkPolicies" && git push origin main
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
    --project $TENANT_PROJECT_ID \
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