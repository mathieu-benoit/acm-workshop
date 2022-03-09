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
git push
```

## Check deployments

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```