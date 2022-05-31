---
title: "Enforce Memorystore policies"
weight: 6
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin", "policies", "security-tips"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

Initialize variables:
```Bash
source ${WORK_DIR}acm-workshop-variables.sh
```

## Enforce policies

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/policies/templates/limitmemorystoreredis.yaml
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
          msg := sprintf("Memorystore (redis) %s's version should be REDIS_6_X instead of %s.", [input.review.object.metadata.name, input.review.object.spec.redisVersion])
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
        violation[{"msg":msg}] {
          input.review.object.kind == "RedisInstance"
          not input.review.object.spec.transitEncryptionMode == "SERVER_AUTHENTICATION"
          msg := sprintf("Memorystore (redis) %s's transit encryption mode should be set to SERVER_AUTHENTICATION.", [input.review.object.metadata.name])
        }
EOF
```

Define the `Constraint` resource:
```Bash
cat <<EOF > ~/$HOST_PROJECT_DIR_NAME/config-sync/policies/constraints/allowed-memorystore-redis.yaml
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
cd ~/$HOST_PROJECT_DIR_NAME/
git add .
git commit -m "Enforce Memorystore policies"
git push origin main
```

## Check deployments

List the GitHub runs for the **Host project configs** repository `cd ~/$HOST_PROJECT_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                         WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Allow Memorystore for Tenant project         ci        main    push   1978342885  1m6s     2m
✓       Allow Security for Tenant project            ci        main    push   1975011420  1m10s    1d
✓       Allow ASM for Tenant project                 ci        main    push   1972159145  1m1s     22h
✓       Allow Artifact Registry for Tenant project   ci        main    push   1972065864  57s      22h
✓       Allow GKE Hub for Tenant project             ci        main    push   1970917868  1m8s     1d
✓       Allow GKE for Tenant project                 ci        main    push   1961343262  1m0s     2d
✓       Allow Networking for Tenant project          ci        main    push   1961279233  1m9s     2d
✓       Enforce policies for Tenant project          ci        main    push   1961276465  1m2s     2d
✓       GitOps for Tenant project                    ci        main    push   1961259400  1m7s     2d
✓       Setting up Tenant namespace/project          ci        main    push   1961160322  1m7s     2d
✓       Billing API in Host project                  ci        main    push   1961142326  1m12s    2d
✓       Initial commit                               ci        main    push   1961132028  1m2s     2d
```

List the Kubernetes resources managed by Config Sync in **Config Controller** for the **Host project configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $HOST_PROJECT_ID \
    --managed-resources all \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬───────────────────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                        NAME                       │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼───────────────────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ acm-workshop-464-tenant                              │                      │
│                                       │ Namespace              │ config-control                                    │                      │
│ constraints.gatekeeper.sh             │ LimitGKECluster        │ allowed-gke-cluster                               │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                                 │                      │
│ constraints.gatekeeper.sh             │ LimitMemorystoreRedis  │ allowed-memorystore-redis                         │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitgkecluster                                   │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                                    │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitmemorystoreredis                             │                      │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                                         │ acm-workshop-464-tenant │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext.core.cnrm.cloud.google.com │ acm-workshop-464-tenant │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                                        │ acm-workshop-464-tenant │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ gke-hub-admin-acm-workshop-464-tenant                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-user-acm-workshop-464-tenant         │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ service-account-admin-acm-workshop-464-tenant        │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ iam-admin-acm-workshop-464-tenant                    │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ redis-admin-acm-workshop-464-tenant                  │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ security-admin-acm-workshop-464-tenant               │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-tenant                              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ container-admin-acm-workshop-464-tenant              │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ artifactregistry-admin-acm-workshop-464-tenant       │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember        │ network-admin-acm-workshop-464-tenant                │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-tenant-sa-wi-user                   │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-tenant                              │ config-control       │
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
