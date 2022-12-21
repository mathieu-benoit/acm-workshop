---
title: "Enforce GCP resources policies"
weight: 3
description: "Duration: 5 min | Persona: Org Admin"
tags: ["org-admin", "policies", "security-tips"]
---
![Org Admin](/images/org-admin.png)
_{{< param description >}}_

In this section, you will set up policies in order to enforce governance against the Kubernetes manifests defining your Google Cloud services. As an example, you will limit the locations and the kind available for the Google Cloud services.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
echo "export GKE_LOCATION=northamerica-northeast1" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```
{{% notice info %}}
We are defining the `GKE_LOCATION` in `northamerica-northeast1` this will be used later for the location of the VPC, GKE, Artifact Registry, etc. in the Tenant project. We are using this region because that's the [greenest Google Cloud region (Low CO2)](https://cloud.google.com/sustainability/region-carbon) in the regions supported by [GKE Confidential Nodes](https://cloud.google.com/kubernetes-engine/docs/how-to/confidential-gke-nodes#availability) used in this workshop.
{{% /notice %}}

## Define "Allowed KCC resources" policies

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/templates/allowedkccresources.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: allowedkccresources
  annotations:
    description: "Requirements for any KCC resources."
spec:
  crd:
    spec:
      names:
        kind: AllowedKccResources
      validation:
        legacySchema: false
        openAPIV3Schema:
          properties:
            allowedKinds:
              items:
                type: string
              type: array
          type: object
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package allowedkccresources
        violation[{"msg": msg}] {
          _matches_group(input.review.kind.group)
          objectKind := input.review.kind.kind
          not _matches_kind(input.parameters.allowedKinds, objectKind)
          msg := sprintf("KCC resource of kind: %v is not allowed", [objectKind])
        }
        _matches_group(group) {
          endswith(group, ".cnrm.cloud.google.com")
          not group == "core.cnrm.cloud.google.com"
        }
        _matches_kind(allowedKinds, objectKind) {
          allowedKinds[_] = objectKind
        }
EOF
```

Define the `Constraint` resource:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/constraints/allowed-kcc-resources.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: AllowedKccResources
metadata:
  name: allowedkccresources
spec:
  enforcementAction: deny
  parameters:
    allowedKinds:
    - ArtifactRegistryRepository
    - ComputeAddress
    - ComputeNetwork
    - ComputeRouter
    - ComputeRouterNAT
    - ComputeSecurityPolicy
    - ComputeSSLPolicy
    - ComputeSubnetwork
    - ContainerCluster
    - ContainerNodePool
    - GKEHubFeature
    - GKEHubFeatureMembership
    - GKEHubMembership
    - IAMPartialPolicy
    - IAMPolicyMember
    - IAMServiceAccount
    - Project
    - RedisInstance
    - Service
    - SpannerDatabase
    - SpannerInstance
EOF
```

## Define "Allowed GCP locations" policies

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/templates/limitlocations.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: limitlocations
  annotations:
    description: "Allowed GCP locations."
spec:
  crd:
    spec:
      names:
        kind: LimitLocations
      validation:
        openAPIV3Schema:
          type: object
          properties:
            locations:
              description: List of allowed GCP locations
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |-
        package limitlocations
        violation[{"msg":msg}] {
          contains(input.review.object.apiVersion, "cnrm.cloud.google.com")
          not allowedLocation(input.review.object.spec.location)
          msg := sprintf("%s %s uses a disallowed location: %s, authorized locations are: %s", [input.review.object.kind, input.review.object.metadata.name, input.review.object.spec.location, input.parameters.locations])
        }
        violation[{"msg":msg}] {
          contains(input.review.object.apiVersion, "cnrm.cloud.google.com")
          not allowedLocation(input.review.object.spec.region)
          msg := sprintf("%s %s uses a disallowed location: %s, authorized locations are: %s", [input.review.object.kind, input.review.object.metadata.name, input.review.object.spec.region, input.parameters.locations])
        }
        allowedLocation(reviewLocation) {
          locations := input.parameters.locations
          satisfied := [good |
            location = locations[_]
            good = lower(location) == lower(reviewLocation)
          ]
          any(satisfied)
        }
EOF
```

Define the `Constraint` resource:
```Bash
cat <<EOF > ${WORK_DIR}$HOST_PROJECT_DIR_NAME/policies/constraints/allowed-locations.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: LimitLocations
metadata:
  name: allowed-locations
spec:
  enforcementAction: deny
  parameters:
    locations:
      - "northamerica-northeast1"
      - "global"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME/
git add . && git commit -m "Enforce policies for GCP resources" && git push origin main
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
Wait and re-run this command above until you see `"status": "SYNCED"`. All the `managed_resources` listed should have `STATUS: Current` as well.

List the GitHub runs for the **Host project configs** repository:
```Bash
cd ${WORK_DIR}$HOST_PROJECT_DIR_NAME && gh run list
```