---
title: "Deploy apps"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy the Online Boutique apps.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Update base overlay

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add resource ../upstream/base
cat <<EOF >> ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base/kustomization.yaml
patchesStrategicMerge:
- |-
  apiVersion: v1
  kind: Service
  metadata:
    name: frontend-external
  \$patch: delete
EOF
```
{{% notice info %}}
Here we are deleting the `Service` `frontend-external` because the `frontend` app will be exposed by the Ingress Gateway.
{{% /notice %}}

## Define VirtualService

Define the `VirtualService` resource in order to establish the Ingress Gateway routing to the Online Boutique apps:
```Bash
cat <<EOF > ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base/virtualservice.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
spec:
  hosts:
  - "*"
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

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add resource virtualservice.yaml
```

## Update the Staging namespace overlay

Update the Staging Kustomize overlay with the proper `hosts` value in the `VirtualService` and with the `Deployments`'s container images to point to the private Artifact Registry:
```Bash
cat <<EOF >> ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging/kustomization.yaml
patchesJson6902:
- target:
    kind: VirtualService
    name: frontend
  patch: |-
    - op: replace
      path: /spec/hosts
      value:
        - ${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}
- target:
    kind: Deployment
    name: adservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/adservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: cartservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/cartservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: checkoutservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/checkoutservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: currencyservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/currencyservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: emailservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/emailservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: frontend
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/frontend:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: loadgenerator
  patch: |-
    - op: replace
      path: /spec/template/spec/initContainers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/busybox:latest
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/loadgenerator:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: paymentservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/paymentservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: productcatalogservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/productcatalogservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: recommendationservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/recommendationservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: shippingservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/shippingservice:${ONLINE_BOUTIQUE_VERSION}
- target:
    kind: Deployment
    name: redis-cart
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}/redis:alpine
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Online Boutique apps" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="gcloud" %}}
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{% tab name="UI" %}}
Alternatively, you could also see this from within the Cloud Console, by clicking on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/status?clusterName=${GKE_NAME}&id=${GKE_NAME}&project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `SYNCED`. And then you can also click on `View resources` to see the details.
{{% /tab %}}
{{< /tabs >}}

## Check the Online Boutique apps

Open the list of the **Workloads** deployed in the GKE cluster, you will see that the Online Boutique apps is successfully deployed. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/workload/overview?project=${TENANT_PROJECT_ID}"
```

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should receive the error: `RBAC: access denied`. This is because the default deny-all `AuthorizationPolicy` has been applied to the entire mesh. In the next section you will apply a fine granular `AuthorizationPolicy` for the Online Boutique apps in order to get fix this.