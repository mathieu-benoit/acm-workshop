---
title: "Create Config Controller"
weight: 1
description: "Duration: 20 min | Persona: Org Admin"
---
_{{< param description >}}_

Define variables:
```Bash
WORK_DIR=~/
touch ${WORK_DIR}acm-workshop-variables.sh
chmod +x ${WORK_DIR}acm-workshop-variables.sh
RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)
BILLING_ACCOUNT_ID=FIXME
ORG_OR_FOLDER_ID=FIXME
echo "export RANDOM_SUFFIX=${RANDOM_SUFFIX}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ORG_OR_FOLDER_ID=${ORG_OR_FOLDER_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export LOCAL_IP_ADDRESS=$(curl -4 ifconfig.co)" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_NAME=configcontroller" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_LOCATION=us-east1" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_NETWORK=default" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice info %}}
Just `us-east1`, `us-central1` and `northamerica-northeast1` are the supported regions for now for Config Controller.
{{% /notice %}}

## Create Config Controller's GCP project

Create the Config Controller's GCP project:
{{< tabs groupId="org-level">}}
{{% tab name="Org level" %}}
Create this GCP project at the Organization level:
```Bash
gcloud projects create $CONFIG_CONTROLLER_PROJECT_ID \
    --organization $ORG_OR_FOLDER_ID \
    --name $CONFIG_CONTROLLER_PROJECT_ID
```
{{% /tab %}}
{{% tab name="Folder level" %}}
Alternatively, you could also create this GCP project at a Folder level:
```Bash
gcloud projects create $CONFIG_CONTROLLER_PROJECT_ID \
    --folder $ORG_OR_FOLDER_ID \
    --name $CONFIG_CONTROLLER_PROJECT_ID
```
{{% /tab %}}
{{< /tabs >}}

Set the Billing account on this GCP project: 
```
gcloud beta billing projects link $CONFIG_CONTROLLER_PROJECT_ID \
    --billing-account $BILLING_ACCOUNT_ID
```

Set this project as the default project for following `gcloud` commands:
```
gcloud config set project $CONFIG_CONTROLLER_PROJECT_ID
```

## Create the Config Controller instance

If you don't have a default network in your project, create one by running the following command:
```Bash
gcloud compute networks create $CONFIG_CONTROLLER_NETWORK \
    --subnet-mode=auto
```

Create the Config Controller instance:
```Bash
gcloud services enable krmapihosting.googleapis.com \
    cloudresourcemanager.googleapis.com
gcloud anthos config controller create $CONFIG_CONTROLLER_NAME \
    --location $CONFIG_CONTROLLER_LOCATION \
    --network $CONFIG_CONTROLLER_NETWORK \
    --man-block $LOCAL_IP_ADDRESS/32
```
{{% notice note %}}
The Config Controller instance provisioning could take around 15-20 min.
{{% /notice %}}

Check that the Config Controller instance was successfully created:
```Bash
gcloud anthos config controller list \
    --location $CONFIG_CONTROLLER_LOCATION
gcloud anthos config controller describe $CONFIG_CONTROLLER_NAME \
    --location $CONFIG_CONTROLLER_LOCATION
```

## Get the Config Controller instance credentials

```Bash
gcloud anthos config controller get-credentials $CONFIG_CONTROLLER_NAME \
    --location $CONFIG_CONTROLLER_LOCATION
```

## Set Config Controller's service account roles

Get the actual the Config Controller's service account:
```Bash
CONFIG_CONTROLLER_SA="$(kubectl get ConfigConnectorContext \
    -n config-control \
    -o jsonpath='{.items[0].spec.googleServiceAccount}')"
```

Set the `resourcemanager.projectCreator` role:
{{< tabs groupId="org-level">}}
{{% tab name="Org level" %}}
Create this GCP project at the Organization level:
```Bash
gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/resourcemanager.projectCreator'
```
{{% /tab %}}
{{% tab name="Folder level" %}}
Alternatively, you could also create this GCP project at a Folder level:
```Bash
gcloud resource-manager folders add-iam-policy-binding ${ORG_OR_FOLDER_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/resourcemanager.projectCreator'
```
{{% /tab %}}
{{< /tabs >}}

Set the `billing.user`, `serviceusage.serviceUsageAdmin` and `iam.serviceAccountAdmin` roles:
```Bash
gcloud beta billing accounts add-iam-policy-binding ${BILLING_ACCOUNT_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/billing.user'
gcloud projects add-iam-policy-binding ${CONFIG_CONTROLLER_PROJECT_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/serviceusage.serviceUsageAdmin'
gcloud projects add-iam-policy-binding ${CONFIG_CONTROLLER_PROJECT_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/iam.serviceAccountAdmin'
```

## Check deployments

List the GCP resources created:
```Bash
gcloud projects describe $CONFIG_CONTROLLER_PROJECT_ID
gcloud anthos config controller list \
    --project $CONFIG_CONTROLLER_PROJECT_ID
gcloud organizations get-iam-policy $ORG_OR_FOLDER_ID \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud beta billing accounts get-iam-policy ${BILLING_ACCOUNT_ID} \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud projects get-iam-policy $CONFIG_CONTROLLER_PROJECT_ID \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
```Plaintext
NAME                                                                       LOCATION  STATE
projects/acm-workshop-463/locations/us-east1/krmApiHosts/configcontroller  us-east1  RUNNING
ROLE
roles/resourcemanager.projectCreator
ROLE
roles/billing.user
ROLE
roles/iam.serviceAccountAdmin
roles/serviceusage.serviceUsageAdmin
```