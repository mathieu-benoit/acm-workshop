---
title: "Before you begin"
weight: 3
---
Before you begin you need to make sure you have the prerequisites in place.

You can run this workshop on Cloud Shell or on your local machine running Linux. Cloud Shell pre-installs all the required tools.

Create a working directory where you will drop all the files needed for this workshop.
```Bash
export WORKING_DIRECTORY=asm-workshop
mkdir $WORKING_DIRECTORY
cd $WORKING_DIRECTORY
```

Install the required tools:
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- `istioctl`
- [`nomos`](https://cloud.google.com/anthos-config-management/docs/how-to/nomos-command#installing)
- `curl`

Get the _Folder Id_ and _Billing Account Id_ you will use to create your GCP project:
```Bash
FOLDER_ID=FIXME
gcloud beta billing accounts list
BILLING_ACCOUNT_ID=FIXME
```

Create a dedicated GCP project for this workshop:
```Bash
export PROJECT_NAME=asm-workshop
RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)
export PROJECT_ID=$PROJECT_NAME-$RANDOM_SUFFIX
gcloud projects create $PROJECT_ID \
    --folder $FOLDER_ID \
    --name $PROJECT_NAME
gcloud config set project $PROJECT_ID
gcloud beta billing projects link $PROJECT_ID \
    --billing-account $BILLING_ACCOUNT_ID
export PROJECT_NUMBER==$(gcloud projects describe $PROJECT_ID --format='get(projectNumber)')
```

Enable the Google Cloud APIs required:
```Bash
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable anthos.googleapis.com
```

Set the region and zone in which you want to deploy your GCP services:
```Bash
export REGION=us-east4
export ZONE=us-east4-a
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
```