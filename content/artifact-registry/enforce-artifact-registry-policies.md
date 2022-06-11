---
title: "Enforce Artifact Registry policies"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
tags: ["platform-admin", "policies", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will enforce policies in order to make sure that the containers in your clusters are coming from a restricted list of container registries.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define "Allowed container registries" policy

Define the `Constraint` based on the [`K8sAllowedRepos`](https://cloud.devsite.corp.google.com/anthos-config-management/docs/reference/constraint-template-library#k8sallowedrepos) `ConstraintTemplate` for `Pods`:
```Bash
cat <<EOF > ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/policies/constraints/pod-allowed-container-registries.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: pod-allowed-container-registries
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
  parameters:
    repos:
    - auto
    - gcr.io
    - k8s.gcr.io
    - gke.gcr.io
    - gcr.io/google-samples/microservices-demo
    - busybox #not ideal, but temporary (loadgenerator's initContainer)
    - redis
    - ${CONTAINER_REGISTRY_REPOSITORY}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "Policies for Artifact Registry" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RepoSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **GKE cluster configs** repository:
```Bash
cd ${WORK_DIR}$GKE_CONFIGS_DIR_NAME && gh run list
```