---
title: "Use Memorystore"
weight: 4
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will update the OnlineBoutique's `cartservice` app in order to point to the Memorystore (Redis) instance previously created.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Update `RepoSync` to deploy the Online Boutique's Helm chart

Get Memorystore (Redis) connection information:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region $GKE_LOCATION --project $TENANT_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region $GKE_LOCATION --project $TENANT_PROJECT_ID --format='get(port)')
```

Define the `RepoSync` to deploy the Online Boutique's Helm chart with the `cartservice` pointing to the Memorystore (Redis) database:
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
          create: false
        connectionString: ${REDIS_IP}:${REDIS_PORT}
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
      serviceAccounts:
        create: true
      authorizationPolicies:
        create: true
      networkPolicies:
        create: true
      sidecars:
        create: true
```

{{% notice info %}}
This will change the `REDIS_ADDR` environment variable of the `cartservice` to point to the Memorystore (Redis) database as well as removing the `Deployment` and the `Service` of the default in-cluster `redis` database.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Use Memorystore (Redis)" && git push origin main
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

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Online Boutique apps working successfully, but now with an external Memorystore (Redis) database.