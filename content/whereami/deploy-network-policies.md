---
title: "Deploy NetworkPolicies"
weight: 3
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy granular and specific `NetworkPolicies` for the Whereami namespace. This will fix the policies violation you faced earlier. At the end you will catch another issue that you will resolve in the next section.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Create base overlay

Create Kustomize base overlay files:
```Bash
mkdir ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize create
```

## Deploy default deny-all NetworkPolicy

Define a default `deny-all` `NetworkPolicy`:
```Bash
cat <<EOF > ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/networkpolicy_deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize edit add resource networkpolicy_deny-all.yaml
```

## Define NetworkPolicy for the Whereami app

Define a fine granular `NetworkPolicy`:
```Bash
cat <<EOF > ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/networkpolicy_whereami.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: whereami
spec:
  podSelector:
    matchLabels:
      app: whereami
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ${INGRESS_GATEWAY_NAMESPACE}
      podSelector:
        matchLabels:
          app: ${INGRESS_GATEWAY_NAME}
    ports:
    - port: 8080
      protocol: TCP
  egress:
  - {}
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize edit add resource networkpolicy_whereami.yaml
```

## Define Staging namespace overlay

```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $WHEREAMI_NAMESPACE
```
{{% notice info %}}
The `kustomization.yaml` file was already existing from the [GitHub repository template](https://github.com/mathieu-benoit/config-sync-app-template-repo/blob/main/staging/kustomization.yaml) used when we created the `Whereami` app repository.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/
git add . && git commit -m "Whereami NetworkPolicies" && git push origin main
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

The `namespaces-required-networkpolicies` `Constraint` shouldn't complain anymore. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/object/constraints.gatekeeper.sh/k8srequirenamespacenetworkpolicies/${GKE_LOCATION}/${GKE_NAME}/namespaces-required-networkpolicies?apiVersion=v1beta1&project=${TENANT_PROJECT_ID}"
```

At the very bottom of the object's description you should now see:
```Plaintext
...
totalViolations: 0
```

List the GitHub runs for the **Whereami app** repository:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME && gh run list
```