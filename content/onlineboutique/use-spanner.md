---
title: "Use Spanner"
weight: 15
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will update the OnlineBoutique's `cartservice` app in order to point to the Spanner database previously created.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Update Staging namespace overlay

Update the Online Boutique apps with the Spanner database connection information:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
cp -r ../upstream/components/spanner/ .
sed -i "s/SPANNER_INSTANCE/${SPANNER_INSTANCE_NAME}/g" spanner/kustomization.yaml
sed -i "s/SPANNER_DATABASE/${SPANNER_DATABASE_NAME}/g" spanner/kustomization.yaml
sed -i "s/SPANNER_PROJECT/${TENANT_PROJECT_ID}/g" spanner/kustomization.yaml
sed -i "s/SPANNER_DB_USER_GSA_ID/${SPANNER_DATABASE_USER_GSA_NAME}@${TENANT_PROJECT_ID}.iam.gserviceaccount.com/g" spanner/kustomization.yaml
sed -i "s/- memorystore//g" kustomization.yaml
kustomize edit add component spanner
```
{{% notice info %}}
This will change the `SPANNER_CONNECTION_STRING` environment variable of the `cartservice` to point to the Spanner database as well as removing the `Deployment` and the `Service` of the default in-cluster `redis` database container.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Use Spanner" && git push origin main
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

You should still have the Online Boutique apps working successfully, but now with an external Spanner database.