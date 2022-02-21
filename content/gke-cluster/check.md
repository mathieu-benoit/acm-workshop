---
title: "Check"
weight: 5
---
- Duration: 2 min

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                           WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GKE Hub rights for GKE project                 ci        main    push   1872423084  1m2s     1d
✓       GKE rights for GKE project                     ci        main    push   1867720906  1m4s     2d
✓       Network admin role for GKE SA                  ci        main    push   1865477672  1m13s    3d
✓       GitOps for GKE project                         ci        main    push   1856916572  58s      4d
✓       GKE cluster namespace/project                  ci        main    push   1856812048  1m4s     4d
✓       Billing API in Config Controller project       ci        main    push   1856221804  56s      4d
✓       Initial commit                                 ci        main    push   1856056661  1m11s    4d
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GitOps for GKE cluster configs                            ci        main    push   1872389473  57s      1d
✓       GKE cluster, primary nodepool and SA for GKE project      ci        main    push   1867725616  1m0s     2d
✓       Network for GKE project                                   ci        main    push   1865498665  1m0s     3d
✓       Initial commit                                            ci        main    push   1856902085  1m3s     4d
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME               WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Initial commit     ci        main    push   1870893382  56s      1d
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1,status)')"
```
You should see:
```Plaintext
getting 2 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬─────────────────────────┬────────────────────────────────────────────────────┬───────────────────────┬──────────┐
│                 GROUP                 │           KIND          │                        NAME                        │       NAMESPACE       │   STATUS │
├───────────────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼───────────────────────┼──────────│
│                                       │ Namespace               │ default                                            │                       │ Current  │
│                                       │ Namespace               │ mabenoit-workshop-gke                              │                       │ Current  │
│                                       │ Namespace               │ config-control                                     │                       │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ service-account-admin-mabenoit-workshop-gke        │ config-control        │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ network-admin-mabenoit-workshop-gke                │ config-control        │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ container-admin-mabenoit-workshop-gke              │ config-control        │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ gke-hub-admin-mabenoit-workshop-gke                │ config-control        │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ iam-admin-mabenoit-workshop-gke                    │ config-control        │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount       │ mabenoit-workshop-gke                              │ config-control        │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ service-account-user-mabenoit-workshop-gke         │ config-control        │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy        │ mabenoit-workshop-gke-sa-workload-identity-binding │ config-control        │ Current  │
│ resourcemanager.cnrm.cloud.google.com │ Project                 │ mabenoit-workshop-gke                              │ config-control        │ Current  │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ gkehub.googleapis.com                              │ config-control        │ Current  │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ anthosconfigmanagement.googleapis.com              │ config-control        │ Current  │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ cloudbilling.googleapis.com                        │ config-control        │ Current  │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ container.googleapis.com                           │ config-control        │ Current  │
│ compute.cnrm.cloud.google.com         │ ComputeRouter           │ gke                                                │ mabenoit-workshop-gke │ Current  │
│ compute.cnrm.cloud.google.com         │ ComputeRouterNAT        │ gke                                                │ mabenoit-workshop-gke │ Current  │
│ compute.cnrm.cloud.google.com         │ ComputeSubnetwork       │ gke                                                │ mabenoit-workshop-gke │ Current  │
│ compute.cnrm.cloud.google.com         │ ComputeNetwork          │ gke                                                │ mabenoit-workshop-gke │ Current  │
│ configsync.gke.io                     │ RepoSync                │ repo-sync                                          │ mabenoit-workshop-gke │ Current  │
│ container.cnrm.cloud.google.com       │ ContainerCluster        │ gke                                                │ mabenoit-workshop-gke │ Current  │
│ container.cnrm.cloud.google.com       │ ContainerNodePool       │ primary                                            │ mabenoit-workshop-gke │ Current  │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext  │ configconnectorcontext.core.cnrm.cloud.google.com  │ mabenoit-workshop-gke │ Current  │
│ gkehub.cnrm.cloud.google.com          │ GKEHubFeature           │ gke-acm                                            │ mabenoit-workshop-gke │ Current  │
│ gkehub.cnrm.cloud.google.com          │ GKEHubFeatureMembership │ gke-acm-membership                                 │ mabenoit-workshop-gke │ Current  │
│ gkehub.cnrm.cloud.google.com          │ GKEHubMembership        │ gke-hub-membership                                 │ mabenoit-workshop-gke │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ metric-writer-gke                                  │ mabenoit-workshop-gke │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ monitoring-viewer-gke                              │ mabenoit-workshop-gke │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ log-writer-gke                                     │ mabenoit-workshop-gke │ Current  │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount       │ gke-primary-pool                                   │ mabenoit-workshop-gke │ Current  │
│ rbac.authorization.k8s.io             │ RoleBinding             │ syncs-repo                                         │ mabenoit-workshop-gke │ Current  │
└───────────────────────────────────────┴─────────────────────────┴────────────────────────────────────────────────────┴───────────────────────┴──────────┘
```