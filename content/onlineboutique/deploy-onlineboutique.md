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

## Grab upstream Kubernetes manifests

Create a dedicated folder for the Online Boutique sample apps in the GKE configs's Git repo:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync
curl https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml > tmp.yaml
nomos hydrate --path . --output . --no-api-server-check --source-format unstructured
rm tmp.yaml
```

## Update Kubernetes manifests

Cleanup and update the upstream files:
```Bash
rm service_redis-cart.yaml
rm deployment_redis-cart.yaml
rm service_frontend-external.yaml
kpt fn eval . \
  -i set-namespace:v0.2 \
  -- namespace=$ONLINEBOUTIQUE_NAMESPACE
sed -i "s/redis-cart:6379/$REDIS_IP:$REDIS_PORT/g" ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/deployment_cartservice.yaml
```

## Define VirtualService

```Bash
cat <<EOF > ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/virtualservice_frontend.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  hosts:
  - ${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}
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