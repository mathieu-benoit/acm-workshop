---
title: "Set up Config Controller's Git repo"
weight: 2
---
- Persona: Org Admin
- Duration: 5 min
- Objectives:
  - Set up a Cloud NAT in order to provide Internet access in egress for the Config Controller instance
  - Enable multi-repositories for the Config Controller's Config Sync component
  - Create a dedicated Organization GitHub repository as the main/root repository of the Config Controller instance
  - Enable Cloud Billing service API in the Config Controller's GCP project

Define variables:
```Bash
echo "export WORKSHOP_ORG_DIR_NAME=acm-workshop-org-repo" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

Open Config Controller's egress to the Internet (GitHub access):
```Bash
CONFIG_CONTROLLER_NETWORK=$(gcloud anthos config controller describe $CONFIG_CONTROLLER_NAME \
    --location=$CONFIG_CONTROLLER_LOCATION \
    --format='get(network)')
gcloud compute routers create nat-router \
    --network $CONFIG_CONTROLLER_NETWORK \
    --region $CONFIG_CONTROLLER_LOCATION
gcloud compute routers nats create nat-config \
    --router-region $CONFIG_CONTROLLER_LOCATION \
    --router nat-router \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
```

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

Create a dedicated GitHub repository to store any Kubernetes manifests associated to the GCP Organization:
```Bash
gh repo create $WORKSHOP_ORG_DIR_NAME --public --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd ~/$WORKSHOP_ORG_DIR_NAME
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

Define the Cloud Billing API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource:
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