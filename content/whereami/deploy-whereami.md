---
title: "Deploy Whereami app"
weight: 3
description: "Duration: 10 min | Persona: Apps Operator"
tags: ["apps-operator", "asm"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

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

## Create base overlay

Create Kustomize base overlay files:
```Bash
mkdir ~/$WHERE_AMI_DIR_NAME/base
cd ~/$WHERE_AMI_DIR_NAME/base
kustomize create --resources ../upstream
cat <<EOF >> ${WORK_DIR}$WHERE_AMI_DIR_NAME/base/kustomization.yaml
configMapGenerator:
- name: whereami-configmap
  behavior: merge
  literals:
  - TRACE_SAMPLING_RATIO="0"
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
Here we are disabling tracing from the upstream files as well as changing the `Service` `type` to `ClusterIP`.
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
The `kustomization.yaml` file was already existing from the [GitHub repository template](https://github.com/mathieu-benoit/config-sync-app-template-repo/blob/main/staging/kustomization.yaml) used when we created the `Whereami` app repository.
{{% /notice %}}

Update the Kustomize base overlay in order to set proper `hosts` value in the `VirtualService` resource:
```Bash
cat <<EOF >> ${WORK_DIR}$WHERE_AMI_DIR_NAME/staging/kustomization.yaml
patchesJson6902:
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
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $WHEREAMI_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

We haven't yet deployed any `NetworkPolicies` in the `whereami` `Namespace`, the `namespaces-required-networkpolicies` `Constraint` should still complain. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/object/constraints.gatekeeper.sh/k8srequirenamespacenetworkpolicies/${GKE_LOCATION}/${GKE_NAME}/namespaces-required-networkpolicies?apiVersion=v1beta1&project=${TENANT_PROJECT_ID}"
```

At the very bottom of the object's description you should still see:
```Plaintext
...
totalViolations: 1
  violations:
  - enforcementAction: dryrun
    kind: Namespace
    message: Namespace <whereami> does not have a NetworkPolicy
    name: whereami
```

The next section will deploy the `NetworkPolicies` in the `whereami` `Namespace` in order to fix this issue.

List the GitHub runs for the **Whereami app** repository:
```Bash
cd ${WORK_DIR}$WHERE_AMI_DIR_NAME && gh run list
```