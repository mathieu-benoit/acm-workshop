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
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Enforce NetworkPolicies policies

### Require labels for Namespaces and Pods

As a best practice and in order to get the `NetworkPolicies` working in this workshop, we need to guarantee that that any `Namespaces` have a `name` label and `Pods` have an `app` label.

Define the `namespaces-required-labels` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-required-labels.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/pods-required-labels.yaml
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
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-required-networkpolicies.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireNamespaceNetworkPolicies
metadata:
  name: namespaces-required-networkpolicies
spec:
  enforcementAction: dryrun
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
EOF
```

### Define Gatekeeper config for Referrential Constraints

Create the `gatekeeper-system` folder:
```Bash
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/gatekeeper-system
```

Define the `gatekeeper-system` `Namespace`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/gatekeeper-system/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: gatekeeper-system
EOF
```

Define the `config-referential-constraints` `Config`:
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
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Policies for NetworkPolicies" && git push origin main
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