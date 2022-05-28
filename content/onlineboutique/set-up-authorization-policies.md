---
title: "Set up Authorization Policies"
weight: 8
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/upstream
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/service-accounts@main
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/authorization-policies@main
```

## Update the Kustomize base overlay

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add component ../upstream/service-accounts/all
kustomize edit add component ../upstream/service-accounts/for-memorystore
kustomize edit add component ../upstream/authorization-policies/all
kustomize edit add component ../upstream/authorization-policies/for-memorystore
```

## Update Staging namespace overlay

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging
mkdir authorization-policies
cp -r ../upstream/authorization-policies/for-namespace/ authorization-policies/.
sed -i "s/ONLINEBOUTIQUE_NAMESPACE/${ONLINEBOUTIQUE_NAMESPACE}/g" authorization-policies/for-namespace/kustomization.yaml
kustomize edit add component authorization-policies/for-namespace
cp -r ../upstream/authorization-policies/for-ingress-gateway/ authorization-policies/.
sed -i "s/ONLINEBOUTIQUE_NAMESPACE/${ONLINEBOUTIQUE_NAMESPACE}/g;s/INGRESS_GATEWAY_NAMESPACE/${INGRESS_GATEWAY_NAMESPACE}/g;s/INGRESS_GATEWAY_NAME/${INGRESS_GATEWAY_NAME}/g" authorization-policies/for-ingress-gateway/kustomization.yaml
kustomize edit add component authorization-policies/for-ingress-gateway
```

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique Authorization Policies"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                    WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Online Boutique Authorization Policies  ci        main    push   1978549160  1m13s    3m
✓       Online Boutique Sidecar                 ci        main    push   1978491894  1m0s     24m
✓       Online Boutique Network Policies        ci        main    push   1978459522  54s      34m
✓       Online Boutique apps                    ci        main    push   1978432931  1m3s     43m
✓       Initial commit                          ci        main    push   1976979782  54s      10h

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
┌─────────────────────┬─────────────────────┬───────────────────────┬────────────────┐
│        GROUP        │         KIND        │          NAME         │   NAMESPACE    │
├─────────────────────┼─────────────────────┼───────────────────────┼────────────────┤
│                     │ ServiceAccount      │ recommendationservice │ onlineboutique │
│                     │ Service             │ currencyservice       │ onlineboutique │
│                     │ ServiceAccount      │ emailservice          │ onlineboutique │
│                     │ ServiceAccount      │ productcatalogservice │ onlineboutique │
│                     │ Service             │ frontend              │ onlineboutique │
│                     │ ServiceAccount      │ cartservice           │ onlineboutique │
│                     │ ServiceAccount      │ paymentservice        │ onlineboutique │
│                     │ Service             │ productcatalogservice │ onlineboutique │
│                     │ ServiceAccount      │ frontend              │ onlineboutique │
│                     │ ServiceAccount      │ currencyservice       │ onlineboutique │
│                     │ Service             │ adservice             │ onlineboutique │
│                     │ Service             │ shippingservice       │ onlineboutique │
│                     │ ServiceAccount      │ adservice             │ onlineboutique │
│                     │ Service             │ paymentservice        │ onlineboutique │
│                     │ Service             │ cartservice           │ onlineboutique │
│                     │ ServiceAccount      │ loadgenerator         │ onlineboutique │
│                     │ ServiceAccount      │ shippingservice       │ onlineboutique │
│                     │ Service             │ emailservice          │ onlineboutique │
│                     │ Service             │ checkoutservice       │ onlineboutique │
│                     │ ServiceAccount      │ checkoutservice       │ onlineboutique │
│                     │ Service             │ recommendationservice │ onlineboutique │
│ apps                │ Deployment          │ frontend              │ onlineboutique │
│ apps                │ Deployment          │ currencyservice       │ onlineboutique │
│ apps                │ Deployment          │ shippingservice       │ onlineboutique │
│ apps                │ Deployment          │ loadgenerator         │ onlineboutique │
│ apps                │ Deployment          │ paymentservice        │ onlineboutique │
│ apps                │ Deployment          │ cartservice           │ onlineboutique │
│ apps                │ Deployment          │ productcatalogservice │ onlineboutique │
│ apps                │ Deployment          │ checkoutservice       │ onlineboutique │
│ apps                │ Deployment          │ recommendationservice │ onlineboutique │
│ apps                │ Deployment          │ adservice             │ onlineboutique │
│ apps                │ Deployment          │ emailservice          │ onlineboutique │
│ networking.istio.io │ Sidecar             │ productcatalogservice │ onlineboutique │
│ networking.istio.io │ Sidecar             │ cartservice           │ onlineboutique │
│ networking.istio.io │ Sidecar             │ emailservice          │ onlineboutique │
│ networking.istio.io │ Sidecar             │ currencyservice       │ onlineboutique │
│ networking.istio.io │ Sidecar             │ loadgenerator         │ onlineboutique │
│ networking.istio.io │ Sidecar             │ shippingservice       │ onlineboutique │
│ networking.istio.io │ Sidecar             │ adservice             │ onlineboutique │
│ networking.istio.io │ Sidecar             │ paymentservice        │ onlineboutique │
│ networking.istio.io │ Sidecar             │ frontend              │ onlineboutique │
│ networking.istio.io │ Sidecar             │ recommendationservice │ onlineboutique │
│ networking.istio.io │ VirtualService      │ frontend              │ onlineboutique │
│ networking.istio.io │ Sidecar             │ checkoutservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ paymentservice        │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ currencyservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ loadgenerator         │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ adservice             │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ denyall               │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ emailservice          │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ checkoutservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ cartservice           │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ shippingservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ recommendationservice │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ productcatalogservice │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy       │ frontend              │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ adservice             │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ productcatalogservice │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ paymentservice        │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ currencyservice       │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ recommendationservice │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ frontend              │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ checkoutservice       │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ emailservice          │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ deny-all              │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ cartservice           │ onlineboutique │
│ security.istio.io   │ AuthorizationPolicy │ shippingservice       │ onlineboutique │
└─────────────────────┴─────────────────────┴───────────────────────┴────────────────┘
```