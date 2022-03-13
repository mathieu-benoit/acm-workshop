---
title: "Set up Config Controller's Git repo"
weight: 2
description: "Duration: 10 min | Persona: Org Admin"
---
_{{< param description >}}_

Define variables:
```Bash
source ~/acm-workshop-variables.sh
echo "export WORKSHOP_ORG_DIR_NAME=acm-workshop-org-repo" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

## Set up Cloud NAT

Open Config Controller's egress to the Internet (GitHub access):
```Bash
CONFIG_CONTROLLER_NETWORK=$(gcloud anthos config controller describe $CONFIG_CONTROLLER_NAME \
    --location=$CONFIG_CONTROLLER_LOCATION \
    --format='get(managementConfig.standardManagementConfig.network)')
CONFIG_CONTROLLER_NAT_ROUTER_NAME=nat-router
gcloud compute routers create $CONFIG_CONTROLLER_NAT_ROUTER_NAME \
    --network $CONFIG_CONTROLLER_NETWORK \
    --region $CONFIG_CONTROLLER_LOCATION
CONFIG_CONTROLLER_NAT_CONFIG_NAME=nat-config
gcloud compute routers nats create $CONFIG_CONTROLLER_NAT_CONFIG_NAME \
    --router-region $CONFIG_CONTROLLER_LOCATION \
    --router $CONFIG_CONTROLLER_NAT_ROUTER_NAME \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

## Enable multi-repositories

Deploy the multi-repositories setup for the Config Controller's Config Management component:
```Bash
cat << EOF | kubectl apply -f -
apiVersion: configmanagement.gke.io/v1
kind: ConfigManagement
metadata:
  name: config-management
spec:
  enableMultiRepo: true
  policyController:
    enabled: true
    logDeniesEnabled: true
    referentialRulesEnabled: true
    templateLibraryInstalled: false
EOF
```
{{% notice info %}}
We explicitly set the Policy Controller's `templateLibraryInstalled` field to `false`. Throughout this workshop, we will create our own `ConstraintTemplate` resources when needed. It will have two main benefits: first you will learn about how to create your own `ConstraintTemplate` (with OPA rego) and second, you we will be able to validate our Kubernetes resources against this . But be aware of this [default library of `ConstraintTemplate` resources](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library) you could leverage as-is if you set this field to `true`.
{{% /notice %}}

Let's wait for the multi-repositories configs to be deployed:
```Bash
kubectl wait --for condition=established crd rootsyncs.configsync.gke.io
```

## Define the primary Git repository

Create a dedicated GitHub repository to store any Kubernetes manifests associated to the GCP Organization:
```Bash
gh repo create $WORKSHOP_ORG_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ~/$WORKSHOP_ORG_DIR_NAME
git pull
git checkout main
ORG_REPO_URL=$(gh repo view --json url --jq .url)
```

Deploy a `RootSync` linking this GitHub repository to the Config Controller instance as the main/root GitOps configuration:
```Bash
cat << EOF | kubectl apply -f -
apiVersion: configsync.gke.io/v1beta1
kind: RootSync
metadata:
  name: root-sync
  namespace: config-management-system
spec:
  sourceFormat: unstructured
  git:
    repo: ${ORG_REPO_URL}
    revision: HEAD
    branch: main
    dir: config-sync
    auth: none
EOF
```
{{% notice info %}}
Since you started this workshop, you just ran 4 `kubectl` commands. For your information, moving forward you won't run any other `kubectl` commands because the design and intent of this workshop is to only deploy any Kubernetes resources via GitOps with Config Sync. You will also use some handy `gcloud` commands when appropriate.
{{% /notice %}}

## Define Cloud Billing API

In order to have Config Controller's Config Sync linking a Billing Account to GCP projects later in this workshop, we need to define the Cloud Billing API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for Config Controller's GCP project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/cloudbilling-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: cloudbilling.googleapis.com
  namespace: config-control
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Billing API in Config Controller project"
git push
```

## Check deployments

List the GCP resources created:
```Bash
gcloud compute routers list \
    --project $CONFIG_CONTROLLER_PROJECT_ID
gcloud compute routers nats list \
    --router $CONFIG_CONTROLLER_NAT_ROUTER_NAME \
    --region $CONFIG_CONTROLLER_LOCATION \
    --project $CONFIG_CONTROLLER_PROJECT_ID
```
```Plaintext
NAME        REGION    NETWORK
nat-router  us-east1  default
NAME        NAT_IP_ALLOCATE_OPTION  SOURCE_SUBNETWORK_IP_RANGES_TO_NAT
nat-config  AUTO_ONLY               ALL_SUBNETWORKS_ALL_IP_RANGES
```

List the GitHub runs for the Org configs repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Billing API in Config Controller project  ci        main    push   1960889246  1m0s     1m
✓       Initial commit                            ci        main    push   1960885850  1m8s     2m
```

List the Kubernetes resources managed by Config Sync in **Config Controller**:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
    --managed-resources all \
    --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌────────────────────────────────────┬───────────┬─────────────────────────────┬────────────────┐
│               GROUP                │    KIND   │             NAME            │   NAMESPACE    │
├────────────────────────────────────┼───────────┼─────────────────────────────┼────────────────┤
│                                    │ Namespace │ config-control              │                │
│ serviceusage.cnrm.cloud.google.com │ Service   │ cloudbilling.googleapis.com │ config-control │
└────────────────────────────────────┴───────────┴─────────────────────────────┴────────────────┘
```