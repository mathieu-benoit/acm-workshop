---
title: "Create Spanner"
weight: 14
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["kcc", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will create a Spanner instance and database for the Online Boutique's `cartservice` app to connect to. You will also configure the associated `cartservice`'s Google Service account to have fine granular read access to the Spanner database via Workload Identity.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export SPANNER_INSTANCE_NAME=onlineboutique" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export SPANNER_DATABASE_NAME=carts" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export SPANNER_DATABASE_USER_GSA_NAME=spanner-db-user" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Create (if not yet existing) a folder dedicated for any resources related Online Boutique specifically: 
```Bash
mkdir -p ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Spanner instance

Define the [Spanner instance resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/spanner/spannerinstance):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/spanner-instance.yaml
apiVersion: spanner.cnrm.cloud.google.com/v1beta1
kind: SpannerInstance
metadata:
  name: ${SPANNER_INSTANCE_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  config: regional-${GKE_LOCATION}
  displayName: ${SPANNER_INSTANCE_NAME}
  numNodes: 2
EOF
```

## Define Spanner database

Define the [Spanner database resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/spanner/spannerdatabase):
```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/spanner-database.yaml
apiVersion: spanner.cnrm.cloud.google.com/v1beta1
kind: SpannerDatabase
metadata:
  name: ${SPANNER_DATABASE_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: spanner.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/SpannerInstance/${SPANNER_INSTANCE_NAME}
spec:
  instanceRef:
    name: ${SPANNER_INSTANCE_NAME}
  databaseDialect: GOOGLE_STANDARD_SQL
  ddl:
  - "CREATE TABLE CartItems (userId STRING(1024), productId STRING(1024), quantity INT64,) PRIMARY KEY (userId, productId)"
  - "CREATE INDEX CartItemsByUserId ON CartItems(userId)"
EOF
```

## Grant the `cartservice`'s service account access to the Spanner database

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/spanner-db-user-service-account.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${SPANNER_DATABASE_USER_GSA_NAME}
  namespace: ${TENANT_PROJECT_ID}
spec:
  displayName: ${SPANNER_DATABASE_USER_GSA_NAME}
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/spanner-db-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: ${SPANNER_DATABASE_USER_GSA_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${SPANNER_DATABASE_USER_GSA_NAME},spanner.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/SpannerDatabase/${SPANNER_DATABASE_NAME}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${SPANNER_DATABASE_USER_GSA_NAME}
      namespace: ${TENANT_PROJECT_ID}
  resourceRef:
    kind: SpannerDatabase
    name: ${SPANNER_DATABASE_NAME}
  role: roles/spanner.databaseUser
EOF
```

```Bash
cat <<EOF > ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/$ONLINEBOUTIQUE_NAMESPACE/spanner-db-user-workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: ${SPANNER_DATABASE_USER_GSA_NAME}
  namespace: ${TENANT_PROJECT_ID}
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/${TENANT_PROJECT_ID}/IAMServiceAccount/${SPANNER_DATABASE_USER_GSA_NAME}
spec:
  resourceRef:
    name: ${SPANNER_DATABASE_USER_GSA_NAME}
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${TENANT_PROJECT_ID}.svc.id.goog[${ONLINEBOUTIQUE_NAMESPACE}/cartservice]
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME/
git add . && git commit -m "Spanner instance and database and configure cartservice's gsa" && git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  SpannerInstance-.->Project
  SpannerDatabase-->SpannerInstance
  IAMServiceAccount-.->Project
  IAMPolicyMember-->SpannerDatabase
  IAMPolicyMember-->IAMServiceAccount
{{< /mermaid >}}

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Tenant project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $TENANT_PROJECT_ID
```
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Tenant project configs** repository:
```Bash
cd ${WORK_DIR}$TENANT_PROJECT_DIR_NAME && gh run list
```

List the Google Cloud resources created:
```Bash
gcloud spanner instances list \
    --project=$TENANT_PROJECT_ID
gcloud spanner databases list \
    --instance $SPANNER_INSTANCE_NAME \
    --project=$TENANT_PROJECT_ID
gcloud spanner databases get-iam-policy $SPANNER_DATABASE_NAME \
    --project $TENANT_PROJECT_ID \
    --instance $SPANNER_INSTANCE_NAME
    --filter="bindings.members:${SPANNER_DATABASE_USER_GSA_NAME}@${TENANT_PROJECT_ID}.iam.gserviceaccount.com" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```