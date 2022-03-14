---
title: "Set up Sidecar"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define Sidecar resources

```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_adservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: adservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: adservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_cartservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: cartservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: cartservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_checkoutservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: checkoutservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: checkoutservice
  egress:
  - hosts:
    - "istio-system/*"
    - "./cartservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./currencyservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./emailservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./paymentservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./productcatalogservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./shippingservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_currencyservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: currencyservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: currencyservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_emailservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: emailservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: emailservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_frontend.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: frontend
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: frontend
  egress:
  - hosts:
    - "istio-system/*"
    - "./adservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./cartservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./checkoutservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./currencyservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./productcatalogservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./recommendationservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
    - "./shippingservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_loadgenerator.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: loadgenerator
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: loadgenerator
  egress:
  - hosts:
    - "istio-system/*"
    - "./frontend.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_paymentservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: paymentservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: paymentservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_productcatalogservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: productcatalogservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: productcatalogservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_recommendationservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: recommendationservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: recommendationservice
  egress:
  - hosts:
    - "istio-system/*"
    - "./productcatalogservice.${ONLINEBOUTIQUE_NAMESPACE}.svc.cluster.local"
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/sidecar_shippingservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: shippingservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: shippingservice
  egress:
  - hosts:
    - "istio-system/*"
EOF
```

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