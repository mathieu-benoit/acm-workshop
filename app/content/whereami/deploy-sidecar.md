---
title: "Deploy Sidecar"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy a fine granular `Sidecar` in order to optimize the resources (CPU/Memory) usage of the Whereami app's sidecar proxy. By default, each application in the `whereami` `Namespace` can reach to all the endpoints in the mesh. The `Sidecar` resource allows to reduce that list to the strict minimum of which endpoints it needs to communicate with.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Sidecar

```Bash
cat <<EOF > ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/sidecar.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: whereami
spec:
  workloadSelector:
    labels:
      app: whereami
  egress:
  - hosts:
    - istio-system/*
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize edit add resource sidecar.yaml
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/
git add . && git commit -m "Whereami Sidecar" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Whereami app** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="UI" %}}
Run this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/packages?project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `Synced` and the `Reconcile status` column as `Current`.
{{% /tab %}}
{{% tab name="gcloud" %}}
Run this command:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **Whereami app** repository:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME && gh run list
```

## Check the Whereami app

Navigate to the Whereami app, click on the link displayed by the command below:
```Bash
echo -e "https://${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
```

You should still have the Whereami app working successfully.