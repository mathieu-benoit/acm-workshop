---
title: "Enforce Memorystore policies"
weight: 9
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin", "policies", "security-tips"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will set up policies in order to enforce governance against the Kubernetes manifests defining your Memorystore (redis) instances.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

## Enforce Memorystore policies

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/templates/limitmemorystoreredis.yaml
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
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/constraints/allowed-memorystore-redis.yaml
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
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Enforce Memorystore policies" && git push origin main
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