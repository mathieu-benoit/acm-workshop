---
title: "Deploy Sidecars"
weight: 10
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["asm", "apps-operator"]
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

FIXME in Sidecar: `- "./${CART_MEMORYSTORE_HOST}"`

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique Sidecar"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                              WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Online Boutique Sidecar           ci        main    push   1978491894  9s       1m
✓       Online Boutique Network Policies  ci        main    push   1978459522  54s      11m
✓       Online Boutique apps              ci        main    push   1978432931  1m3s     19m
✓       Initial commit                    ci        main    push   1976979782  54s      10h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **Online Boutique app** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
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
│                     │ Service        │ checkoutservice       │ onlineboutique │
│                     │ Service        │ cartservice           │ onlineboutique │
│                     │ Service        │ frontend              │ onlineboutique │
│                     │ Service        │ adservice             │ onlineboutique │
│                     │ Service        │ recommendationservice │ onlineboutique │
│                     │ Service        │ paymentservice        │ onlineboutique │
│                     │ Service        │ currencyservice       │ onlineboutique │
│                     │ Service        │ shippingservice       │ onlineboutique │
│                     │ Service        │ emailservice          │ onlineboutique │
│ apps                │ Deployment     │ cartservice           │ onlineboutique │
│ apps                │ Deployment     │ frontend              │ onlineboutique │
│ apps                │ Deployment     │ recommendationservice │ onlineboutique │
│ apps                │ Deployment     │ shippingservice       │ onlineboutique │
│ apps                │ Deployment     │ paymentservice        │ onlineboutique │
│ apps                │ Deployment     │ productcatalogservice │ onlineboutique │
│ apps                │ Deployment     │ loadgenerator         │ onlineboutique │
│ apps                │ Deployment     │ checkoutservice       │ onlineboutique │
│ apps                │ Deployment     │ emailservice          │ onlineboutique │
│ apps                │ Deployment     │ adservice             │ onlineboutique │
│ apps                │ Deployment     │ currencyservice       │ onlineboutique │
│ networking.istio.io │ Sidecar        │ adservice             │ onlineboutique │
│ networking.istio.io │ Sidecar        │ paymentservice        │ onlineboutique │
│ networking.istio.io │ Sidecar        │ currencyservice       │ onlineboutique │
│ networking.istio.io │ Sidecar        │ emailservice          │ onlineboutique │
│ networking.istio.io │ Sidecar        │ cartservice           │ onlineboutique │
│ networking.istio.io │ Sidecar        │ frontend              │ onlineboutique │
│ networking.istio.io │ Sidecar        │ loadgenerator         │ onlineboutique │
│ networking.istio.io │ Sidecar        │ checkoutservice       │ onlineboutique │
│ networking.istio.io │ Sidecar        │ recommendationservice │ onlineboutique │
│ networking.istio.io │ VirtualService │ frontend              │ onlineboutique │
│ networking.istio.io │ Sidecar        │ productcatalogservice │ onlineboutique │
│ networking.istio.io │ Sidecar        │ shippingservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ emailservice          │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ frontend              │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ currencyservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ checkoutservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ shippingservice       │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ loadgenerator         │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ denyall               │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ recommendationservice │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ productcatalogservice │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ cartservice           │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ adservice             │ onlineboutique │
│ networking.k8s.io   │ NetworkPolicy  │ paymentservice        │ onlineboutique │
└─────────────────────┴────────────────┴───────────────────────┴────────────────┘
```

## Check the Online Boutique apps

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Online Boutique apps working successfully.