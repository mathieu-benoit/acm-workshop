---
title: "Allow Memorystore"
weight: 2
description: "Duration: 5 min | Persona: Org Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define API

Define the Memorystore (redis) API [`Service`](https://cloud.google.com/config-connector/docs/reference/resource-docs/serviceusage/service) resource for the GKE project:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/redis-service.yaml
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  annotations:
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
    config.kubernetes.io/depends-on: resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${GKE_PROJECT_ID}
  name: ${GKE_PROJECT_ID}-redis
  namespace: config-control
spec:
  projectRef:
    name: ${GKE_PROJECT_ID}
  resourceID: redis.googleapis.com
EOF
```

## Define role

Define the `redis.admin` role with an [`IAMPolicyMember`](https://cloud.google.com/config-connector/docs/reference/resource-docs/iam/iampolicymember) for the GKE project's service account:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/projects/$GKE_PROJECT_ID/redis-admin.yaml
apiVersion: iam.cnrm.cloud.google.com/v1beta1
kind: IAMPolicyMember
metadata:
  name: redis-admin-${GKE_PROJECT_ID}
  namespace: config-control
  annotations:
    config.kubernetes.io/depends-on: iam.cnrm.cloud.google.com/namespaces/config-control/IAMServiceAccount/${GKE_PROJECT_ID},resourcemanager.cnrm.cloud.google.com/namespaces/config-control/Project/${GKE_PROJECT_ID}
spec:
  memberFrom:
    serviceAccountRef:
      name: ${GKE_PROJECT_ID}
  role: roles/redis.admin
  resourceRef:
    apiVersion: resourcemanager.cnrm.cloud.google.com/v1beta1
    kind: Project
    external: projects/${GKE_PROJECT_ID}
EOF
```

## Enforce policies

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/policies/templates/limitmemorystoreredis.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: limitmemorystoreredis
  annotations:
    description: "Requirements for any Memorystore (redis) instance."
spec:
  crd:
    spec:
      names:
        kind: LimitMemorystoreRedis
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package limitmemorystoreredis
        violation[{"msg":msg}] {
          input.review.object.kind == "RedisInstance"
          not input.review.object.spec.redisVersion == "REDIS_6_X"
          msg := sprintf("Memorystore (redis) %s's version should be 6.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "RedisInstance"
          not input.review.object.spec.authorizedNetworkRef
          msg := sprintf("Memorystore (redis) %s's VPC shouldn't be default.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.object.kind == "RedisInstance"
          input.review.object.spec.authorizedNetworkRef.name == "default"
          msg := sprintf("Memorystore (redis) %s's VPC shouldn't be default.", [input.review.object.metadata.name])
        }
EOF
```

Define the `Constraint` resource:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/policies/constraints/allowed-memorystore-redis.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: LimitMemorystoreRedis
metadata:
  name: allowed-memorystore-redis
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups:
          - redis.cnrm.cloud.google.com
        kinds:
          - RedisInstance
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Allow Memorystore for GKE project"
git push origin main
```

## Check deployments

{{< mermaid >}}
graph TD;
  IAMServiceAccount-->Project
  IAMPartialPolicy-->IAMServiceAccount
  ConfigConnectorContext-->IAMServiceAccount
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  Service-->Project
  Service-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
  IAMPolicyMember-->Project
  Service-->Project
  IAMPolicyMember-->IAMServiceAccount
{{< /mermaid >}}

List the GCP resources created:
```Bash
gcloud projects get-iam-policy $GKE_PROJECT_ID \
    --filter="bindings.members:${GKE_PROJECT_SA_EMAIL}" \
    --flatten="bindings[].members" \
    --format="table(bindings.role)"
```
```Plaintext
ROLE
roles/artifactregistry.admin
roles/compute.networkAdmin
roles/compute.securityAdmin
roles/container.admin
roles/gkehub.admin
roles/iam.serviceAccountAdmin
roles/iam.serviceAccountUser
roles/redis.admin
roles/resourcemanager.projectIamAdmin
```

List the GitHub runs for the **Org configs** repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Allow Memorystore for GKE project         ci        main    push   1978342885  1m6s     2m
✓       Allow Security for GKE project            ci        main    push   1975011420  1m10s    1d
✓       Allow ASM for GKE project                 ci        main    push   1972159145  1m1s     22h
✓       Allow Artifact Registry for GKE project   ci        main    push   1972065864  57s      22h
✓       Allow GKE Hub for GKE project             ci        main    push   1970917868  1m8s     1d
✓       Allow GKE for GKE project                 ci        main    push   1961343262  1m0s     2d
✓       Allow Networking for GKE project          ci        main    push   1961279233  1m9s     2d
✓       Enforce policies for GKE project          ci        main    push   1961276465  1m2s     2d
✓       GitOps for GKE project                    ci        main    push   1961259400  1m7s     2d
✓       Setting up GKE namespace/project          ci        main    push   1961160322  1m7s     2d
✓       Billing API in Config Controller project  ci        main    push   1961142326  1m12s    2d
✓       Initial commit                            ci        main    push   1961132028  1m2s     2d
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Org configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $CONFIG_CONTROLLER_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬───────────────────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                        NAME                       │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ acm-workshop-464-gke                              │                      │
│                                       │ Namespace              │ config-control                                    │                      │
│ constraints.gatekeeper.sh             │ LimitGKECluster        │ allowed-gke-cluster                               │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                                 │                      │
│ constraints.gatekeeper.sh             │ LimitMemorystoreRedis  │ allowed-memorystore-redis                         │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitgkecluster                                   │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                                    │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitmemorystoreredis                             │                      │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                                         │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                                        │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ gke-hub-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-user-acm-workshop-464-gke         │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-admin-acm-workshop-464-gke        │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ iam-admin-acm-workshop-464-gke                    │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ redis-admin-acm-workshop-464-gke                  │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ security-admin-acm-workshop-464-gke               │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-gke                              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ container-admin-acm-workshop-464-gke              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ artifactregistry-admin-acm-workshop-464-gke       │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ network-admin-acm-workshop-464-gke                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-gke-sa-wi-user                   │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-gke                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ redis.googleapis.com                              │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ gkehub.googleapis.com                             │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ artifactregistry.googleapis.com                   │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ mesh.googleapis.com                               │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com                       │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ container.googleapis.com                          │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ containeranalysis.googleapis.com                  │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ anthosconfigmanagement.googleapis.com             │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ containerscanning.googleapis.com                  │ config-control       │
└───────────────────────────────────────┴────────────────────────┴───────────────────────────────────────────────────┴──────────────────────┘
```