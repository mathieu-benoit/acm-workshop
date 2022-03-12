---
title: "Allow ASM"
weight: 1
description: "Duration: 5 min | Persona: Org Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define Mesh API

Define the Mesh API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource in the GKE project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/mesh-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: mesh.googleapis.com
  namespace: config-control
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Allow ASM for GKE project"
git push
```

## Check deployments

List the GCP resources created:
```Bash
gcloud services list \
    --project $GKE_PROJECT_ID
```
```Plaintext
NAME                                   TITLE
anthosconfigmanagement.googleapis.com  Anthos Config Management API
artifactregistry.googleapis.com        Artifact Registry API
autoscaling.googleapis.com             Cloud Autoscaling API
bigquery.googleapis.com                BigQuery API
bigquerymigration.googleapis.com       BigQuery Migration API
bigquerystorage.googleapis.com         BigQuery Storage API
compute.googleapis.com                 Compute Engine API
container.googleapis.com               Kubernetes Engine API
containeranalysis.googleapis.com       Container Analysis API
containerfilesystem.googleapis.com     Container File System API
containerregistry.googleapis.com       Container Registry API
containerscanning.googleapis.com       Container Scanning API
gkeconnect.googleapis.com              GKE Connect API
gkehub.googleapis.com                  GKE Hub API
iam.googleapis.com                     Identity and Access Management (IAM) API
iamcredentials.googleapis.com          IAM Service Account Credentials API
logging.googleapis.com                 Cloud Logging API
mesh.googleapis.com                    Mesh API
meshca.googleapis.com                  Anthos Service Mesh Certificate Authority API
meshconfig.googleapis.com              Mesh Configuration API
monitoring.googleapis.com              Cloud Monitoring API
multiclustermetering.googleapis.com    Multi cluster metering API
opsconfigmonitoring.googleapis.com     Config Monitoring for Ops API
oslogin.googleapis.com                 Cloud OS Login API
pubsub.googleapis.com                  Cloud Pub/Sub API
stackdriver.googleapis.com             Stackdriver API
storage-api.googleapis.com             Google Cloud Storage JSON API
```

List the GitHub runs for the **Org configs** repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Allow ASM for GKE project                 ci        main    push   1972159145  1m1s     4m
✓       Allow Artifact Registry for GKE project   ci        main    push   1972065864  57s      43m
✓       Enforce policies for GKE project          ci        main    push   1970984571  1m19s    6h
✓       Allow GKE Hub for GKE project             ci        main    push   1970917868  1m8s     7h
✓       Allow Networking for GKE project          ci        main    push   1970498686  1m18s    8h
✓       Allow GKE for GKE project                 ci        main    push   1961343262  1m0s     1d
✓       Allow Networking for GKE project          ci        main    push   1961279233  1m9s     1d
✓       Enforce policies for GKE project          ci        main    push   1961276465  1m2s     1d
✓       GitOps for GKE project                    ci        main    push   1961259400  1m7s     1d
✓       Setting up GKE namespace/project          ci        main    push   1961160322  1m7s     1d
✓       Billing API in Config Controller project  ci        main    push   1961142326  1m12s    1d
✓       Initial commit                            ci        main    push   1961132028  1m2s     1d
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
┌────────────────────────────────────────┬────────────────────────────┬───────────────────────────────────────────────────┬──────────────────────┐
│                 GROUP                  │            KIND            │                        NAME                       │      NAMESPACE       │
├────────────────────────────────────────┼────────────────────────────┼───────────────────────────────────────────────────┼──────────────────────┤
│                                        │ Namespace                  │ acm-workshop-464-gke                              │                      │
│                                        │ Namespace                  │ config-control                                    │                      │
│ constraints.gatekeeper.sh              │ LimitLocations             │ allowed-locations                                 │                      │
│ constraints.gatekeeper.sh              │ LimitGKECluster            │ allowed-gke-cluster                               │                      │
│ templates.gatekeeper.sh                │ ConstraintTemplate         │ limitlocations                                    │                      │
│ templates.gatekeeper.sh                │ ConstraintTemplate         │ limitgkecluster                                   │                      │
│ artifactregistry.cnrm.cloud.google.com │ ArtifactRegistryRepository │ containers                                        │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeSubnetwork          │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouter              │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeNetwork             │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com          │ ComputeRouterNAT           │ gke                                               │ acm-workshop-464-gke │
│ configsync.gke.io                      │ RepoSync                   │ repo-sync                                         │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerCluster           │ gke                                               │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com        │ ContainerNodePool          │ primary                                           │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com             │ ConfigConnectorContext     │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeatureMembership    │ gke-acm-membership                                │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubMembership           │ gke-hub-membership                                │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com           │ GKEHubFeature              │ gke-acm                                           │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ monitoring-viewer                                 │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ log-writer                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ gke-primary-pool                                  │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ gke-primary-pool-sa-cs-monitoring-wi-user         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ metric-writer                                     │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-reader                           │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io              │ RoleBinding                │ syncs-repo                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ service-account-admin-acm-workshop-464-gke        │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ artifactregistry-admin-acm-workshop-464-gke       │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ gke-hub-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMServiceAccount          │ acm-workshop-464-gke                              │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMPartialPolicy           │ acm-workshop-464-gke-sa-wi-user                   │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ container-admin-acm-workshop-464-gke              │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ iam-admin-acm-workshop-464-gke                    │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ network-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com              │ IAMPolicyMember            │ service-account-user-acm-workshop-464-gke         │ config-control       │
│ resourcemanager.cnrm.cloud.google.com  │ Project                    │ acm-workshop-464-gke                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ gkehub.googleapis.com                             │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ mesh.googleapis.com                               │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ anthosconfigmanagement.googleapis.com             │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ artifactregistry.googleapis.com                   │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ container.googleapis.com                          │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ cloudbilling.googleapis.com                       │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ containeranalysis.googleapis.com                  │ config-control       │
│ serviceusage.cnrm.cloud.google.com     │ Service                    │ containerscanning.googleapis.com                  │ config-control       │
└────────────────────────────────────────┴────────────────────────────┴───────────────────────────────────────────────────┴──────────────────────┘
```