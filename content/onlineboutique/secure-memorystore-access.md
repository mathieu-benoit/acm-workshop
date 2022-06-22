---
title: "Secure Memorystore access"
weight: 12
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will secure the access by TLS to the Memorystore (redis) instance from the OnlineBoutique's `cartservice` appl, without updating the source code of the app, just with Istio's capabilities.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export CART_MEMORYSTORE_HOST=${REDIS_NAME}.memorystore-redis.${ONLINEBOUTIQUE_NAMESPACE}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice info %}}
The `CART_MEMORYSTORE_HOST` has been built in order to explicitly represent the Memorystore (redis) endpoint on an Istio perspective. This name will be leveraged in 3 Istio resources: `ServiceEntry`, `DestinationRule` and `Sidecar`.
{{% /notice %}}

## Update Staging namespace overlay

Get Memorystore (redis) connection information:
```Bash
export REDIS_TLS_IP=$(gcloud redis instances describe $REDIS_TLS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(host)')
export REDIS_TLS_PORT=$(gcloud redis instances describe $REDIS_TLS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(port)')
export REDIS_TLS_CERT_NAME=redis-cert
gcloud redis instances describe $REDIS_TLS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(serverCaCerts[0].cert)' > ${WORK_DIR}${REDIS_TLS_CERT_NAME}.pem
```

Update the Online Boutique apps with the new Memorystore (redis) connection information:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
cp -r ../upstream/base/for-memorystore/ .
sed -i "s/REDIS_IP/${REDIS_TLS_IP}/g;s/REDIS_PORT/${REDIS_TLS_PORT}/g" for-memorystore/kustomization.yaml
```
{{% notice info %}}
This will change the `REDIS_ADDR` environment variable of the `cartservice` to point to the Memorystore (redis) instance with TLS enabled.
{{% /notice %}}

Define the `Secret` with the Certificate Authority:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging/for-memorystore
kubectl create secret generic $REDIS_TLS_CERT_NAME --from-file=${WORK_DIR}${REDIS_TLS_CERT_NAME}.pem -n $ONLINEBOUTIQUE_NAMESPACE --dry-run=client -o yaml > memorystore-redis-tls-secret.yaml
kustomize edit add resource memorystore-redis-tls-secret.yaml
```
{{% notice note %}}
The certificate value will be exposed in the `Secret` manifest in the Git repository. It is not a good practice, you shouldn't do that for your own workload. In the future, this will be fixed in this workshop with for example the use of the [Google Secret Manager provider for the Secret Store CSI Driver](https://github.com/GoogleCloudPlatform/secrets-store-csi-driver-provider-gcp).
{{% /notice %}}

Define the `ServiceEntry` and `DestinationRule` in order to configure the TLS connection outside of the mesh and the cluster, pointing to the Memorystore (redis) instance:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging/for-memorystore
cat <<EOF >> memorystore-redis-tls-serviceentry.yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: memorystore-redis-tls
spec:
  hosts:
  - ${CART_MEMORYSTORE_HOST}
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
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging/for-memorystore
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
              sidecar.istio.io/userVolumeMount: '[{"name": "redis-cert", "mountPath": "/etc/certs", "readonly": true}]'
              sidecar.istio.io/userVolume: '[{"name": "redis-cert", "secret": {"secretName": "redis-cert"}}]'
              proxy.istio.io/config: '{"holdApplicationUntilProxyStarts": true}'
EOF
```

Update the previously deployed `Sidecars`:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
cat <<EOF >> kustomization.yaml
- target:
    kind: Sidecar
    name: cartservice
  patch: |-
    - op: replace
      path: /spec/egress/0/hosts
      value:
        - "istio-system/*"
        - "./${CART_MEMORYSTORE_HOST}"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Secure Memorystore (redis) access" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```

## Check the Online Boutique apps

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Online Boutique apps working successfully, but now with an external redis database with encryption in-transit between this Memorystore (redis) database and the `cartservice`.