---
title: "Allow GKE Hub"
weight: 3
---
- Persona: Org Admin
- Duration: 5 min
- Objectives:
  - FIXME

Define the `gkehub.admin` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the GKE project's service account:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/gke-hub-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: gke-hub-admin-${GKE_PROJECT_ID}
  namespace: config-control
spec:
  member: serviceAccount:${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
  role: roles/gkehub.admin
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
```

Define the GKE Hub API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the GKE project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/gke-hub-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: gkehub.googleapis.com
  namespace: config-control
EOF
```

Define the GKE API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the GKE project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/anthos-configmanagement-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: anthosconfigmanagement.googleapis.com
  namespace: config-control
EOF
```

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "GKE Hub rights for GKE project"
git push
```