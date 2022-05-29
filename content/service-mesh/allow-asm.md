---
title: "Allow ASM"
weight: 1
description: "Duration: 5 min | Persona: Org Admin"
tags: ["asm", "kcc", "org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Mesh API

Define the Mesh API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource in the Tenant project:
```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/projects/$TENANT_PROJECT_ID/mesh-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${TENANT_PROJECT_ID}
  name: ${TENANT_PROJECT_ID}-mesh
  namespace: config-control
spec:
  projectRef:
    name: ${TENANT_PROJECT_ID}
  resourceID: mesh.googleapis.com
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$HOST_PROJECT_DIR_NAME/
git add .
git commit -m "Allow ASM for Tenant project"
git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-->Project
  IAMPartialPolicy-->IAMServiceAccount
  ConfigConnectorContext-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  Service-->Project
  Service-->Project
  Service-->Project
{{< /mermaid >}}

List the GitHub runs for the **Host project configs** repository `cd ~/$HOST_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                         WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Allow ASM for Tenant project                 ci        main    push   1972159145  1m1s     4m
✓       Allow Artifact Registry for Tenant project   ci        main    push   1972065864  57s      43m
✓       Enforce policies for Tenant project          ci        main    push   1970984571  1m19s    6h
✓       Allow GKE Hub for Tenant project             ci        main    push   1970917868  1m8s     7h
✓       Allow Networking for Tenant project          ci        main    push   1970498686  1m18s    8h
✓       Allow GKE for Tenant project                 ci        main    push   1961343262  1m0s     1d
✓       Allow Networking for Tenant project          ci        main    push   1961279233  1m9s     1d
✓       Enforce policies for Tenant project          ci        main    push   1961276465  1m2s     1d
✓       GitOps for Tenant project                    ci        main    push   1961259400  1m7s     1d
✓       Setting up Tenant namespace/project          ci        main    push   1961160322  1m7s     1d
✓       Billing API in Host project                  ci        main    push   1961142326  1m12s    1d
✓       Initial commit                               ci        main    push   1961132028  1m2s     1d
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
│ constraints.gatekeeper.sh             │ LimitGKECluster        │ allowed-gke-cluster                               │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                                 │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                                    │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitgkecluster                                   │                      │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                                         │ acm-workshop-464-tenant │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-tenant │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                                        │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-tenant-sa-wi-user                   │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-user-acm-workshop-464-tenant         │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ iam-admin-acm-workshop-464-tenant                    │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-admin-acm-workshop-464-tenant        │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ artifactregistry-admin-acm-workshop-464-tenant       │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ gke-hub-admin-acm-workshop-464-tenant                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-tenant                              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ container-admin-acm-workshop-464-tenant              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ network-admin-acm-workshop-464-tenant                │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-tenant                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ gkehub.googleapis.com                             │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ mesh.googleapis.com                               │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ containeranalysis.googleapis.com                  │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ artifactregistry.googleapis.com                   │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ containerscanning.googleapis.com                  │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ container.googleapis.com                          │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ anthosconfigmanagement.googleapis.com             │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com                       │ config-control       │
└───────────────────────────────────────┴────────────────────────┴───────────────────────────────────────────────────┴──────────────────────┘
```