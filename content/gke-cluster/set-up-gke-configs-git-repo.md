---
title: "Set up GKE configs's Git repo"
weight: 4
description: "Duration: 10 min | Persona: Platform Admin"
---
_{{< param description >}}_

Define variables:
```Bash
echo "export GKE_CONFIGS_DIR_NAME=acm-workshop-gke-configs-repo" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Define ACM GKEHubFeature

Define the ACM [`GKEHubFeature`](https://cloud.google.com/config-connector/docs/reference/resource-docs/gkehub/gkehubfeature) resource:
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-hub-feature-acm.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeature
metadata:
  name: ${GKE_NAME}-acm
  namespace: ${GKE_PROJECT_ID}
spec:
  projectRef:
    external: ${GKE_PROJECT_ID}
  location: global
  resourceID: configmanagement
EOF
```
{{% notice note %}}
The `resourceID` must be `configmanagement` if you want to use Anthos Config Management feature.
{{% /notice %}}

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-hub-membership.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubMembership
metadata:
  name: ${GKE_NAME}-hub-membership
  namespace: ${GKE_PROJECT_ID}
spec:
  location: global
  authority:
    issuer: https://container.googleapis.com/v1/projects/${GKE_PROJECT_ID}/locations/${GKE_LOCATION}/clusters/${GKE_NAME}
  endpoint:
    gkeCluster:
      resourceRef:
        name: ${GKE_NAME}
EOF
```

## Create a main GitHub repository for all GKE configs

Create a dedicated GitHub repository where we will commit all the configs, policies, etc. we want to deploy in this GKE cluster:
```Bash
gh repo create $GKE_CONFIGS_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ~/$GKE_CONFIGS_DIR_NAME
git pull
git checkout main
GKE_CONFIGS_REPO_URL=$(gh repo view --json url --jq .url)
```

## Define RootSync with this GitHub repository 

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/gke-acm-membership.yaml
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeatureMembership
metadata:
  name: ${GKE_NAME}-acm-membership
  namespace: ${GKE_PROJECT_ID}
spec:
  projectRef:
    external: ${GKE_PROJECT_ID}
  location: global
  membershipRef:
    name: ${GKE_NAME}-hub-membership
  featureRef:
    name: ${GKE_NAME}-acm
  configmanagement:
    configSync:
      sourceFormat: unstructured
      git:
        policyDir: config-sync
        secretType: none
        syncBranch: main
        syncRepo: ${GKE_CONFIGS_REPO_URL}
    policyController:
      enabled: true
      referentialRulesEnabled: true
      logDeniesEnabled: true
      templateLibraryInstalled: false
    version: "1.10.2"
EOF
```
{{% notice tip %}}
We explicitly set the Config Management's `version` field with the current version. It's a best practice to do this, as you are responsible to manually upgrade this component as [new versions are coming](https://cloud.google.com/anthos-config-management/docs/release-notes). So you will be able to update this file accordingly in order to trigger the upgrade of Config Management with the new version.
{{% /notice %}}

{{% notice info %}}
We explicitly set the Policy Controller's `templateLibraryInstalled` field to `false`. Throughout this workshop, we will create our own `ConstraintTemplate` resources when needed. It will have two main benefits: first you will learn about how to create your own `ConstraintTemplate` (with OPA rego) and second, you we will be able to validate our Kubernetes resources against this . But be aware of this [default library of `ConstraintTemplate` resources](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library) you could leverage as-is if you set this field to `true`.
{{% /notice %}}

## Define Config Sync Monitoring

https://cloud.google.com/anthos-config-management/docs/how-to/monitoring-multi-repo

```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/config-sync-monitoring-workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: ${GKE_SA}-sa-cs-monitoring-wi-user
  namespace: ${GKE_PROJECT_ID}
spec:
  resourceRef:
    name: ${GKE_SA}
    apiVersion: iam.cnrm.cloud.google.com/v1beta1
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${GKE_PROJECT_ID}.svc.id.goog[config-management-monitoring/default]
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "GitOps for GKE cluster configs"
git push
```

## Check deployments

Here is what you should have at this stage:

List the GitHub runs for the **GKE project configs** repository `cd ~/$GKE_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GitOps for GKE cluster configs                        ci        main    push   1970974465  53s      13m
✓       GKE cluster, primary nodepool and SA for GKE project  ci        main    push   1963473275  1m16s    1d
✓       Network for GKE project                               ci        main    push   1961289819  1m13s    1d
✓       Initial commit                                        ci        main    push   1961170391  56s      1d
```

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME            WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Initial commit  ci        main    push   1970951731  57s      28m
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
┌───────────────────────────────────────┬─────────────────────────┬───────────────────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │           KIND          │                        NAME                       │      NAMESPACE       │
├───────────────────────────────────────┼─────────────────────────┼───────────────────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace               │ acm-workshop-464-gke                              │                      │
│                                       │ Namespace               │ config-control                                    │                      │
│ constraints.gatekeeper.sh             │ LimitLocations          │ allowed-locations                                 │                      │
│ constraints.gatekeeper.sh             │ LimitGKECluster         │ allowed-gke-cluster                               │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate      │ limitlocations                                    │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate      │ limitgkecluster                                   │                      │
│ compute.cnrm.cloud.google.com         │ ComputeNetwork          │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeRouter           │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeSubnetwork       │ gke                                               │ acm-workshop-464-gke │
│ compute.cnrm.cloud.google.com         │ ComputeRouterNAT        │ gke                                               │ acm-workshop-464-gke │
│ configsync.gke.io                     │ RepoSync                │ repo-sync                                         │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com       │ ContainerCluster        │ gke                                               │ acm-workshop-464-gke │
│ container.cnrm.cloud.google.com       │ ContainerNodePool       │ primary                                           │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext  │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com          │ GKEHubMembership        │ gke-hub-membership                                │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com          │ GKEHubFeature           │ gke-acm                                           │ acm-workshop-464-gke │
│ gkehub.cnrm.cloud.google.com          │ GKEHubFeatureMembership │ gke-acm-membership                                │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ metric-writer                                     │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount       │ gke-primary-pool                                  │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy        │ gke-primary-pool-sa-cs-monitoring-wi-user         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ monitoring-viewer                                 │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ log-writer                                        │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io             │ RoleBinding             │ syncs-repo                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount       │ acm-workshop-464-gke                              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ gke-hub-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ iam-admin-acm-workshop-464-gke                    │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ service-account-admin-acm-workshop-464-gke        │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ service-account-user-acm-workshop-464-gke         │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ network-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy        │ acm-workshop-464-gke-sa-wi-user                   │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ container-admin-acm-workshop-464-gke              │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                 │ acm-workshop-464-gke                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ cloudbilling.googleapis.com                       │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ anthosconfigmanagement.googleapis.com             │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ container.googleapis.com                          │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ gkehub.googleapis.com                             │ config-control       │
└───────────────────────────────────────┴─────────────────────────┴───────────────────────────────────────────────────┴──────────────────────┘
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster**:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
```Plaintext
FIXME
```