---
title: "Create Config Controller"
weight: 1
---
- Persona: Org Admin
- Duration: 20 min

Define variables:
```Bash
RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)
BILLING_ACCOUNT_ID=FIXME
ORG_OR_FOLDER_ID=FIXME
echo "export RANDOM_SUFFIX=${RANDOM_SUFFIX}" >> ~/acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}" >> ~/acm-workshop-variables.sh
echo "export BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}" >> ~/acm-workshop-variables.sh
echo "export ORG_OR_FOLDER_ID=${ORG_OR_FOLDER_ID}" >> ~/acm-workshop-variables.sh
echo "export LOCAL_IP_ADDRESS=$(curl ifconfig.co)" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

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

Create the Config Controller instance:
```Bash
gcloud services enable krmapihosting.googleapis.com \
    cloudresourcemanager.googleapis.com
CONFIG_CONTROLLER_NAME=configcontroller
CONFIG_CONTROLLER_LOCATION=us-east1 # or us-central1 are supported for now
gcloud anthos config controller create $CONFIG_CONTROLLER_NAME \
    --location=$CONFIG_CONTROLLER_LOCATION \
    --man-block $LOCAL_IP_ADDRESS/32
gcloud anthos config controller list \
    --location=$CONFIG_CONTROLLER_LOCATION
gcloud anthos config controller describe $CONFIG_CONTROLLER_NAME \
    --location=$CONFIG_CONTROLLER_LOCATION
```
{{% notice note %}}
The Config Controller instance provisioning could take around 15-20 min.
{{% /notice %}}

## Set Config Controller's service account roles

Get the actual the Config Controller's service account:
```Bash
CONFIG_CONTROLLER_SA="$(kubectl get ConfigConnectorContext \
    -n config-control \
    -o jsonpath='{.items[0].spec.googleServiceAccount}')"
```

Set the `resourcemanager.projectCreator` and `roles/billing.projectManager` roles:
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