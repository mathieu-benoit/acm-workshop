---
title: "Deploy AuthorizationPolicies"
weight: 6
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["asm", "platform-admin", "security-tips"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will deploy granular and specific `AuthorizationPolicies` for the Ingress Gateway namespace.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define AuthorizationPolicy

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/authorizationpolicy_ingress-gateway.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: ${INGRESS_GATEWAY_NAME}
  rules:
  - to:
    - operation:
        ports:
        - "8080"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Ingress Gateway AuthorizationPolicy" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
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
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"`.
{{% /tab %}}
{{< /tabs >}}

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```