---
title: "Deploy apps"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
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
    gcpServiceAccountEmail: ${HELM_CHARTS_READER_GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
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
Here we are deleting the `Service` `frontend-external` because the `frontend` app will be exposed by the Ingress Gateway.
{{% /notice %}}

Define the `VirtualService` resource in order to establish the Ingress Gateway routing to the Online Boutique apps.

Update the Staging Kustomize overlay with the proper `hosts` value in the `VirtualService`.

Update the Staging Kustomize overlay with the `Deployments`'s container images pointing to the private Artifact Registry.

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Online Boutique apps" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository from within the Cloud Console, by clicking on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```

## Check the Online Boutique apps

Open the list of the **Workloads** deployed in the GKE cluster, you will see that the Online Boutique apps is successfully deployed. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/workload/overview?project=${TENANT_PROJECT_ID}"
```

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should see the error: `RBAC: access denied`. In the next section, you will see how to track this error and how to fix it.