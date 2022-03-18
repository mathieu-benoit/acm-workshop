---
title: "Set up Network Policies"
weight: 6
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
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/upstream
kpt pkg get https://github.com/GoogleCloudPlatform/microservices-demo.git/docs/network-policies@mathieu-benoit/authorization-policies
rm network-policies/Kptfile
rm network-policies/kustomization.yaml
```

## Update the Kustomize base overlay

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add component ../upstream/network-policies/all
kustomize edit add component ../upstream/network-policies/for-ingress-gateway
kustomize edit add component ../upstream/network-policies/for-memorystore
```

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique Network Policies"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                              WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Online Boutique Network Policies  ci        main    push   1978459522  54s      2m
✓       Online Boutique apps              ci        main    push   1978432931  1m3s     10m
✓       Initial commit                    ci        main    push   1976979782  54s      10h
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
│                     │ Service        │ adservice             │ onlineboutique │
│                     │ Service        │ checkoutservice       │ onlineboutique │
│                     │ Service        │ recommendationservice │ onlineboutique │
│                     │ Service        │ cartservice           │ onlineboutique │
│                     │ Service        │ shippingservice       │ onlineboutique │
│                     │ Service        │ emailservice          │ onlineboutique │
│                     │ Service        │ paymentservice        │ onlineboutique │
│                     │ Service        │ currencyservice       │ onlineboutique │
│                     │ Service        │ frontend              │ onlineboutique │
│ apps                │ Deployment     │ paymentservice        │ onlineboutique │
│ apps                │ Deployment     │ productcatalogservice │ onlineboutique │
│ apps                │ Deployment     │ shippingservice       │ onlineboutique │
│ apps                │ Deployment     │ recommendationservice │ onlineboutique │
│ apps                │ Deployment     │ frontend              │ onlineboutique │
│ apps                │ Deployment     │ emailservice          │ onlineboutique │
│ apps                │ Deployment     │ checkoutservice       │ onlineboutique │
│ apps                │ Deployment     │ adservice             │ onlineboutique │
│ apps                │ Deployment     │ currencyservice       │ onlineboutique │
│ apps                │ Deployment     │ cartservice           │ onlineboutique │
│ networking.istio.io │ VirtualService │ frontend              │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ recommendationservice │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ paymentservice        │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ loadgenerator         │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ emailservice          │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ cartservice           │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ checkoutservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ productcatalogservice │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ frontend              │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ currencyservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ adservice             │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ denyall               │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ shippingservice       │ onlineboutique │
└─────────────────────┴────────────────┴───────────────────────┴────────────────┘
```