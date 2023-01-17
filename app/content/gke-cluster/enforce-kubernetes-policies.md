---
title: "Enforce Kubernetes policies"
weight: 6
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin", "policies", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will enforce Kubernetes policies for Pod Security Admission (PSA) and `NetworkPolicies`.

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Enforce Pod Security Admission (PSA) policies

As best practice we will ensure that any `Namespaces` enables the [Pod Security Admission (PSA)](https://kubernetes.io/docs/concepts/security/pod-security-admission/) feature.

Define the `namespaces-required-psa-label` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.google.com/anthos-config-management/docs/latest/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-required-psa-label.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: namespaces-required-psa-label
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires Namespaces to have the "pod-security.kubernetes.io/enforce" label with either the value "baseline" or "restricted".',
        remediation: 'Any Namespaces should have the "pod-security.kubernetes.io/enforce" label with either the value "baseline" or "restricted".'
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
    - key: pod-security.kubernetes.io/enforce
      allowedRegex: (baseline|restricted)
EOF
```
{{% notice note %}}
As of now, only the `asm-ingress` and `onlineboutique` namespaces support `restricted`. On the other hand, the `whereami` and `bankofanthos` namespaces only support `baseline`. We are authorizing both here.
{{% /notice %}}

## Enforce NetworkPolicies policies

### Require labels for Namespaces and Pods

As a best practice and in order to get the `NetworkPolicies` working in this workshop, we need to guarantee that any `Pods` have a label `app`.

Define the `pods-required-app-label` `Constraint` based on the [`K8sRequiredLabels`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequiredlabels) `ConstraintTemplate` for `Pods`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/pods-required-app-label.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: pods-required-app-label
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires Pods to have the name "app" in order to leverage the podSelector feature of NetworkPolicies.',
        remediation: 'Any Pods should have the "app" label.'
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
    - config-management-monitoring
    - config-management-system
    - default
    - gatekeeper-system
    - kube-node-lease
    - kube-public
    - kube-system
    - resource-group-system
    - poco-trial
  parameters:
    labels:
    - key: app
EOF
```
{{% notice note %}}
Complementary to this, on `Namespaces` the [`kubernetes.io/metadata.name` label](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/#automatic-labelling) automatically set by Kubernetes 1.22+ will be leveraged.
{{% /notice %}}

### Require NetworkPolicies in Namespaces

Define the `namespaces-required-networkpolicies` `Constraint` based on the [`K8sRequireNamespaceNetworkPolicies`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library#k8srequirenamespacenetworkpolicies) `ConstraintTemplate` for `Namespaces`. This `Constraint` requires that any `Namespaces` defined in the cluster has a `NetworkPolicy`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/namespaces-required-networkpolicies.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireNamespaceNetworkPolicies
metadata:
  name: namespaces-required-networkpolicies
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires that every namespace defined in the cluster has NetworkPolicies.',
        remediation: 'Any namespace should have NetworkPolicies. It's highly recommended to have at least a first default deny-all and then one fine granular NetworkPolicy per app.'
      }"
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

Because this is [constraint is referential](https://cloud.google.com/anthos-config-management/docs/how-to/creating-constraints#referential) (look at `NetworkPolicy` in `Namespace`), we need to define an associated `Config` in the `gatekeeper-system` `Namespace`:

Create the `gatekeeper-system` folder:
```Bash
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/gatekeeper-system
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
git add . && git commit -m "Policies for Kubernetes resources" && git push origin main
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