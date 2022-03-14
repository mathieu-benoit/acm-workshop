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

## Define NetworkPolicy resources

Define fine granular `NetworkPolicy` resources:
```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_denyall.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_adservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: adservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: adservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 9555
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_cartservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cartservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: cartservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
    - port: 7070
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_checkoutservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: checkoutservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: checkoutservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 5050
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_currencyservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: currencyservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: currencyservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
    - port: 7000
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_emailservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: emailservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: emailservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
    - port: 8080
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_frontend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
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
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_loadgenerator.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: loadgenerator
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: loadgenerator
  policyTypes:
  - Egress
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_paymentservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: paymentservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: paymentservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
    - port: 50051
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_productcatalogservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: productcatalogservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: productcatalogservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    - podSelector:
        matchLabels:
          app: recommendationservice
    ports:
    - port: 3550
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_recommendationservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: recommendationservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: recommendationservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - port: 8080
      protocol: TCP
  egress:
  - {}
EOF
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/networkpolicy_shippingservice.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: shippingservice
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: shippingservice
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - podSelector:
        matchLabels:
          app: checkoutservice
    ports:
    - port: 50051
      protocol: TCP
  egress:
  - {}
EOF
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