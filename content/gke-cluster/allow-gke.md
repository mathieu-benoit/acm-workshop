---
title: "Allow GKE"
weight: 1
description: "Duration: 5 min | Persona: Org Admin"
---
_{{< param description >}}_

Define variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define roles

Define the `container.admin`, `iam.serviceAccountAdmin`, `resourcemanager.projectIamAdmin` and `iam.serviceAccountUser` roles with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) resource for the GKE project's service account:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/container-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: container-admin-${GKE_PROJECT_ID}
  namespace: config-control
spec:
  member: serviceAccount:${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
  role: roles/container.admin
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/service-account-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: service-account-admin-${GKE_PROJECT_ID}
  namespace: config-control
spec:
  member: serviceAccount:${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
  role: roles/iam.serviceAccountAdmin
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/iam-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: iam-admin-${GKE_PROJECT_ID}
  namespace: config-control
spec:
  member: serviceAccount:${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
  role: roles/resourcemanager.projectIamAdmin
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/service-account-user.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: service-account-user-${GKE_PROJECT_ID}
  namespace: config-control
spec:
  member: serviceAccount:${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
  role: roles/iam.serviceAccountUser
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
```

## Define GKE API

Define the GKE API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the GKE project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/container-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: container.googleapis.com
  namespace: config-control
EOF
```
{{% notice note %}}
We are enabling the GCP services APIs from the Org Admin, it allows more control and governance over which GCP services APIs the Platform Admin could use or not. If you want to give more autonomy to the Platform Admin, you could grant the `serviceusage.serviceUsageAdmin` role to the associated service account.
{{% /notice %}}

## Enforce policies

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/policies/templates/limitgkecluster.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: limitgkecluster
  annotations:
    description: "Requirements for any GKE cluster."
spec:
  crd:
    spec:
      names:
        kind: LimitGKECluster
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package limitgkecluster
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

Define the `Constraint` resource:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/policies/constraints/allowed-gke-cluster.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: LimitGKECluster
metadata:
  name: allowed-gke-cluster
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
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Allow GKE for GKE project"
git push
```

## Check deployments

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $CONFIG_CONTROLLER_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
FIXME
```