---
title: "Deploy AuthorizationPolicies"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy granular and specific `AuthorizationPolicies` for the Online Boutique namespace. At the end that's where you will finally have working Online Boutique apps :)

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream
kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-samples.git/docs/online-boutique-asm-manifests/authorization-policies@main
```

## Update the Kustomize base overlay

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add component ../upstream/components/service-accounts
kustomize edit add component ../upstream/authorization-policies/all
```

## Update Staging namespace overlay

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
mkdir authorization-policies
cp -r ../upstream/authorization-policies/for-namespace/ authorization-policies/.
sed -i "s/ONLINEBOUTIQUE_NAMESPACE/${ONLINEBOUTIQUE_NAMESPACE}/g" authorization-policies/for-namespace/kustomization.yaml
kustomize edit add component authorization-policies/for-namespace
cp -r ../upstream/authorization-policies/for-ingress-gateway/ authorization-policies/.
sed -i "s/ONLINEBOUTIQUE_NAMESPACE/${ONLINEBOUTIQUE_NAMESPACE}/g;s/INGRESS_GATEWAY_NAMESPACE/${INGRESS_GATEWAY_NAMESPACE}/g;s/INGRESS_GATEWAY_NAME/${INGRESS_GATEWAY_NAME}/g" authorization-policies/for-ingress-gateway/kustomization.yaml
kustomize edit add component authorization-policies/for-ingress-gateway
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Online Boutique AuthorizationPolicies" && git push origin main
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

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```

## Check the Online Boutique apps

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should now have the Online Boutique apps working successfully. Congrats!