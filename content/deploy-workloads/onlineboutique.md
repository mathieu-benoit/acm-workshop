---
title: "Deploy OnlineBoutique"
weight: 2
---
In this section, you will deploy the [OnlineBoutique](https://github.com/GoogleCloudPlatform/microservices-demo) apps _as-is_, without any notion of Istio nor ASM, not yet.

Create the OnlineBoutique namespace:
```Bash
export ONLINEBOUTIQUE_NAMESPACE=onlineboutique
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${ONLINEBOUTIQUE_NAMESPACE}
  labels:
    name: ${ONLINEBOUTIQUE_NAMESPACE}
EOF
```

Retrieve and deploy the Kubernetes manifests of the OnlineBoutique apps:
```Bash
mkdir ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE
curl https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml > ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/tmp.yaml
nomos hydrate --path ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/ --output ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE --no-api-server-check --source-format unstructured
rm ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/tmp.yaml
kubectl apply -f ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/ -n $ONLINEBOUTIQUE_NAMESPACE
```

Ensure that all deployments are up and running:
```Bash
kubectl wait --for=condition=available --timeout=600s deployment --all -n $ONLINEBOUTIQUE_NAMESPACE
ONLINEBOUTIQUE_PUBLIC_IP=$(kubectl get svc frontend-external -n $ONLINEBOUTIQUE_NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
curl -s http://${ONLINEBOUTIQUE_PUBLIC_IP}
```

In order to be more secure and have more resilience with the data stored in `redis`, we will leverage Memorystore (redis) instead:
```Bash
gcloud services enable redis.googleapis.com
REDIS_NAME=cart
gcloud redis instances create $REDIS_NAME --size=1 --region=$REGION --zone=$ZONE --redis-version=redis_6_x
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$REGION --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$REGION --format='get(port)')
sed -i "s/redis-cart:6379/$REDIS_IP:$REDIS_PORT/g" ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_cartservice.yaml
kubectl apply -f ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_cartservice.yaml -n $ONLINEBOUTIQUE_NAMESPACE
```

Ensure that the solution is still working correctly with Memorystore (redis):
```Bash
curl -s http://${ONLINEBOUTIQUE_PUBLIC_IP}
```

From there, the `redis` container originally deployed could now be deleted:
```Bash
kubectl delete deployment redis-cart -n $ONLINEBOUTIQUE_NAMESPACE
kubectl delete service redis-cart -n $ONLINEBOUTIQUE_NAMESPACE
rm ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_redis-cart.yaml
rm ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/service_redis-cart.yaml
```
{{% notice note %}}
You can connect to a Memorystore (redis) instance only from GKE clusters that are in the same region and use the same network as your instance. You cannot connect to a Memorystore (redis) instance from a GKE cluster without VPC-native/IP aliasing enabled. For this you should create a GKE cluster with this option `--enable-ip-alias`.
{{% /notice %}}

Here is the high-level setup you you just accomplished with this section:
![ASM Security diagram](/images/onlineboutique-initial.png)

Resources:
- [Tutorial - Deploying the Online Boutique sample application](https://cloud.google.com/service-mesh/docs/onlineboutique-install-kpt)
- [Connecting to Memorystore (redis) from GKE](https://cloud.google.com/memorystore/docs/redis/connect-redis-instance-gke)