---
title: "Create Config Controller"
weight: 1
---

- Persona: Org Admin
- Duration: 20 min
- Objectives:
  - FIXME

Create the Config Controller's GCP project:
```Bash
PREFIX=''
RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)
CONFIG_CONTROLLER_PROJECT_ID=${PREFIX}workshop-${RANDOM_SUFFIX}
BILLING_ACCOUNT_ID=FIXME
ORG_ID=FIXME
gcloud projects create $CONFIG_CONTROLLER_PROJECT_ID --organization $ORG_ID --name $CONFIG_CONTROLLER_PROJECT_ID
# FIXME - provide same way but with Folder Id.
gcloud beta billing projects link $CONFIG_CONTROLLER_PROJECT_ID --billing-account $BILLING_ACCOUNT_ID
gcloud config set project $CONFIG_CONTROLLER_PROJECT_ID
```

Create the Config Controller instance:
```Bash
gcloud services enable krmapihosting.googleapis.com \
    cloudresourcemanager.googleapis.com
CONFIG_CONTROLLER_NAME=configcontroller
CONFIG_CONTROLLER_LOCATION=us-east1
LOCAL_IP_ADDRESS=$(curl ifconfig.co)
gcloud anthos config controller create $CONFIG_CONTROLLER_NAME \
    --location=$CONFIG_CONTROLLER_LOCATION \
    --man-block $LOCAL_IP_ADDRESS/32
gcloud anthos config controller list \
    --location=$CONFIG_CONTROLLER_LOCATION
gcloud anthos config controller describe $CONFIG_CONTROLLER_NAME \
    --location=$CONFIG_CONTROLLER_LOCATION
```

Set the proper roles to the Config Controller's service account:
```
CONFIG_CONTROLLER_SA="$(kubectl get ConfigConnectorContext \
    -n config-control \
    -o jsonpath='{.items[0].spec.googleServiceAccount}')"
gcloud organizations add-iam-policy-binding ${ORG_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/resourcemanager.projectCreator'
gcloud organizations add-iam-policy-binding ${ORG_ID} \
    --member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    --role='roles/billing.projectManager'
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