---
title: "Set up Host project's Git repo"
weight: 3
description: "Duration: 10 min | Persona: Org Admin"
tags: ["kcc", "org-admin", "security-tips"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will set up the primary Git repository of the Config Controller instance in order to have in place a GitOps approach to deploy your infrastructure in Google Cloud. You will also configure a Cloud NAT to this Config Controller instance to give it access to the Internet (GitHub repositories) in Egress. Finally, you will enable the `cloudbilling` API in the Host project, which will allow the assignment of the Billing Account Id to any Google Cloud project Config Controller will create.


Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export HOST_PROJECT_DIR_NAME=acm-workshop-org-repo" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Set up Cloud NAT

Open Config Controller's egress to the Internet (GitHub access):
```Bash
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
    templateLibraryInstalled: true
EOF
```
{{% notice info %}}
We explicitly set the Policy Controller's `templateLibraryInstalled` field to `true`, in order to install the [default library of `ConstraintTemplates`](https://cloud.google.com/anthos-config-management/docs/reference/constraint-template-library).
{{% /notice %}}

Let's wait for the multi-repositories configs to be deployed:
```Bash
kubectl wait --for condition=established crd rootsyncs.configsync.gke.io
```

## Define the Host project's Git repository

Create a dedicated private GitHub repository to store any Kubernetes manifests associated to the Host project:
```Bash
cd ${WORK_DIR}
gh auth login
gh repo create $HOST_PROJECT_DIR_NAME --private --clone --template https://github.com/mathieu-benoit/config-sync-template-repo
cd $HOST_PROJECT_DIR_NAME
git pull
git checkout main
ORG_REPO_URL=$(gh repo view --json sshUrl --jq .sshUrl)
ORG_REPO_NAME_WITH_OWNER=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
```

Generate [SSH key pair](https://cloud.google.com/anthos-config-management/docs/how-to/installing-config-sync#ssh-key-pair) in order to get a read access to the private Git repository:
```Bash
mkdir tmp
ssh-keygen -t rsa -b 4096 \
    -C "${ORG_REPO_NAME_WITH_OWNER}@github" \
    -N '' \
    -f ./tmp/github-org-repo
kubectl create secret generic git-creds \
    -n config-management-system \
    --from-file ssh=./tmp/github-org-repo
gh repo deploy-key add ./tmp/github-org-repo.pub
rm -r tmp
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
    dir: .
    auth: ssh
    secretRef:
      name: git-creds
EOF
```
{{% notice tip %}}
The GitHub repository is private in order to demonstrate how to allow read access to Config Sync when you use a private Git repository. 
{{% /notice %}}

Since you started this workshop, you just ran 6 `kubectl` commands. For your information, moving forward you won't run any other `kubectl` commands because the design and intent of this workshop is to only deploy any Kubernetes resources via GitOps with Config Sync. You will also use some handy `gcloud` commands when appropriate.

## Define API

In order to have Config Controller's Config Sync linking a Billing Account to GCP projects later in this workshop, we need to define the Cloud Billing API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for Config Controller's GCP project:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/cloudbilling-service.yaml
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
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Billing API in Host project" && git push origin main
```
{{% notice info %}}
Because it's the first `git commit` of this workshop, if you don't have your own environment set up with `git`, you may be prompted to properly set up `git config --global user.email "you@example.com"` and `git config --global user.name "Your Name"`.
{{% /notice %}}

## Check deployments

List the GitHub runs for the **Host project configs** repository:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME && gh run list
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RootSync`. All the `managed_resources` listed should have `STATUS: Current` as well.