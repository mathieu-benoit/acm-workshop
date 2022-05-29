---
title: "Create Host project"
weight: 1
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will create the Host project. This Google Cloud project will host the Config Controller instance later.

Define variables:
```Bash
WORK_DIR=~/
touch ${WORK_DIR}acm-workshop-variables.sh
chmod +x ${WORK_DIR}acm-workshop-variables.sh
RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)
BILLING_ACCOUNT_ID=FIXME
ORG_OR_FOLDER_ID=FIXME
echo "export RANDOM_SUFFIX=${RANDOM_SUFFIX}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export HOST_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ORG_OR_FOLDER_ID=${ORG_OR_FOLDER_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create Host project

Create the Config Controller's GCP project either at the Folder level or the Organization level:
{{< tabs groupId="org-level">}}
{{% tab name="Folder level" %}}
Create this resource at a Folder level:
```Bash
gcloud projects create $HOST_PROJECT_ID \
    --folder $ORG_OR_FOLDER_ID \
    --name $HOST_PROJECT_ID
```
{{% /tab %}}
{{% tab name="Org level" %}}
Alternatively, you could also create this resource at the Organization level:
```Bash
gcloud projects create $HOST_PROJECT_ID \
    --organization $ORG_OR_FOLDER_ID \
    --name $HOST_PROJECT_ID
```
{{% /tab %}}
{{< /tabs >}}

Set the Billing account on this GCP project: 
```Bash
gcloud beta billing projects link $HOST_PROJECT_ID \
    --billing-account $BILLING_ACCOUNT_ID
```

Set this project as the default project for following `gcloud` commands:
```Bash
gcloud config set project $HOST_PROJECT_ID
```

## Check deployments

List the GCP resources created:
```Bash
gcloud projects describe $HOST_PROJECT_ID
```