---
title: "Allow Networking"
weight: 1
description: "Duration: 2 min | Persona: Org Admin"
tags: ["kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define role

Define the `compute.networkAdmin` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the Tenant project's service account:
```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/network-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: network-admin-${TENANT_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${TENANT_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${TENANT_PROJECT_ID}
  role: roles/compute.networkAdmin
  resourceRef:
    kind: Project
    external: projects/${TENANT_PROJECT_ID}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Allow Networking for Tenant project" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-->Project
  IAMPartialPolicy-->IAMServiceAccount
  ConfigConnectorContext-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
{{< /mermaid >}}

List the GCP resources created:
```Bash
gcloud projects get-iam-policy $TENANT_PROJECT_ID \
    --filter="bindings.members:${TENANT_PROJECT_SA_EMAIL}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
```Plaintext
ROLE
roles/compute.networkAdmin
```

List the GitHub runs for the **Host project configs** repository `cd ~/$HOST_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Allow Networking for Tenant project       ci        main    push   1960975064  1m11s    2m
✓       Enforce policies for Tenant project       ci        main    push   1960968253  1m4s     4m
✓       GitOps for Tenant project                 ci        main    push   1960959789  1m5s     7m
✓       Setting up Tenant namespace/project       ci        main    push   1960908849  1m12s    21m
✓       Billing API in Host project               ci        main    push   1960889246  1m0s     28m
✓       Initial commit                            ci        main    push   1960885850  1m8s     29m
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬───────────────────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                        NAME                       │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ config-control                                    │                      │
│                                       │ Namespace              │ acm-workshop-464-tenant                              │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                                 │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                                    │                      │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                                         │ acm-workshop-464-tenant │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-tenant │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                                        │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-tenant-sa-wi-user                   │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-tenant                              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ network-admin-acm-workshop-464-tenant                │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-tenant                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com                       │ config-control       │
└───────────────────────────────────────┴────────────────────────┴───────────────────────────────────────────────────┴──────────────────────┘
```