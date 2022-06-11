---
title: "Deploy apps"
weight: 3
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
Here, we are removing the upstream `Namespace` resource as we already defined it in a previous section while configuring the associated Config Sync's `RepoSync` setup.
{{% /notice %}}

You could browse the files in the `${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream/base` folder, along with the `Namespace`, `Deployment` and `Service` for the OnlineBoutique apps, you could see the  `VirtualService` resource which will allow to establish the Ingress Gateway routing to the OnlineBoutique app. The `spec.hosts` value is `"*"` but in the following part you will replace this value by the actual DNS of the OnlineBoutique solution (i.e. `ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME`) defined in a previous section.

## Define Staging namespace overlay

Here are the updates for the overlay files needed to define the Staging namespace:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $ONLINEBOUTIQUE_NAMESPACE
cp -r ../upstream/base/for-virtualservice-host/ .
sed -i "s/HOST_NAME/${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}/g" for-virtualservice-host/kustomization.yaml
kustomize edit add component for-virtualservice-host
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