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
mkdir upstream/base
curl https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml > upstream/base/kubernetes-manifests.yaml
cd upstream/base
kustomize create --resources kubernetes-manifests.yaml
```

## Create base overlay

Create Kustomize base overlay files:
```Bash
mkdir ~/$ONLINE_BOUTIQUE_DIR_NAME/base
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize create --resources ../upstream/base
cat <<EOF >> ~/$ONLINE_BOUTIQUE_DIR_NAME/base/kustomization.yaml
patchesJson6902:
- target:
    kind: Deployment
    name: cartservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/env/0
      value:
        name: REDIS_ADDR
        value: $REDIS_IP:$REDIS_PORT
patchesStrategicMerge:
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: redis-cart
  \$patch: delete
- |-
  apiVersion: v1
  kind: Service
  metadata:
    name: redis-cart
  \$patch: delete
- |-
  apiVersion: v1
  kind: Service
  metadata:
    name: frontend-external
  \$patch: delete
EOF
```
{{% notice note %}}
Here we are removing the `redis-cart` `Deployment` and `Service` because we are leveraging Memorystore (redis) instead. We are also removing the default `frontend-external` `Service` because we will use the ASM Ingress Gateway to expose the Online Boutique's `frontend`.
{{% /notice %}}

## Define VirtualService

Define the `VirtualService` resource in order to establish the Ingress Gateway routing to the OnlineBoutique app:
```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/base/virtual-service-frontend.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
spec:
  hosts:
  - "*"
  gateways:
  - ${INGRESS_GATEWAY_NAMESPACE}/${INGRESS_GATEWAY_NAME}
  http:
  - route:
    - destination:
        host: frontend
        port:
          number: 80
EOF
```

Update the Kustomize base overlay:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add resource virtual-service-frontend.yaml
```

## Define Staging namespace overlay

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $ONLINEBOUTIQUE_NAMESPACE
```

Update the Kustomize base overlay in order to set proper `hosts` value in the `VirtualService` resource:
```Bash
cat <<EOF >> ~/$ONLINE_BOUTIQUE_DIR_NAME/staging/kustomization.yaml
patchesJson6902:
- target:
    kind: VirtualService
    name: frontend
  patch: |-
    - op: replace
      path: /spec/hosts
      value:
        - ${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}
EOF
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