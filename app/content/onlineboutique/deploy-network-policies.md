---
title: "Deploy NetworkPolicies"
weight: 8
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "helm", "policies", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will see the Policy Controller violation regarding to the missing `NetworkPolicies` in the Online Boutique namespace. Then, you will fix this violation by deploying the associated resources.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## See the Policy Controller violations

See the Policy Controller violations in the **GKE cluster**, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

You will see that the `K8sRequireNamespaceNetworkPolicies` `Constraint` has this violation: `Namespace <onlineboutique> does not have a NetworkPolicy`.

Let's fix it!

## Update `RepoSync` to deploy the Online Boutique's Helm chart

Define the `RepoSync` to deploy the Online Boutique's Helm chart with the `NetworkPolicies`:
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
      networkPolicies:
        create: true
EOF
```

{{% notice info %}}
In order to deploy the fine granular `NetworkPolicies`, one per app, we just updated the list of `values` of the Online Boutique's Helm chart previously configured, with `networkPolicies.create: true`.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Online Boutique NetworkPolicies" && git push origin main
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

See the Policy Controller `Constraints` without any violations in the **GKE cluster**, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

## Check the Online Boutique website

Navigate to the Online Boutique website, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Online Boutique website working successfully.