---
title: "Enforce Tenant projects policies"
weight: 4
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin", "policies", "security-tips"]
---
![Org Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/org-admin.png)
_{{< param description >}}_

In this section you will enforce policies to guarantee that any `Namespaces` in the ConfigController instance defining any Tenant project should contain its own `ConfigConnectorContext` object in order to leverage the [namespaced mode of Config Connector](https://cloud.google.com/config-connector/docs/how-to/advanced-install#namespaced-mode).

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define the "Require ConfigConnectorContext for Namespaces" policies

Define the `ConstraintTemplate` making sure that any `Namespaces` has a `ConfigConnectorContext` in it:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/templates/requirenamespaceconfigconnectorcontext.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: requirenamespaceconfigconnectorcontext
  annotations:
    description: "Requires that every namespaces defined in the cluster has a ConfigConnectorContext. Note: This constraint is referential. See https://cloud.google.com/anthos-config-management/docs/how-to/creating-constraints#referential for details."
spec:
  crd:
    spec:
      names:
        kind: RequireNamespaceConfigConnectorContext
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package requirenamespaceconfigconnectorcontext
          violation[{"msg": msg}] {
          input.review.kind.kind == "Namespace"
          not namespace_has_configconnectorcontext(input.review.object.metadata.name)
          msg := sprintf("Namespace <%v> does not have a ConfigConnectorContext", [input.review.object.metadata.name])
        }
        namespace_has_configconnectorcontext(ns) {
          ccc := data.inventory.namespace[ns][_].ConfigConnectorContext[_]
        }
EOF
```

Define the `namespaces-required-configconnectorcontext` `Constraint` based on the `RequireNamespaceConfigConnectorContext` `ConstraintTemplate` for `Namespaces`:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/constraints/namespaces-required-configconnectorcontext.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: RequireNamespaceConfigConnectorContext
metadata:
  name: namespaces-required-configconnectorcontext
  annotations:
    policycontroller.gke.io/constraintData: |
      "{
        description: 'Requires Namespaces to have a ConfigConnectorContext in order to leverage Config Connector.',
        remediation: 'Any Namespaces should have a ConfigConnectorContext.'
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
    - cnrm-system
    - config-control
    - config-management-monitoring
    - config-management-system
    - configconnector-operator-system
    - default
    - gatekeeper-system
    - krmapihosting-monitoring
    - krmapihosting-system
    - kube-node-lease
    - kube-public
    - kube-system
    - resource-group-system
EOF
```

Because this is [constraint is referential](https://cloud.google.com/anthos-config-management/docs/how-to/creating-constraints#referential) (look at `ConfigConnectorContext` in `Namespace`), we need to define an associated `Config` in the `gatekeeper-system` `Namespace`:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/config-referential-constraints.yaml
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
      - group: "core.cnrm.cloud.google.com"
        version: "v1beta1"
        kind: "ConfigConnectorContext"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Enforce policies for Tenant projects" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${HOST_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` too.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **Host project configs** repository:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME && gh run list
```