---
title: "Deploy NetworkPolicies"
weight: 6
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["apps-operator", "security-tips"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy granular and specific `NetworkPolicies` for the Online Boutique namespace. This will fix the policies violation you faced earlier. At the end you will catch another issue that you will resolve in the next section.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Get upstream Kubernetes manifests

Get the upstream Kubernetes manifests:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/upstream
kpt pkg get https://github.com/GoogleCloudPlatform/microservices-demo.git/docs/network-policies@main
cd network-policies
kustomize create --autodetect
kustomize edit remove resource Kptfile
```

## Update the Kustomize base overlay

```Bash
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
kustomize edit add resource ../upstream/network-policies
kustomize edit add component network-policies
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME/
git add . && git commit -m "Online Boutique NetworkPolicies" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **Online Boutique apps** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name repo-sync \
    --sync-namespace $ONLINEBOUTIQUE_NAMESPACE
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Online Boutique apps** repository:
```Bash
cd ${WORK_DIR}$ONLINE_BOUTIQUE_DIR_NAME && gh run list
```

## Check the Online Boutique apps

Open the list of the **Workloads** deployed in the GKE cluster, you will now see that all the Online Boutique apps are working. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/kubernetes/workload/overview?project=${TENANT_PROJECT_ID}"
```

Navigate to the Online Boutique apps, click on the link displayed by the command below:
```Bash
echo -e "https://${ONLINE_BOUTIQUE_INGRESS_GATEWAY_HOST_NAME}"
```

You should receive the error: `RBAC: access denied`. This is because the default deny-all `AuthorizationPolicy` has been applied to the entire mesh. In the next section you will apply fine granular `AuthorizationPolicies` for the Online Boutique apps in order to get them working.