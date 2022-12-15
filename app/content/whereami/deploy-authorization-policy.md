---
title: "Deploy AuthorizationPolicy"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy a granular and specific `AuthorizationPolicy` for the Whereami namespace. At the end that's where you will finally have a working Whereami app :)

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define AuthorizationPolicy

Define a fine granular `AuthorizationPolicy`:
```Bash
cat <<EOF > ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/authorizationpolicy_whereami.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: whereami
spec:
  selector:
    matchLabels:
      app: whereami
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/${INGRESS_GATEWAY_NAMESPACE}/sa/${INGRESS_GATEWAY_NAME}
    to:
    - operation:
        ports:
        - "8080"
        methods:
        - GET
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize edit add resource authorizationpolicy_whereami.yaml
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/
git add . && git commit -m "Whereami AuthorizationPolicy" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Whereami app** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="gcloud" %}}
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{% tab name="UI" %}}
Alternatively, you could also see this from within the Cloud Console, by clicking on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/config_management/status?clusterName=${GKE_NAME}&id=${GKE_NAME}&project=${TENANT_PROJECT_ID}"
```
Wait until you see the `Sync status` column as `SYNCED`. And then you can also click on `View resources` to see the details.
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

You should now have the Whereami app working successfully. Congrats!