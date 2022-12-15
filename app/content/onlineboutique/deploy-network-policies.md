---
title: "Deploy NetworkPolicies"
weight: 3
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy granular and specific `NetworkPolicies` for the Online Boutique namespace. This will fix the policies violation you faced earlier.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
kpt pkg get https://github.com/GoogleCloudPlatform/microservices-demo.git/kustomize@main ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream
rm ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream/tests -rf
rm ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream/Kptfile
rm ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream/kustomization.yaml
```

## Update the Kustomize base overlay

```Bash
mkdir ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/base
mkdir network-policies
cat <<EOF >> network-policies/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patchesJson6902:
- target:
    kind: NetworkPolicy
    name: frontend
  patch: |-
    - op: replace
      path: /spec/ingress
      value:
        - from:
          - podSelector:
              matchLabels:
                app: loadgenerator
          - namespaceSelector:
              matchLabels:
                name: ${INGRESS_GATEWAY_NAMESPACE}
            podSelector:
              matchLabels:
                app: ${INGRESS_GATEWAY_NAME}
          ports:
          - port: 8080
            protocol: TCP
EOF
kustomize create
kustomize edit add component ../upstream/components/network-policies
kustomize edit add component network-policies
```

## Define Staging namespace overlay

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/staging
kustomize edit add resource ../base
kustomize edit set namespace $ONLINEBOUTIQUE_NAMESPACE
```
{{% notice info %}}
The `kustomization.yaml` file was already existing from the [GitHub repository template](https://github.com/mathieu-benoit/config-sync-app-template-repo/blob/main/staging/kustomization.yaml) used when we created the **Online Boutique apps** repository.
{{% /notice %}}

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Online Boutique NetworkPolicies" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository:
{{< tabs groupId="cs-status-ui">}}
{{% tab name="gcloud" %}}
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
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

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```