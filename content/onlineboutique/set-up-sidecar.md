---
title: "Set up Sidecar"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Prepare upstream Kubernetes manifests

Prepare the upstream Kubernetes manifests:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/upstream
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/sidecars@main
```

## Update the Kustomize base overlay

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add component ../upstream/sidecars/all
```

## Update Staging namespace overlay

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging
mkdir sidecars
cp -r ../upstream/sidecars/for-namespace/ sidecars/.
sed -i "s/ONLINEBOUTIQUE_NAMESPACE/${ONLINEBOUTIQUE_NAMESPACE}/g" sidecars/for-namespace/kustomization.yaml
kustomize edit add component sidecars/for-namespace
kustomize edit add component ../upstream/sidecars/for-memorystore
```

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Sidecars for ${ONLINEBOUTIQUE_NAMESPACE}"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE`:
```Plaintext
completed       success Sidecars for ob-team1   ci      main    push    2317294732      1m22s   3m
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
│                     │ Service        │ adservice             │ ob-team1  │ Unknown │            │
│                     │ Service        │ cartservice           │ ob-team1  │ Unknown │            │
│                     │ Service        │ checkoutservice       │ ob-team1  │ Unknown │            │
│                     │ Service        │ currencyservice       │ ob-team1  │ Unknown │            │
│                     │ Service        │ emailservice          │ ob-team1  │ Unknown │            │
│                     │ Service        │ frontend              │ ob-team1  │ Unknown │            │
│                     │ Service        │ paymentservice        │ ob-team1  │ Unknown │            │
│                     │ Service        │ productcatalogservice │ ob-team1  │ Unknown │            │
│                     │ Service        │ recommendationservice │ ob-team1  │ Unknown │            │
│                     │ Service        │ shippingservice       │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ adservice             │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ cartservice           │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ checkoutservice       │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ currencyservice       │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ emailservice          │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ frontend              │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ loadgenerator         │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ paymentservice        │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ productcatalogservice │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ recommendationservice │ ob-team1  │ Unknown │            │
│ apps                │ Deployment     │ shippingservice       │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ adservice             │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ cartservice           │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ checkoutservice       │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ currencyservice       │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ emailservice          │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ frontend              │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ loadgenerator         │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ paymentservice        │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ productcatalogservice │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ recommendationservice │ ob-team1  │ Unknown │            │
│ networking.istio.io │ Sidecar        │ shippingservice       │ ob-team1  │ Unknown │            │
│ networking.istio.io │ VirtualService │ frontend              │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ adservice             │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ cartservice           │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ checkoutservice       │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ currencyservice       │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ deny-all              │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ emailservice          │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ frontend              │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ loadgenerator         │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ paymentservice        │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ productcatalogservice │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ recommendationservice │ ob-team1  │ Unknown │            │
│ networking.k8s.io   │ NetworkPolicy  │ shippingservice       │ ob-team1  │ Unknown │            │
```