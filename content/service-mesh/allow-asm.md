---
title: "Allow ASM"
weight: 1
---
- Persona: Org Admin
- Duration: 5 min
- Objectives:
  - FIXME

Enable the Mesh API in the GKE project:
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

Apply and deploy all these Kubernetes manifests:
{{< tabs groupId="commit">}}
{{% tab name="git commit" %}}
Let's deploy them via a GitOps approach:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Setting up ASM rights for project ${GKE_PROJECT_ID}."
git push
```
{{% /tab %}}
{{% tab name="kubectl apply" %}}
Alternatively, you could directly apply them via the Config Controller's Kubernetes Server API:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
kubectl apply -f .
```
{{% /tab %}}
{{< /tabs >}}