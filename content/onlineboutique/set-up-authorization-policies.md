---
title: "Set up Authorization Policies"
weight: 8
description: "Duration: 5 min | Persona: Apps Operator"
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will set up fine granular `AuthorizationPolicies` for you Online Boutique apps. `AuthorizationPolicies` resources add more security between the communication of your `Pods` within your Mesh.

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
git commit -m "Authorization Policies for ${ONLINEBOUTIQUE_NAMESPACE}"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE`:
```Plaintext
completed       success Authorization Policies for ob-team1     ci      main    push    2317317787      9s      0m
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
│                     │ Service             │ adservice             │ ob-team1  │ Current │            │
│                     │ Service             │ cartservice           │ ob-team1  │ Current │            │
│                     │ Service             │ checkoutservice       │ ob-team1  │ Current │            │
│                     │ Service             │ currencyservice       │ ob-team1  │ Current │            │
│                     │ Service             │ emailservice          │ ob-team1  │ Current │            │
│                     │ Service             │ frontend              │ ob-team1  │ Current │            │
│                     │ Service             │ paymentservice        │ ob-team1  │ Current │            │
│                     │ Service             │ productcatalogservice │ ob-team1  │ Current │            │
│                     │ Service             │ recommendationservice │ ob-team1  │ Current │            │
│                     │ Service             │ shippingservice       │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ adservice             │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ cartservice           │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ checkoutservice       │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ currencyservice       │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ emailservice          │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ frontend              │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ loadgenerator         │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ paymentservice        │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ productcatalogservice │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ recommendationservice │ ob-team1  │ Current │            │
│                     │ ServiceAccount      │ shippingservice       │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ adservice             │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ cartservice           │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ checkoutservice       │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ currencyservice       │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ emailservice          │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ frontend              │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ loadgenerator         │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ paymentservice        │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ productcatalogservice │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ recommendationservice │ ob-team1  │ Current │            │
│ apps                │ Deployment          │ shippingservice       │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ adservice             │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ cartservice           │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ checkoutservice       │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ currencyservice       │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ emailservice          │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ frontend              │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ loadgenerator         │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ paymentservice        │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ productcatalogservice │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ recommendationservice │ ob-team1  │ Current │            │
│ networking.istio.io │ Sidecar             │ shippingservice       │ ob-team1  │ Current │            │
│ networking.istio.io │ VirtualService      │ frontend              │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ adservice             │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ cartservice           │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ checkoutservice       │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ currencyservice       │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ deny-all              │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ emailservice          │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ frontend              │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ loadgenerator         │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ paymentservice        │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ productcatalogservice │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ recommendationservice │ ob-team1  │ Current │            │
│ networking.k8s.io   │ NetworkPolicy       │ shippingservice       │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ adservice             │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ cartservice           │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ checkoutservice       │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ currencyservice       │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ emailservice          │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ frontend              │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ paymentservice        │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ productcatalogservice │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ recommendationservice │ ob-team1  │ Current │            │
│ security.istio.io   │ AuthorizationPolicy │ shippingservice       │ ob-team1  │ Current │            │
```