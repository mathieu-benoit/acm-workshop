---
title: "Set up Network Policies"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator"]
---
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/upstream
kpt pkg get https://github.com/GoogleCloudPlatform/microservices-demo.git/docs/network-policies@main
cd network-policies
kustomize create --autodetect
kustomize edit remove resource Kptfile
```

## Update the Kustomize base overlay

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/base
mkdir network-policies
cat <<EOF >> network-policies/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patchesStrategicMerge:
- |-
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: redis-cart
  \$patch: delete
patchesJson6902:
- target:
    kind: NetworkPolicy
    name: frontend
  patch: |-
    - op: replace
      path: /spec/ingress
      value:
        - from:
          - podSelector:
              matchLabels:
                app: loadgenerator
          - namespaceSelector:
              matchLabels:
                name: ${INGRESS_GATEWAY_NAMESPACE}
            podSelector:
              matchLabels:
                app: ${INGRESS_GATEWAY_NAME}
          ports:
          - port: 8080
            protocol: TCP
EOF
kustomize edit add resource ../upstream/network-policies
kustomize edit add component network-policies
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
