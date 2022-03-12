---
title: "Allow GKE Hub"
weight: 3
description: "Duration: 5 min | Persona: Org Admin"
---
_{{< param description >}}_

Define variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define GKE Hub admin role

Define the `gkehub.admin` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the GKE project's service account:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/gke-hub-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: gke-hub-admin-${GKE_PROJECT_ID}
  namespace: config-control
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_PROJECT_ID}
  role: roles/gkehub.admin
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
```

## Define GKE and GKE Hub APIs

Define the GKE and GKE Hub APIs [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resources for the GKE project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/gke-hub-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: gkehub.googleapis.com
  namespace: config-control
EOF
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/anthos-configmanagement-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: anthosconfigmanagement.googleapis.com
  namespace: config-control
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Allow GKE Hub for GKE project"
git push
```

## Check deployments

List the GCP resources created:
```Bash
gcloud projects get-iam-policy $GKE_PROJECT_ID \
    --filter="bindings.members:${GKE_PROJECT_SA_EMAIL}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
```Plaintext
ROLE
roles/compute.networkAdmin
roles/container.admin
roles/gkehub.admin
roles/iam.serviceAccountAdmin
roles/iam.serviceAccountUser
roles/resourcemanager.projectIamAdmin
```

List the GitHub runs for the **Org configs** repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Allow GKE Hub for GKE project             ci        main    push   1970917868  1m8s     4m
✓       Allow GKE for GKE project                 ci        main    push   1961343262  1m0s     1d
✓       Allow Networking for GKE project          ci        main    push   1961279233  1m9s     1d
✓       Enforce policies for GKE project          ci        main    push   1961276465  1m2s     1d
✓       GitOps for GKE project                    ci        main    push   1961259400  1m7s     1d
✓       Setting up GKE namespace/project          ci        main    push   1961160322  1m7s     1d
✓       Billing API in Config Controller project  ci        main    push   1961142326  1m12s    1d
✓       Initial commit                            ci        main    push   1961132028  1m2s     1d
```

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GKE cluster, primary nodepool and SA for GKE project  ci        main    push   1963473275  1m16s    11h
✓       Network for GKE project                               ci        main    push   1961289819  1m13s    20h
✓       Initial commit                                        ci        main    push   1961170391  56s      20h
```

List the Kubernetes resources managed by Config Sync in **Config Controller**:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
    --managed-resources all \
    --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
```Plaintext
getting 2 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬───────────────────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                        NAME                       │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ acm-workshop-464-gke                              │                      │
│                                       │ Namespace              │ config-control                                    │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                                 │                      │
│ constraints.gatekeeper.sh             │ LimitGKECluster        │ allowed-gke-cluster                               │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                                    │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitgkecluster                                   │                      │
│ compute.cnrm.cloud.google.com         │ ComputeSubnetwork      │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeRouterNAT       │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeRouter          │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeNetwork         │ gke                                               │ acm-workshop-464-gke │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                                         │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com       │ ContainerCluster       │ gke                                               │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com       │ ContainerNodePool      │ primary                                           │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ log-writer                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ metric-writer                                     │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ monitoring-viewer                                 │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ gke-primary-pool                                  │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-gke                              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ gke-hub-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ iam-admin-acm-workshop-464-gke                    │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-admin-acm-workshop-464-gke        │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-user-acm-workshop-464-gke         │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ network-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-gke-sa-wi-user                   │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ container-admin-acm-workshop-464-gke              │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-gke                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com                       │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ anthosconfigmanagement.googleapis.com             │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ container.googleapis.com                          │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ gkehub.googleapis.com                             │ config-control       │
└───────────────────────────────────────┴────────────────────────┴───────────────────────────────────────────────────┴──────────────────────┘
```