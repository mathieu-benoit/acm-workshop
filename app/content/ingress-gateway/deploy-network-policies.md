---
title: "Deploy NetworkPolicies"
weight: 5
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin", "security-tips", "policies"]
---
![Platform Admin](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/platform-admin.png)
_{{< param description >}}_

In this section, you will see the Policy Controller violation regarding to the missing `NetworkPolicies` in the Ingress Gateway. Finally, you will fix this violation by deploying the associated resources.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## See the Policy Controller violations

See the Policy Controller violations in the **GKE cluster**, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

You will see that the `K8sRequireNamespaceNetworkPolicies` `Constraint` has this violation: `Namespace <asm-ingress> does not have a NetworkPolicy`.

Let's fix it!

## Define NetworkPolicies

```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_denyall.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: denyall
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/$INGRESS_GATEWAY_NAMESPACE/networkpolicy_ingress-gateway.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ${INGRESS_GATEWAY_NAME}
  namespace: ${INGRESS_GATEWAY_NAMESPACE}
spec:
  podSelector:
    matchLabels:
      app: ${INGRESS_GATEWAY_NAME}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
  - {}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Ingress Gateway NetworkPolicies" && git push origin main
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

See the Policy Controller `Constraints` without any violations in the **GKE cluster**, by running this command and click on this link:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/policy_controller/dashboard?project=${TENANT_PROJECT_ID}"
```

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```