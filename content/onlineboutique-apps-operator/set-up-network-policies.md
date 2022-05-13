---
title: "Set up Network Policies"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will set up fine granular `NetworkPolicies` for you Online Boutique apps. `NetworkPolicies` resources add more security between the communication of your `Pods`.

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAME=asm-ingressgateway" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export INGRESS_GATEWAY_NAMESPACE=asm-ingress" >> ${WORK_DIR}acm-workshop-variables.sh
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
git commit -m "Network Policies for ${ONLINEBOUTIQUE_NAMESPACE}"
git push origin main
```

## Check deployments

List the GitHub runs for the **Online Boutique app** repository `cd ~/$ONLINE_BOUTIQUE_DIR_NAME && gh run list | grep $ONLINEBOUTIQUE_NAMESPACE -m 1`:
```Plaintext
in_progress             Network Policies for ob-team1   ci      main    push    2317274227      7s      0m
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
│                     │ Service        │ adservice             │ ob-team1  │ Current │
│                     │ Service        │ cartservice           │ ob-team1  │ Current │
│                     │ Service        │ checkoutservice       │ ob-team1  │ Current │
│                     │ Service        │ currencyservice       │ ob-team1  │ Current │
│                     │ Service        │ emailservice          │ ob-team1  │ Current │
│                     │ Service        │ frontend              │ ob-team1  │ Current │
│                     │ Service        │ paymentservice        │ ob-team1  │ Current │
│                     │ Service        │ productcatalogservice │ ob-team1  │ Current │
│                     │ Service        │ recommendationservice │ ob-team1  │ Current │
│                     │ Service        │ shippingservice       │ ob-team1  │ Current │
│ apps                │ Deployment     │ adservice             │ ob-team1  │ Current │
│ apps                │ Deployment     │ cartservice           │ ob-team1  │ Current │
│ apps                │ Deployment     │ checkoutservice       │ ob-team1  │ Current │
│ apps                │ Deployment     │ currencyservice       │ ob-team1  │ Current │
│ apps                │ Deployment     │ emailservice          │ ob-team1  │ Current │
│ apps                │ Deployment     │ frontend              │ ob-team1  │ Current │
│ apps                │ Deployment     │ loadgenerator         │ ob-team1  │ Current │
│ apps                │ Deployment     │ paymentservice        │ ob-team1  │ Current │
│ apps                │ Deployment     │ productcatalogservice │ ob-team1  │ Current │
│ apps                │ Deployment     │ recommendationservice │ ob-team1  │ Current │
│ apps                │ Deployment     │ shippingservice       │ ob-team1  │ Current │
│ networking.istio.io │ VirtualService │ frontend              │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ adservice             │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ cartservice           │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ checkoutservice       │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ currencyservice       │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ deny-all              │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ emailservice          │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ frontend              │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ loadgenerator         │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ paymentservice        │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ productcatalogservice │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ recommendationservice │ ob-team1  │ Current │
│ networking.k8s.io   │ NetworkPolicy  │ shippingservice       │ ob-team1  │ Current │
```