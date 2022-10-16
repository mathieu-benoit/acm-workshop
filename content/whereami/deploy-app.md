---
title: "Deploy app"
weight: 5
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy via Kustomize the Whereami app in the dedicated namespace.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME
kpt pkg get https://github.com/GoogleCloudPlatform/kubernetes-engine-samples/whereami/k8s
mv k8s upstream
```

## Update base overlay

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize edit add resource ../upstream
cat <<EOF >> ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/kustomization.yaml
patchesJson6902:
- target:
    kind: Service
    name: whereami
  patch: |-
    - op: replace
      path: /spec/type
      value: ClusterIP
EOF
```
{{% notice info %}}
Here we are changing the `Service` `type` to `ClusterIP` because the Whereami app will be exposed by the Ingress Gateway.
{{% /notice %}}

## Define VirtualService

Define the `VirtualService` resource in order to establish the Ingress Gateway routing to the Whereami app:
```Bash
cat <<EOF > ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/virtualservice.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: whereami
spec:
  hosts:
  - "*"
  gateways:
  - ${INGRESS_GATEWAY_NAMESPACE}/${INGRESS_GATEWAY_NAME}
  http:
  - route:
    - destination:
        host: whereami
        port:
          number: 80
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize edit add resource virtualservice.yaml
```

## Update Staging namespace overlay

Update the Staging Kustomize overlay in order to set the private container image and the proper `hosts` value in the `VirtualService` resource:
```Bash
cat <<EOF >> ${WORK_DIR}$WHERE_AMI_DIR_NAME/staging/kustomization.yaml
patchesJson6902:
- target:
    kind: Deployment
    name: whereami
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_WHEREAMI_IMAGE_NAME}
- target:
    kind: VirtualService
    name: whereami
  patch: |-
    - op: replace
      path: /spec/hosts
      value:
        - ${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/
git add . && git commit -m "Whereami app" && git push origin main
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

## Check the Whereami app

Open the list of the **Workloads** deployed in the GKE cluster, you will see that the Whereami app is successfully deployed. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/workload/overview?project=${TENANT_PROJECT_ID}"
```

Navigate to the Whereami app, click on the link displayed by the command below:
```Bash
echo -e "https://${WHERE_AMI_INGRESS_GATEWAY_HOST_NAME}"
```

You should receive the error: `RBAC: access denied`. This is because the default deny-all `AuthorizationPolicy` has been applied to the entire mesh. In the next section you will apply a fine granular `AuthorizationPolicy` for the Whereami app in order to get it working.