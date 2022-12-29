---
title: "Configure Config Sync"
weight: 3
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["asm", "gitops-tips", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will configure Config Sync to sync the resources in the Online Boutique `Namespace` via its associated `RoleBinding`.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINEBOUTIQUE_NAMESPACE=onlineboutique" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

```Bash
mkdir -p ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs
mkdir ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Namespace

Define a dedicated `Namespace` for the Online Boutique apps:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    name: ${ONLINEBOUTIQUE_NAMESPACE}
    istio-injection: enabled
  name: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
```

## Allo Config Sync to sync Istio resources

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/repo-sync-role-binding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: repo-sync
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ns-reconciler-${ONLINEBOUTIQUE_NAMESPACE}
  namespace: config-management-system
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
EOF
```
{{% notice tip %}}
We are using the [`edit` user-facing role](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) here, to follow the least privilege principle. Earlier in this workshop during the ASM installation, we extended the default `edit` role with more capabilities regarding to the Istio resources: `VirtualServices`, `Sidecars` and `AuthorizationPolicies` which will be leveraged in the OnlineBoutique's namespace.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Configure Config Sync for Online Boutique" && git push origin main
```

FIXME