---
title: "Deploy apps"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "helm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy the Online Boutique apps, via Config Sync and its Helm chart.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define `RepoSync` to deploy the Online Boutique's Helm chart

Define the `RepoSync` to deploy the Online Boutique's Helm chart:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/repo-syncs/$ONLINEBOUTIQUE_NAMESPACE/repo-sync.yaml
apiVersion: configsync.gke.io/v1beta1
kind: RepoSync
metadata:
  name: repo-sync
  namespace: ${ONLINEBOUTIQUE_NAMESPACE}
spec:
  sourceFormat: unstructured
  sourceType: helm
  helm:
    repo: oci://${CHART_REGISTRY_REPOSITORY}
    chart: ${ONLINEBOUTIQUE_NAMESPACE}
    version: ${ONLINE_BOUTIQUE_VERSION:1}
    releaseName: ${ONLINEBOUTIQUE_NAMESPACE}
    auth: gcpserviceaccount
    gcpServiceAccountEmail: ${HELM_CHARTS_READER_GSA}@${TENANT_PROJECT_ID}.iam.gserviceaccount.com
    values:
      cartDatabase:
        inClusterRedis:
          publicRepository: false
      images:
        repository: ${PRIVATE_ONLINE_BOUTIQUE_REGISTRY}
        tag: ${ONLINE_BOUTIQUE_VERSION}
      nativeGrpcHealthCheck: true
      seccompProfile:
        enable: true
      loadGenerator:
        checkFrontendInitContainer: false
      frontend:
        externalService: false
        virtualService:
          create: true
          gateway:
            name: ${INGRESS_GATEWAY_NAME}
            namespace: ${INGRESS_GATEWAY_NAMESPACE}
            labelKey: asm
            labelValue: ingressgateway
          hosts:
          - ${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}
EOF
```

{{% notice info %}}
Here we are deleting the `Service` `frontend-external` because the `frontend` app will be exposed by the Ingress Gateway. The associated `VirtualService` will be generated in order to establish the link between the Ingress Gateway and the Online Boutique's `frontend` app. We are also updating the container image repository to use our own private Artifact Registry. Finally, we are also leveraging more secure feature such as `nativeGrpcHealthCheck` and `seccompProfile`. You could read more [here](https://medium.com/google-cloud/246119e46d53) about all the options the Online Boutique's Helm chart exposes.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Online Boutique apps" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```

## Check the Online Boutique apps

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should see the error: `RBAC: access denied`. In the next section, you will see how to track this error and how to fix it.