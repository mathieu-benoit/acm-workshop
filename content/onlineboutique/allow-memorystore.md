---
title: "Allow Memorystore"
weight: 2
description: "Duration: 5 min | Persona: Org Admin"
---
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
    cnrm.cloud.google.com/project-id: ${GKE_PROJECT_ID}
    cnrm.cloud.google.com/deletion-policy: "abandon"
    cnrm.cloud.google.com/disable-dependent-services: "false"
  name: redis.googleapis.com
  namespace: config-control
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
spec:
  member: serviceAccount:${GKE_PROJECT_ID}@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com
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
          input.review.kind.kind == "RedisInstance"
          not input.review.object.spec.redisVersion == "REDIS_6_X"
          msg := sprintf("Memorystore (redis) %s's version should be 6.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.kind.kind == "RedisInstance"
          not input.review.object.spec.authorizedNetworkRef
          msg := sprintf("Memorystore (redis) %s's VPC shouldn't be default.", [input.review.object.metadata.name])
        }
        violation[{"msg":msg}] {
          input.review.kind.kind == "RedisInstance"
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