---
title: "Allow ASM"
weight: 1
---
- Persona: Org Admin
- Duration: 5 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

Enable the Mesh API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource in the GKE project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/mesh-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: mesh.googleapis.com
  namespace: config-control
EOF
```

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "ASM rights for GKE project"
git push
```