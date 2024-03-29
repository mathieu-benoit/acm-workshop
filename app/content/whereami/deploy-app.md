---
title: "Deploy app"
weight: 5
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](https://github.com/mathieu-benoit/my-images/raw/main/acm-workshop/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy the Whereami app.

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
rm k8s/Kptfile
mv k8s upstream
```

## Create base overlay

Create Kustomize base overlay files:
```Bash
mkdir ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/base
kustomize create
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

## Define Staging namespace overlay

```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $WHEREAMI_NAMESPACE
```
{{% notice info %}}
The `kustomization.yaml` file was already existing from the [GitHub repository template](https://github.com/mathieu-benoit/config-sync-app-template-repo/blob/main/staging/kustomization.yaml) used when we created the **Whereami app** repository.
{{% /notice %}}

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

You should see the error: `RBAC: access denied`. In the next section, you will see how to track this error and how to fix it.