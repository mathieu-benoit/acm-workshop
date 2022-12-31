---
title: "Deploy AuthorizationPolicy"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will see how to track the `AuthorizationPolicies` issue and then you will deploy granular and specific `AuthorizationPolicies` for the Whereami namespace to fix this issue.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## See the `AuthorizationPolicies` issue

See the `AuthorizationPolicies` issue in the **GKE cluster** for the Whereami app, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/anthos/security/workload-view/Deployment/${GKE_LOCATION}/${GKE_NAME}/${WHEREAMI_NAMESPACE}/whereami?project=${TENANT_PROJECT_ID}"
```

Under the **Service requests** section on this page, you will see some **Inbound denials** depending on how many times you tried to refresh the Whereami app endpoint. If you click on **View logs** you will be able to see via Cloud Logging the details of the errors. That's where you will the logs with `status: 403` and `response_details: "AuthzDenied"`.

Let's fix it!

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

You should now have the Whereami app working successfully. Congrats!