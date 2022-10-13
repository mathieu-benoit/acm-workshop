---
title: "Deploy apps"
weight: 4
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy via Kustomize the Online Boutique apps in the dedicated namespace.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME
mkdir upstream
cd upstream
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/base@main
```

## Create base overlay

Create Kustomize base overlay files:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME
mkdir base
cd base
kustomize create --resources ../upstream/base/all
cat <<EOF >> kustomization.yaml
patchesStrategicMerge:
- |-
  apiVersion: v1
  kind: Namespace
  metadata:
    name: onlineboutique
  \$patch: delete
EOF
```
{{% notice info %}}
We are removing the upstream `Namespace` resource as we already defined it in a previous section while configuring the associated Config Sync's `RepoSync` setup.
{{% /notice %}}

You could browse the files in the `${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream/base` folder, along with the `Namespace`, `Deployment` and `Service` for the OnlineBoutique apps, you could see the `VirtualService` resource which will allow to establish the Ingress Gateway routing to the OnlineBoutique app. The `spec.hosts` value is `"*"` but in the following part you will replace this value by the actual DNS of the OnlineBoutique solution (i.e. `ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME`) defined in a previous section.

## Define Staging namespace overlay

Update the overlay files needed to define the Staging namespace:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $ONLINEBOUTIQUE_NAMESPACE
cp -r ../upstream/base/for-virtualservice-host/ .
sed -i "s/HOST_NAME/${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}/g" for-virtualservice-host/kustomization.yaml
kustomize edit add component for-virtualservice-host
```

Update the `Deployments`'s container images to point to the private Artifact Registry:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
cat <<EOF >> ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging/kustomization.yaml
patchesJson6902:
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
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```

## Check the Online Boutique apps

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You will see that the Online Boutique website is not working.

Open the list of the **Workloads** deployed in the GKE cluster, click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/workload/overview?project=${TENANT_PROJECT_ID}"
```

Here you could see that all the Online Boutique `Deployments` are in `Error`. If you look at more details on the `Pods` you will see this error:
```Plaintext
Readiness probe failed: Get "http://10.4.2.13:15020/app-health/server/readyz": dial tcp 10.4.2.13:15020: connect: connection refused
```

At this stage, that's expected because we have deployed the `deny-all` `NetworkPolicy` in the `onlineboutique` `Namespace` blocking any ingress and egress requests to and from any app in this `Namespace`. We will fix this in the next sections.