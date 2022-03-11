---
title: "Enforce policies"
weight: 3
description: "Duration: 5 min | Persona: Org Admin"
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

## Check deployments

Here is what you should have at this stage:

List the GitHub runs for the **Org configs** repository `cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Enforce policies for GKE project          ci        main    push   1960968253  1m4s     1m
✓       GitOps for GKE project                    ci        main    push   1960959789  1m5s     3m
✓       Setting up GKE namespace/project          ci        main    push   1960908849  1m12s    18m
✓       Billing API in Config Controller project  ci        main    push   1960889246  1m0s     25m
✓       Initial commit                            ci        main    push   1960885850  1m8s     26m
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
getting 2 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬────────────────────────┬────────────────────────────────────┬──────────────────────┐
│                 GROUP                 │          KIND          │                NAME                │      NAMESPACE       │
├───────────────────────────────────────┼────────────────────────┼────────────────────────────────────┼──────────────────────┤
│                                       │ Namespace              │ acm-workshop-464-gke               │                      │
│                                       │ Namespace              │ config-control                     │                      │
│ constraints.gatekeeper.sh             │ LimitLocations         │ allowed-locations                  │                      │
│ templates.gatekeeper.sh               │ ConstraintTemplate     │ limitlocations                     │                      │
│ configsync.gke.io                     │ RepoSync               │ repo-sync                          │ acm-workshop-464-gke │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext │ configconnectorcontext             │ acm-workshop-464-gke │
│ rbac.authorization.k8s.io             │ RoleBinding            │ syncs-repo                         │ acm-workshop-464-gke │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount      │ acm-workshop-464-gke               │ config-control       │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy       │ acm-workshop-464-gke-sa-wi-user    │ config-control       │
│ resourcemanager.cnrm.cloud.google.com │ Project                │ acm-workshop-464-gke               │ config-control       │
│ serviceusage.cnrm.cloud.google.com    │ Service                │ cloudbilling.googleapis.com        │ config-control       │
└───────────────────────────────────────┴────────────────────────┴────────────────────────────────────┴──────────────────────┘
```