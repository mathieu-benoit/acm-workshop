---
title: "Use Memorystore"
weight: 11
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will update the OnlineBoutique's `cartservice` app in order to point to the Memorystore (redis) instance previously created.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Update Staging namespace overlay

Get Memorystore (redis) connection information:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$TENANT_PROJECT_ID --format='get(port)')
```

Update the Online Boutique apps with the new Memorystore (redis) connection information:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
cp -r ../upstream/base/for-memorystore/ .
sed -i "s/REDIS_IP/${REDIS_IP}/g;s/REDIS_PORT/${REDIS_PORT}/g" for-memorystore/kustomization.yaml
kustomize edit add component for-memorystore
```
{{% notice info %}}
This will change the `REDIS_ADDR` environment variable of the `cartservice` to point to the Memorystore (redis) instance as well as removing the `Deployment` and the `Service` of the default in-cluster `redis` database container.
{{% /notice %}}

Update the previously deployed `Sidecars`, `NetworkPolicies` and `AuthorizationPolicies`:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
kustomize edit add component ../upstream/sidecars/for-memorystore
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
cat <<EOF >> network-policies/kustomization.yaml
patchesStrategicMerge:
- |-
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: redis-cart
  \$patch: delete
EOF
kustomize edit add component ../upstream/service-accounts/for-memorystore
kustomize edit add component ../upstream/authorization-policies/for-memorystore
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Secure Memorystore (redis) access" && git push origin main
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

You should still have the Online Boutique apps working successfully, but now with an external Memorystore (redis) database.