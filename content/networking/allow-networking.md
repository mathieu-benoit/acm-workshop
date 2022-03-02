---
title: "Allow Networking"
weight: 1
---
- Persona: Org Admin
- Duration: 2 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

Define the `compute.networkAdmin` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the GKE project's service account:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/network-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: network-admin-${GKE_PROJECT_ID}
  namespace: config-control
spec:
  member: serviceAccount:${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
  role: roles/compute.networkAdmin
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
```

Deploy this Kubernetes manifest via a GitOps approach:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Network rights for GKE project"
git push
```