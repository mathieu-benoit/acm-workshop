---
title: "Allow GKE Hub"
weight: 4
---

- Persona: Org Admin
- Duration: 5 min
- Objectives:
  - FIXME

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

Enable the GKE Hub API in the GKE project:
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

Enable the GKE API in the GKE project:
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

{{< tabs groupId="commit">}}
{{% tab name="git commit" %}}
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Setting up GKE Hub rights for project ${GKE_PROJECT_ID}."
git push
```
{{% /tab %}}
{{% tab name="kubectl apply" %}}
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
kubectl apply -f .
```
{{% /tab %}}
{{< /tabs >}}