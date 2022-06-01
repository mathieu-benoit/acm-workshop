---
title: "Enforce GKE policies"
weight: 2
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin", "policies", "security-tips"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

Define variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Enforce GKE clusters policies

Define the `ConstraintTemplate`:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/templates/gke-clusters-requirements-template.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: gkeclusterrequirement
  annotations:
    description: "Requirements for any GKE cluster."
spec:
  crd:
    spec:
      names:
        kind: GkeClusterRequirement
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package gkeclusterrequirement
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerCluster"
          not input.review.object.spec.confidentialNodes.enabled == true
          msg := sprintf("GKE cluster %s should enable confidentialNodes.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerCluster"
          not input.review.object.spec.enableShieldedNodes == true
          msg := sprintf("GKE cluster %s should enable enableShieldedNodes.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerCluster"
          not input.review.object.spec.networkingMode == "VPC_NATIVE"
          msg := sprintf("GKE cluster %s should use VPC_NATIVE networkingMode.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerCluster"
          not input.review.object.spec.privateClusterConfig.enablePrivateNodes == true
          msg := sprintf("GKE cluster %s should enable enablePrivateNodes.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerCluster"
          not input.review.object.spec.workloadIdentityConfig.workloadPool
          msg := sprintf("GKE cluster %s should define workloadIdentityConfig.workloadPool.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerCluster"
          not input.review.object.spec.datapathProvider == "ADVANCED_DATAPATH"
          msg := sprintf("GKE cluster %s should define datapathProvider as ADVANCED_DATAPATH to use GKE Dataplane V2.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerCluster"
          not input.review.object.spec.addonsConfig.httpLoadBalancing.disabled == false
          msg := sprintf("GKE cluster %s should enable addonsConfig.httpLoadBalancing.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerNodePool"
          not input.review.object.spec.management.autoRepair == true
          msg := sprintf("GKE node pool %s should enable management.autoRepair.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerNodePool"
          not input.review.object.spec.management.autoUpgrade == true
          msg := sprintf("GKE node pool %s should enable management.autoUpgrade.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerNodePool"
          not input.review.object.spec.nodeConfig.imageType == "COS_CONTAINERD"
          msg := sprintf("GKE node pool %s should define nodeConfig.imageType as COS_CONTAINERD.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerNodePool"
          not input.review.object.spec.nodeConfig.shieldedInstanceConfig.enableIntegrityMonitoring == true
          msg := sprintf("GKE node pool %s should enable nodeConfig.shieldedInstanceConfig.enableIntegrityMonitoring.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerNodePool"
          not input.review.object.spec.nodeConfig.shieldedInstanceConfig.enableSecureBoot == true
          msg := sprintf("GKE node pool %s should enable nodeConfig.shieldedInstanceConfig.enableSecureBoot.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "ContainerNodePool"
          not input.review.object.spec.nodeConfig.serviceAccountRef.name
          msg := sprintf("GKE node pool %s should define nodeConfig.serviceAccountRef.", [input.review.object.metadata.name])
        }
EOF
```

Define the `gke-clusters-requirements` `Constraint` based on the `GkeClusterRequirement` `ConstraintTemplate` just created:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/constraints/gke-clusters-requirements.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: GkeClusterRequirement
metadata:
  name: gke-clusters-requirements
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups:
          - container.cnrm.cloud.google.com
        kinds:
          - ContainerCluster
          - ContainerNodePool
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Policies for GKE clusters" && git push origin main
```

## Check deployments

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
Wait and re-run this command above until you see `"status": "SYNCED"` for this `RootSync`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Host project configs** repository:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME && gh run list
```