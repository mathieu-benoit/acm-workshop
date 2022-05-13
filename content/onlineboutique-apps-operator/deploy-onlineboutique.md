---
title: "Deploy Online Boutique apps"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy your Online Boutique apps using Kustomize.

Initialize variables:
```Bash
WORK_DIR=~/
touch ${WORK_DIR}acm-workshop-variables.sh
chmod +x ${WORK_DIR}acm-workshop-variables.sh
GKE_PROJECT_ID=acm-workshop-464-gke
echo "export GKE_PROJECT_ID=${GKE_PROJECT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
ONLINEBOUTIQUE_NAMESPACE=ob-team1
echo "export ONLINEBOUTIQUE_NAMESPACE=${ONLINEBOUTIQUE_NAMESPACE}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_DIR_NAME=acm-workshop-${ONLINEBOUTIQUE_NAMESPACE}-repo" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME='${ONLINEBOUTIQUE_NAMESPACE}.endpoints.${GKE_PROJECT_ID}.cloud.goog'" >> ${WORK_DIR}acm-workshop-variables.sh
echo "gcloud config set accessibility/screen_reader false" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

A GitHub repository already exists where all the Kubernetes manifests to deploy Online Boutique apps are stored. It was created in a previous section by the Platform Admin. 

First thing first, you need to ask your Platform Admin to grant you access as Contributor/Editor to this Online Boutique GitHub repo.

Then, you are cloning this repo in order to add the Online Boutique manifests:
```Bash
cd ~
git clone https://github.com/FIXME/$ONLINEBOUTIQUE_NAMESPACE
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME
mkdir upstream
cd upstream
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/base@main
```

## Create base overlay

Create Kustomize base overlay files:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME
mkdir base
cd base
kustomize create --resources ../upstream/base/all
cat <<EOF >> kustomization.yaml
patchesStrategicMerge:
- |-
  apiVersion: v1
  kind: Namespace
  metadata:
    name: onlineboutique
  \$patch: delete
EOF
```
{{% notice info %}}
Here, we are removing the upstream `Namespace` resource as we already defined it in a previous section while configuring the associated Config Sync's `RepoSync` setup.
{{% /notice %}}

You could browse the files in the `~/$ONLINE_BOUTIQUE_DIR_NAME/upstream/base` folder, along with the `Namespace`, `Deployment` and `Service` resources for the OnlineBoutique apps, you could see the  `VirtualService` resource which will allow to establish the Ingress Gateway routing to the OnlineBoutique app. The `spec.hosts` value is `"*"` but in the following part you will replace this value by the actual DNS of the OnlineBoutique solution (i.e. `ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME`) defined in a previous section.

## Define Staging namespace overlay

You need first to grab the Memorystore (redis) connection information:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(port)')
echo $REDIS_IP
echo $REDIS_PORT
echo "export REDIS_IP=${REDIS_IP}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export REDIS_PORT=${REDIS_PORT}" >> ${WORK_DIR}acm-workshop-variables.sh
```

Here are the updates for the overlay files needed to define the Staging namespace:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $ONLINEBOUTIQUE_NAMESPACE
cp -r ../upstream/base/for-memorystore/ .
sed -i "s/REDIS_IP/${REDIS_IP}/g;s/REDIS_PORT/${REDIS_PORT}/g" for-memorystore/kustomization.yaml
kustomize edit add component for-memorystore
cp -r ../upstream/base/for-virtualservice-host/ .
sed -i "s/HOST_NAME/${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}/g" for-virtualservice-host/kustomization.yaml
kustomize edit add component for-virtualservice-host
```
{{% notice note %}}
If you have an error message, it's because you don't have access to this project, no worries, just asked your Platform Admin to run that for you and provide you these information :)
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Deploy ${ONLINEBOUTIQUE_NAMESPACE} apps"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE -m 1`:
```Plaintext
completed       success Deploy ob-team1 apps    ci      main    push    2320635242      1m8s    1m
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **Online Boutique app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE \
    | grep $ONLINEBOUTIQUE_NAMESPACE
```
```Plaintext
getting 1 RepoSync and RootSync from projects/acm-workshop-464-gke/locations/global/memberships/gke-hub-membership
    "source": "https://github.com/mathieu-benoit/acm-workshop-ob-team1-repo//staging@main:HEAD",
│                     │ Service        │ adservice             │ ob-team1  │ Current │            │
│                     │ Service        │ cartservice           │ ob-team1  │ Current │            │
│                     │ Service        │ checkoutservice       │ ob-team1  │ Current │            │
│                     │ Service        │ currencyservice       │ ob-team1  │ Current │            │
│                     │ Service        │ emailservice          │ ob-team1  │ Current │            │
│                     │ Service        │ frontend              │ ob-team1  │ Current │            │
│                     │ Service        │ paymentservice        │ ob-team1  │ Current │            │
│                     │ Service        │ productcatalogservice │ ob-team1  │ Current │            │
│                     │ Service        │ recommendationservice │ ob-team1  │ Current │            │
│                     │ Service        │ shippingservice       │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ adservice             │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ cartservice           │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ checkoutservice       │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ currencyservice       │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ emailservice          │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ frontend              │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ loadgenerator         │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ paymentservice        │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ productcatalogservice │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ recommendationservice │ ob-team1  │ Current │            │
│ apps                │ Deployment     │ shippingservice       │ ob-team1  │ Current │            │
│ networking.istio.io │ VirtualService │ frontend              │ ob-team1  │ Current │            │
```