---
title: "Deploy apps"
weight: 5
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy the Bank of Anthos apps.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME
kpt pkg get https://github.com/GoogleCloudPlatform/bank-of-anthos/kubernetes-manifests
mv kubernetes-manifests upstream
cd upstream
rm Kptfile
curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/bank-of-anthos/main/extras/jwt/jwt-secret.yaml > jwt-secret.yaml
kustomize create --autodetect
```

## Update base overlay

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base
kustomize edit add resource ../upstream
cat <<EOF >> ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/kustomization.yaml
patchesJson6902:
- target:
    kind: Service
    name: frontend
  patch: |-
    - op: replace
      path: /spec/type
      value: ClusterIP
EOF
```
{{% notice info %}}
Here we are changing the `Service` `type` to `ClusterIP` because the `frontend` app will be exposed by the Ingress Gateway.
{{% /notice %}}

## Define VirtualService

Define the `VirtualService` resource in order to establish the Ingress Gateway routing to the Online Boutique apps:
```Bash
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base/virtualservice.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend
spec:
  hosts:
  - "*"
  gateways:
  - ${INGRESS_GATEWAY_NAMESPACE}/${INGRESS_GATEWAY_NAME}
  http:
  - route:
    - destination:
        host: frontend
        port:
          number: 80
EOF
```

Update the Kustomize base overlay:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/base
kustomize edit add resource virtualservice.yaml
```

## Update the Staging namespace overlay

Set the proper `hosts` value in the `VirtualService`:
```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging/virtualservice
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging/virtualservice/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patchesJson6902:
- target:
    kind: VirtualService
    name: frontend
  patch: |-
    - op: replace
      path: /spec/hosts
      value:
        - ${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}
EOF
```

Update the `StatefulSets` and `Deployments`'s container images to point to the private Artifact Registry:
```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging/container-images
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging/container-images/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patchesJson6902:
- target:
    kind: StatefulSet
    name: accounts-db
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/accounts-db:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: Deployment
    name: balancereader
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/balancereader:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: Deployment
    name: contacts
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/contacts:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: Deployment
    name: frontend
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/frontend:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: StatefulSet
    name: ledger-db
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/ledger-db:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: Deployment
    name: ledgerwriter
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/ledgerwriter:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: Deployment
    name: loadgenerator
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/loadgenerator:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: Deployment
    name: transactionhistory
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/transactionhistory:${BANK_OF_ANTHOS_VERSION}
- target:
    kind: Deployment
    name: userservice
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: ${PRIVATE_BANK_OF_ANTHOS_REGISTRY}/userservice:${BANK_OF_ANTHOS_VERSION}
EOF
```

Update the `StatefulSets` and `Deployments`'s container images to point to the private Artifact Registry:
```Bash
mkdir ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging/disable-monitoring
cat <<EOF > ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging/disable-monitoring/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patchesStrategicMerge:
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: balancereader
  spec:
    template:
      spec:
        containers:
          - name: balancereader
            env:
            - name: ENABLE_TRACING
              value: "false"
            - name: ENABLE_METRICS
              value: "false"
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: contacts
  spec:
    template:
      spec:
        containers:
          - name: contacts
            env:
            - name: ENABLE_TRACING
              value: "false"
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: frontend
  spec:
    template:
      spec:
        containers:
          - name: frontend
            env:
            - name: ENABLE_TRACING
              value: "false"
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: ledgerwriter
  spec:
    template:
      spec:
        containers:
          - name: ledgerwriter
            env:
            - name: ENABLE_TRACING
              value: "false"
            - name: ENABLE_METRICS
              value: "false"
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: transactionhistory
  spec:
    template:
      spec:
        containers:
          - name: transactionhistory
            env:
            - name: ENABLE_TRACING
              value: "false"
            - name: ENABLE_METRICS
              value: "false"
- |-
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: userservice
  spec:
    template:
      spec:
        containers:
          - name: userservice
            env:
            - name: ENABLE_TRACING
              value: "false"
EOF
```

Update the Staging Kustomize overlay:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/staging
kustomize edit add component virtualservice
kustomize edit add component container-images
kustomize edit add component disable-monitoring
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME/
git add . && git commit -m "Bank of Anthos apps" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Bank of Anthos apps** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="gcloud" %}}
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $BANKOFANTHOS_NAMESPACE
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

List the GitHub runs for the **Bank of Anthos apps** repository:
```Bash
cd ${WORK_DIR}$BANK_OF_ANTHOS_DIR_NAME && gh run list
```

## Check the Bank of Anthos apps

Open the list of the **Workloads** deployed in the GKE cluster, click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/workload/overview?project=${TENANT_PROJECT_ID}"
```

There, you will see on the `balancereader`,  `ledgerwriter`, `transactionhistory` workloads this error message: `Does not have minimum availability`. We will fix these errors in the next section.

Navigate to the Bank of Anthos apps, click on the link displayed by the command below:
```Bash
echo -e "https://${BANK_OF_ANTHOS_INGRESS_GATEWAY_HOST_NAME}"
```

You should receive the error: `RBAC: access denied`. This is because the default deny-all `AuthorizationPolicy` has been applied to the entire mesh. In the next section you will apply a fine granular `AuthorizationPolicy` for the Bank of Anthos apps in order to fix this.