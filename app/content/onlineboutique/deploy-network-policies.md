---
title: "Deploy NetworkPolicies"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy granular and specific `NetworkPolicies` for the Online Boutique namespace.

FIXME

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

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

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository from within the Cloud Console, by clicking on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```

The `namespaces-required-networkpolicies` `Constraint` shouldn't complain anymore. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/object/constraints.gatekeeper.sh/k8srequirenamespacenetworkpolicies/${GKE_LOCATION}/${GKE_NAME}/namespaces-required-networkpolicies?apiVersion=v1beta1&project=${TENANT_PROJECT_ID}"
```

At the very bottom of the object's description you should now see:
```Plaintext
...
totalViolations: 0
```

## Check the Online Boutique apps

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Online Boutique apps working successfully.