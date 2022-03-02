---
title: "Deploy Online Boutique"
weight: 4
---
- Persona: Apps Operator
- Duration: 5 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
echo "export GKE_LOCATION=us-east4" >> ~/acm-workshop-variables.sh
echo "export GKE_NAME=gke" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

Create a dedicated folder for the Online Boutique sample apps in the GKE configs's Git repo:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync
curl https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml > tmp.yaml
nomos hydrate --path . --output . --no-api-server-check --source-format unstructured
rm tmp.yaml
```

Cleanup and update the upstream files:
```Bash
rm service_redis-cart.yaml
rm deployment_redis-cart.yaml
rm service_frontend-external.yaml
kpt fn eval . \
  --image gcr.io/kpt-fn/set-namespace:unstable \
  -- namespace=$ONLINEBOUTIQUE_NAMESPACE
sed -i "s/redis-cart:6379/$REDIS_IP:$REDIS_PORT/g" ~/$ONLINE_BOUTIQUE_DIR_NAME/config-sync/deployment_cartservice.yaml
```

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

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Online Boutique sample apps"
git push
```