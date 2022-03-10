---
title: "Enforce policies"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
---
_{{< param description >}}_

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Define "Allowed GCP locations" policies

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/policies/templates/limitlocations.yaml
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
cat <<EOF > ~/$WORKSHOP_ORG_DIR_NAME/config-sync/policies/constraints/allowed-locations.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: LimitLocations
metadata:
  name: allowed-locations
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups:
          - '*'
        kinds:
          - '*'
  parameters:
    locations:
      - "northamerica-northeast1"
      - "northamerica-northeast2"
      - "us-east4"
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME/
git add .
git commit -m "Enforce policies for GKE project"
git push
```