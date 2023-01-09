---
title: "Deploy AuthorizationPolicies"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "helm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will see how to track the `AuthorizationPolicies` issue and then you will deploy granular and specific `AuthorizationPolicies` for the Online Boutique namespace to fix this issue.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## See the `AuthorizationPolicies` issue

See the `AuthorizationPolicies` issue in the **GKE cluster** for the Online Boutique apps, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/anthos/security/workload-view/Deployment/${GKE_LOCATION}/${GKE_NAME}/${ONLINEBOUTIQUE_NAMESPACE}/frontend?project=${TENANT_PROJECT_ID}"
```

Under the **Service requests** section on this page, you will see some **Inbound denials**. If you click on **View logs** you will be able to see via Cloud Logging the details of the errors. That's where you will the logs with `status: 403` and `response_details: "AuthzDenied"`.

Let's fix it!

## Update `RepoSync` to deploy the Online Boutique's Helm chart

Define the `RepoSync` to deploy the Online Boutique's Helm chart with both the `AuthorizationPolicies` and `ServiceAccounts`:
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
      serviceAccounts:
        create: true
      authorizationPolicies:
        create: true
EOF
```

{{% notice info %}}
In order to deploy the fine granular `AuthorizationPolicies` and `ServiceAccounts`, one of each per app, we just updated the list of `values` of the Online Boutique's Helm chart previously configured, with `serviceAccounts.create: true` and `authorizationPolicies.create: true`.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Online Boutique AuthorizationPolicies and ServiceAccounts" && git push origin main
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

## Check the Online Boutique website

Navigate to the Online Boutique website, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should now have the Online Boutique website working successfully. Congrats!