---
title: "Create Config Controller"
weight: 2
description: "Duration: 20 min | Persona: Org Admin"
tags: ["org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will create your Config Controller instance. You will also add the least privilege Google Cloud roles to its associated service account. This Config Controller instance will allow throughout this workshop to deploy any infrastructure via Kubernetes manifests.

Define variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_NAME=configcontroller" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_LOCATION=us-east1" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_NETWORK=default" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice info %}}
We are creating the Config Controller instance in `us-east1` but other regions are also supported: `europe-north1`, `europe-west1`, `europe-west3`, `australia-southeast1`, `australia-southeast2`, `us-central1`, `northamerica-northeast1`, `northamerica-northeast2`, `asia-northeast1` and `asia-northeast2`.
{{% /notice %}}

## Create the Config Controller instance

If you don't have a default network in your project, create one by running the following command:
```Bash
gcloud compute networks create $CONFIG_CONTROLLER_NETWORK \
    --subnet-mode=auto
```

Enable the required Google Cloud APIs:
```Bash
gcloud services enable krmapihosting.googleapis.com \
    cloudresourcemanager.googleapis.com
```

Create the Config Controller instance:
```Bash
gcloud anthos config controller create $CONFIG_CONTROLLER_NAME \
    --location $CONFIG_CONTROLLER_LOCATION \
    --network $CONFIG_CONTROLLER_NETWORK
```
{{% notice tip %}}
As a security best practice you could provision your Config Controller instance with the `--man-block $(curl -4 ifconfig.co)/32` parameter. We are not doing this in this workshop to avoid any issues with Cloud Shell which is allocating a new IP address as soon as the session expired.
{{% /notice %}}
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

Set the `resourcemanager.projectCreator` role either at the Folder level or the Organization level:
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
Create this resource at a Folder level:
```Bash
gcloud resource-manager folders add-iam-policy-binding ${FOLDER_OR_ORG_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/resourcemanager.projectCreator'
```
{{% /tab %}}
{{% tab name="Org level" %}}
Alternatively, you could also create this resource at the Organization level:
```Bash
gcloud organizations add-iam-policy-binding ${FOLDER_OR_ORG_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/resourcemanager.projectCreator'
```
{{% /tab %}}
{{< /tabs >}}

Set the `serviceusage.serviceUsageAdmin` and `iam.serviceAccountAdmin` roles:
```Bash
gcloud projects add-iam-policy-binding ${HOST_PROJECT_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/serviceusage.serviceUsageAdmin'
gcloud projects add-iam-policy-binding ${HOST_PROJECT_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/iam.serviceAccountAdmin'
```

Finally, you need to assign the `billing.user` role too. Later in this workshop, it will be needed to attach a `Project` to a Billing Account. If you don't have the proper role you may have an error by running the command below. In this case you need to ask your Billing Account or Organization admins in order to run this command for you.
```Bash
gcloud beta billing accounts add-iam-policy-binding ${BILLING_ACCOUNT_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/billing.user'
```
{{% notice note %}}
In some specific scenario, you may not be able to accomplish this step. You could skip it for now, another way to assign the Billing Account to a `Project` will be provided later in this workshop, when you will need it.
{{% /notice %}}

## Check deployments

List the Google Cloud resources created:
```Bash
gcloud anthos config controller list \
    --project $HOST_PROJECT_ID
gcloud beta billing accounts get-iam-policy ${BILLING_ACCOUNT_ID} \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
gcloud projects get-iam-policy $HOST_PROJECT_ID \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
```Bash
gcloud resource-manager folders get-iam-policy $FOLDER_OR_ORG_ID \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
{{% /tab %}}
{{% tab name="Org level" %}}
```Bash
gcloud organizations get-iam-policy $FOLDER_OR_ORG_ID \
    --filter="bindings.members:${CONFIG_CONTROLLER_SA}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
{{% /tab %}}
{{< /tabs >}}