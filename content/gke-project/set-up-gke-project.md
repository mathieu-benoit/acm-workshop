---
title: "Set up GKE project"
weight: 1
---

- Persona: Org Admin
- Duration: 20 min
- Objectives:
  - FIXME

```Bash
GKE_PROJECT_ID=${PREFIX}workshop-${RANDOM_SUFFIX}
mkdir ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects
mkdir ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/project.yaml
apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
kind: Project
metadata:
  annotations:
    cnrm.cloud.google.com/auto-create-network: "false"
  name: ${GKE_PROJECT_ID}
  namespace: config-control
spec:
  name: ${GKE_PROJECT_ID}
  billingAccountRef:
    external: "${BILLING_ACCOUNT_ID}"
  organizationRef:
    external: "${ORG_ID}"
  resourceID: ${GKE_PROJECT_ID}
EOF
# FIXME - alternative with Folder Id

cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/service-account.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMServiceAccount
metadata:
  name: ${GKE_PROJECT_ID}
  namespace: config-control
spec:
  displayName: ${GKE_PROJECT_ID}
EOF
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/workload-identity-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPartialPolicy
metadata:
  name: ${GKE_PROJECT_ID}-sa-workload-identity-binding
  namespace: config-control
spec:
  resourceRef:
    name: ${GKE_PROJECT_ID}
    apiVersion: iam.cnrm.cloud.google.com/v1beta1
    kind: IAMServiceAccount
  bindings:
    - role: roles/iam.workloadIdentityUser
      members:
        - member: serviceAccount:${CONFIG_CONTROLLER_PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager-${GKE_PROJECT_ID}]
EOF

cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
  labels:
    owner: ${GKE_PROJECT_ID}
  name: ${GKE_PROJECT_ID}
EOF
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/config-connector-context.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnectorContext
metadata:
  name: configconnectorcontext.core.cnrm.cloud.google.com
  namespace: ${GKE_PROJECT_ID}
spec:
  googleServiceAccount: ${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
EOF

cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Setting up ${GKE_PROJECT_ID} namespace/project."
git push
```