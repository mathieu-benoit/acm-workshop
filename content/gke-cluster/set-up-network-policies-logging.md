---
title: "Set up NetworkPolicies logging"
weight: 6
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

Define variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Define Network Policy logging

https://cloud.google.com/kubernetes-engine/docs/how-to/network-policy-logging

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/networkpolicies-logging.yaml
kind: NetworkLogging
apiVersion: networking.gke.io/v1alpha1
metadata:
  name: default
spec:
  cluster:
    allow:
      log: false
      delegate: false
    deny:
      log: true
      delegate: false
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add . && git commit -m "NetworkPolicies logging" && git push origin main
```

## Check deployments

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Policies for NetworkPolicy resources  ci        main    push   1971716019  1m14s    2m
✓       Network Policies logging              ci        main    push   1971353547  1m1s     1h
✓       Config Sync monitoring                ci        main    push   1971296656  1m9s     2h
✓       Initial commit                        ci        main    push   1970951731  57s      3h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $TENANT_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬────────────────────┬──────────────────────────────┬──────────────────────────────┐
│           GROUP           │        KIND        │             NAME             │          NAMESPACE           │
├───────────────────────────┼────────────────────┼──────────────────────────────┼──────────────────────────────┤
│                           │ Namespace          │ config-management-monitoring │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels  │ deployment-required-labels   │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels  │ namespace-required-labels    │                              │
│ networking.gke.io         │ NetworkLogging     │ default                      │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate │ k8srequiredlabels            │                              │
│                           │ ServiceAccount     │ default                      │ config-management-monitoring │
└───────────────────────────┴────────────────────┴──────────────────────────────┴──────────────────────────────┘
```