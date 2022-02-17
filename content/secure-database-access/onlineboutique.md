---
title: "Secure Memorystore (redis) access"
weight: 1
---
In this section, you will secure the access by TLS to the Memorystore (redis) instance from the OnlineBoutique's `cartservice` application, without updating the source code of the app, just with Istio.

Create a new instance with in-transit encryption enabled:
```Bash
export REDIS_TLS_NAME=cart-tls
gcloud redis instances create $REDIS_TLS_NAME --size=1 --region=$REGION --zone=$ZONE --redis-version=redis_6_x --transit-encryption-mode=SERVER_AUTHENTICATION
```

Once the new Memorystore (redis) instance is created, capture the following variables:
```Bash
export REDIS_TLS_IP=$(gcloud redis instances describe $REDIS_TLS_NAME --region=$REGION --format='get(host)')
export REDIS_TLS_PORT=$(gcloud redis instances describe $REDIS_TLS_NAME --region=$REGION --format='get(port)')
export REDIS_TLS_CERT_NAME=redis-cert
gcloud redis instances describe $REDIS_TLS_NAME --region=$REGION --format='get(serverCaCerts[0].cert)' > ~/$WORKING_DIRECTORY/$REDIS_TLS_CERT_NAME.pem
```

Create the `Secret` with the Certificate Authority:
```Bash
kubectl create secret generic $REDIS_TLS_CERT_NAME --from-file=$REDIS_TLS_CERT_NAME.pem -n $ONLINEBOUTIQUE_NAMESPACE
```

Create the `ServiceEntry` and `DestinationRule`:
```Bash
export INTERNAL_HOST=cart.memorystore-redis.onlineboutique
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: memorystore-redis-tls
spec:
  hosts:
  - ${INTERNAL_HOST}
  addresses:
  - ${REDIS_TLS_IP}/32
  endpoints:
  - address: ${REDIS_TLS_IP}
  location: MESH_EXTERNAL
  resolution: STATIC
  ports:
  - number: ${REDIS_TLS_PORT}
    name: tcp-redis
    protocol: TCP
EOF
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: memorystore-redis-tls
spec:
  exportTo:
  - '.'
  host: ${INTERNAL_HOST}
  trafficPolicy:
    tls:
      mode: SIMPLE
      caCertificates: /etc/certs/${REDIS_TLS_CERT_NAME}.pem
EOF
```

Update the `cartservice`'s `Sidecar` resource according to this new service endpoint in the mesh:
```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: cartservice
spec:
  workloadSelector:
    labels:
      app: cartservice
  egress:
  - hosts:
    - "istio-system/*"
    - "./${INTERNAL_HOST}"
EOF
```

Check that the new internal endpoint is listed as `cart.memorystore-redis.onlineboutique - 6378 - outbound - EDS - memorystore-redis-tls.onlineboutique` by running this command:
```Bash
istioctl proxy-config clusters $(kubectl -n $ONLINEBOUTIQUE_NAMESPACE get pod -l app=cartservice -o jsonpath={.items..metadata.name}) -n $ONLINEBOUTIQUE_NAMESPACE
```

Update the `cartservice` `Deployment` in order to be able to load the 
```Bash
cat <<EOF > ~/$WORKING_DIRECTORY/cartservice-tls-patch.json
{
   "spec": {
      "template": {
         "metadata": {
            "annotations": {
                "sidecar.istio.io/userVolumeMount": "[{\"name\":\"${REDIS_TLS_CERT_NAME}\", \"mountPath\":\"/etc/certs\", \"readonly\":true}]",
                "sidecar.istio.io/userVolume": "[{\"name\":\"${REDIS_TLS_CERT_NAME}\", \"secret\":{\"secretName\":\"${REDIS_TLS_CERT_NAME}\"}}]",
                "proxy.istio.io/config": "{\"holdApplicationUntilProxyStarts\":true}",
                "sidecar.istio.io/logLevel": "debug"
            }
         }
      }
   }
}
EOF
kubectl patch -f ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_cartservice.yaml --local=true --patch "$(cat ~/$WORKING_DIRECTORY/cartservice-tls-patch.json)" -o yaml > ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_cartservice-tls.yaml
sed -i "s/$REDIS_IP:$REDIS_PORT/$REDIS_TLS_IP:$REDIS_TLS_PORT/g" ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_cartservice-tls.yaml
```

Deploy the updates on the `cartservice` `Deployment`:
```Bash
kubectl apply -f ~/$WORKING_DIRECTORY/$ONLINEBOUTIQUE_NAMESPACE/deployment_cartservice-tls.yaml -n $ONLINEBOUTIQUE_NAMESPACE
```

```Bash
curl -s http://${INGRESS_GATEWAY_PUBLIC_IP}
```