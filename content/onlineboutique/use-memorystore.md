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
cp -r ../upstream/components/memorystore/ .
sed -i "s/REDIS_CONNECTION_STRING/${REDIS_IP}:${REDIS_PORT}/g" memorystore/kustomization.yaml
kustomize edit add component memorystore
```
{{% notice info %}}
This will change the `REDIS_ADDR` environment variable of the `cartservice` to point to the Memorystore (redis) instance as well as removing the `Deployment` and the `Service` of the default in-cluster `redis` database container.
{{% /notice %}}

Update the previously deployed `Sidecars`, `NetworkPolicies`, `ServiceAccounts` and `AuthorizationPolicies`:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
kustomize edit add component ../upstream/sidecars/for-memorystore
cat <<EOF >> kustomization.yaml
- |-
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: redis-cart
  \$patch: delete
- |-
  apiVersion: security.istio.io/v1beta1
  kind: AuthorizationPolicy
  metadata:
    name: redis-cart
  \$patch: delete
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Use Memorystore (redis)" && git push origin main
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