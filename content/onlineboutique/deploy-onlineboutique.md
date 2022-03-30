---
title: "Deploy Online Boutique apps"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME
mkdir upstream
cd upstream
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/base@asm-acm-tutorial
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

You could browse the files in the `~/$ONLINE_BOUTIQUE_DIR_NAME/upstream/base` folder, along with the `Namespace`, `Deployment` and `Service` resources for the OnlineBoutique apps, you could see the  `VirtualService` resource which will allow to establish the Ingress Gateway routing to the OnlineBoutique app. The `spec.hosts` value is `"*"` but in the following part you will replace this value by the actual DNS of the OnlineBoutique solution (i.e. `ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME`) defined a previous section.
```YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
spec:
  hosts:
  - "*"
  gateways:
  - asm-ingress/asm-ingressgateway
  http:
  - route:
    - destination:
        host: frontend
        port:
          number: 80
```

## Define Staging namespace overlay

Here are the updates for the overlay files needed to define the Staging namespace:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging
mkdir base
cd base
kustomize edit add resource ../base
kustomize edit set namespace $ONLINEBOUTIQUE_NAMESPACE
cp -r ../../upstream/base/for-memorystore/ .
sed -i "s/REDIS_IP/${REDIS_IP}/g;s/REDIS_PORT/${REDIS_PORT}/g" for-memorystore/kustomization.yaml
kustomize edit add component for-memorystore
cp -r ../../upstream/base/for-virtualservice-host/ .
sed -i "s/HOST_NAME/${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}/g" for-virtualservice-host/kustomization.yaml
kustomize edit add component for-virtualservice-host
```

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique apps"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Online Boutique apps  ci        main    push   1978432931  1m3s     1m
✓       Initial commit        ci        main    push   1976979782  54s      9h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **Online Boutique app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌─────────────────────┬────────────────┬───────────────────────┬────────────────┐
│        GROUP        │      KIND      │          NAME         │   NAMESPACE    │
├─────────────────────┼────────────────┼───────────────────────┼────────────────┤
│                     │ Service        │ productcatalogservice │ onlineboutique │
│                     │ Service        │ frontend              │ onlineboutique │
│                     │ Service        │ paymentservice        │ onlineboutique │
│                     │ Service        │ shippingservice       │ onlineboutique │
│                     │ Service        │ currencyservice       │ onlineboutique │
│                     │ Service        │ emailservice          │ onlineboutique │
│                     │ Service        │ cartservice           │ onlineboutique │
│                     │ Service        │ adservice             │ onlineboutique │
│                     │ Service        │ checkoutservice       │ onlineboutique │
│                     │ Service        │ recommendationservice │ onlineboutique │
│ apps                │ Deployment     │ frontend              │ onlineboutique │
│ apps                │ Deployment     │ checkoutservice       │ onlineboutique │
│ apps                │ Deployment     │ shippingservice       │ onlineboutique │
│ apps                │ Deployment     │ emailservice          │ onlineboutique │
│ apps                │ Deployment     │ paymentservice        │ onlineboutique │
│ apps                │ Deployment     │ cartservice           │ onlineboutique │
│ apps                │ Deployment     │ adservice             │ onlineboutique │
│ apps                │ Deployment     │ productcatalogservice │ onlineboutique │
│ apps                │ Deployment     │ currencyservice       │ onlineboutique │
│ apps                │ Deployment     │ loadgenerator         │ onlineboutique │
│ apps                │ Deployment     │ recommendationservice │ onlineboutique │
│ networking.istio.io │ VirtualService │ frontend              │ onlineboutique │
└─────────────────────┴────────────────┴───────────────────────┴────────────────┘
```