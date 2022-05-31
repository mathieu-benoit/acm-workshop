---
title: "Secure Memorystore access"
weight: 8
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will secure the access by TLS to the Memorystore (redis) instance from the OnlineBoutique's `cartservice` appl, without updating the source code of the app, just with Istio's capabilities.

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
echo "export CART_MEMORYSTORE_HOST=${REDIS_NAME}.memorystore-redis.${ONLINEBOUTIQUE_NAMESPACE}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice info %}}
The `CART_MEMORYSTORE_HOST` has been built in order to explicitly represent the Memorystore endpoint on an Istio perspective. This name will be leveraged in 3 Istio resources: `ServiceEntry`, `DestinationRule` and `Sidecar`.
{{% /notice %}}

## Update Staging namespace overlay

Get Memorystore (redis) connection information:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(port)')
export REDIS_TLS_CERT_NAME=redis-cert
gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(serverCaCerts[0].cert)' > ${WORK_DIR}${REDIS_TLS_CERT_NAME}.pem
```

Update the Online Boutique apps with the new Memorystore (redis) connection information:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging
cp -r ../upstream/base/for-memorystore/ .
sed -i "s/REDIS_IP/${REDIS_IP}/g;s/REDIS_PORT/${REDIS_PORT}/g" for-memorystore/kustomization.yaml
kustomize edit add component for-memorystore
```
{{% notice info %}}
This will change the `REDIS_ADDR` environment variable of the `cartservice` to point to the Memorystore (redis) instance as well as removing the `Deployment` and the `Service` of the default in-cluster `redis` database container.
{{% /notice %}}

Define the `Secret` with the Certificate Authority:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging/for-memorystore
kubectl create secret generic $REDIS_TLS_CERT_NAME --from-file=${WORK_DIR}${REDIS_TLS_CERT_NAME}.pem -n $ONLINEBOUTIQUE_NAMESPACE --dry-run=client -o yaml > memorystore-redis-tls-secret.yaml
kustomize edit add resource memorystore-redis-tls-secret.yaml
```
{{% notice note %}}
The certificate value will be exposed in the `Secret` manifest in the Git repository. It is not a good practice, you shouldn't do that for your own workload. In the future, this will be fixed in this workshop with for example the use of the [Google Secret Manager provider for the Secret Store CSI Driver](https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp).
{{% /notice %}}

Define the `ServiceEntry` and `DestinationRule` in order to configure the TLS connection outside of the mesh and the cluster, pointing to the Memorystore (redis) instance:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging/for-memorystore
cat <<EOF >> memorystore-redis-tls-serviceentry.yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: memorystore-redis-tls
spec:
  hosts:
  - ${CART_MEMORYSTORE_HOST}
  addresses:
  - ${REDIS_IP}/32
  endpoints:
  - address: ${REDIS_IP}
  location: MESH_EXTERNAL
  resolution: STATIC
  ports:
  - number: ${REDIS_PORT}
    name: tcp-redis
    protocol: TCP
EOF
cat <<EOF >> memorystore-redis-tls-destinationrule.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: memorystore-redis-tls
spec:
  exportTo:
  - '.'
  host: ${CART_MEMORYSTORE_HOST}
  trafficPolicy:
    tls:
      mode: SIMPLE
      caCertificates: /etc/certs/${REDIS_TLS_CERT_NAME}.pem
EOF
kustomize edit add resource memorystore-redis-tls-serviceentry.yaml
kustomize edit add resource memorystore-redis-tls-destinationrule.yaml
```

Update the `cartservice` `Deployment` in order to be able to load the TLS configuration for the sidecar proxy:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/staging/for-memorystore
cat <<EOF >> kustomization.yaml
patches:
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: cartservice
      spec:
        template:
          metadata:
            annotations:
              sidecar.istio.io/userVolumeMount: "[{"name":"${REDIS_TLS_CERT_NAME}", "mountPath":"/etc/certs", "readonly":true}]"
              sidecar.istio.io/userVolume: "[{"name":"${REDIS_TLS_CERT_NAME}", "secret":{"secretName":"${REDIS_TLS_CERT_NAME}"}}]"
              proxy.istio.io/config: "{"holdApplicationUntilProxyStarts":true}"
EOF
```

Lastly, by waiting the release of Online Boutique v0.3.8, we need to patch the container image of the `cartservice` app with a temporary public image:
```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/base
cat <<EOF >> kustomization.yaml
patchesJson6902:
- target:
    kind: Deployment
    name: cartservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: us-east4-docker.pkg.dev/mygke-200/containers/boutique/cartservice:redis7
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$ONLINE_BOUTIQUE_DIR_NAME/
git add .
git commit -m "Secure Memorystore access"
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

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique app** repository:
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

## Check the Online Boutique apps

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Online Boutique apps working successfully.