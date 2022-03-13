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

## Define "Allowed container registries" policy

Define the `ConstraintTemplate` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/templates/k8sallowedrepos.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedrepos
  annotations:
    description: "Requires container images to begin with a string from the specified list."
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRepos
      validation:
        openAPIV3Schema:
          type: object
          properties:
            repos:
              description: The list of prefixes a container image is allowed to have.
              type: array
              items:
                type: string
  targets:
    - rego: |
        package k8sallowedrepos
        violation[{"msg": msg}] {
          container := input_containers[_]
          satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
          not any(satisfied)
          msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
        }
        violation[{"msg": msg}] {
          container := input_pod_containers[_]
          satisfied := [good | repo = input.parameters.repos[_] ; good = startswith(container.image, repo)]
          not any(satisfied)
          msg := sprintf("container <%v> has an invalid image repo <%v>, allowed repos are %v", [container.name, container.image, input.parameters.repos])
        }
        input_pod_containers[p] {
            p := input.review.object.spec.containers[_]
        }
        input_pod_containers[p] {
            p := input.review.object.spec.initContainers[_]
        }
        input_containers[c] {
            c := input.review.object.spec.template.spec.containers[_]
        }
        input_containers[c] {
            c := input.review.object.spec.template.spec.initContainers[_]
        }
      target: admission.k8s.gatekeeper.sh
EOF
```

Define the `Constraint` resource:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/policies/constraints/allowed-container-registries.yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: allowed-container-registries
spec:
  enforcementAction: deny
  match:
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
    - apiGroups:
      - apps
      kinds:
      - Deployment
  parameters:
    repos:
    - auto
    - gcr.io
    - k8s.gcr.io
    - gke.gcr.io
    - us-docker.pkg.dev/google-samples/containers/gke/whereami
    - gcr.io/google-samples/microservices-demo
    #- ${CONTAINER_REGISTRY_REPOSITORY}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Enforce Container Registries Policies in GKE cluster"
git push
```

## Check deployments

List the GitHub runs for the **GKE cluster configs** repository `cd ~/$GKE_CONFIGS_DIR_NAME && gh run list`:
```Plaintext
STATUS  NAME                                                  WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Enforce Container Registries Policies in GKE cluster  ci        main    push   1972138349  55s      4m
✓       Policies for NetworkPolicy resources                  ci        main    push   1971716019  1m14s    2h
✓       Network Policies logging                              ci        main    push   1971353547  1m1s     4h
✓       Config Sync monitoring                                ci        main    push   1971296656  1m9s     5h
✓       Initial commit                                        ci        main    push   1970951731  57s      6h
```

List the Kubernetes resources managed by Config Sync in the **GKE cluster** for the **GKE cluster configs** repository:
```Bash
gcloud alpha anthos config sync repo describe \
    --project $GKE_PROJECT_ID \
    --managed-resources all \
    --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')" \
    --sync-name root-sync \
    --sync-namespace config-management-system
```
```Plaintext
getting 1 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬────────────────────┬──────────────────────────────┬──────────────────────────────┐
│           GROUP           │        KIND        │             NAME             │          NAMESPACE           │
├───────────────────────────┼────────────────────┼──────────────────────────────┼──────────────────────────────┤
│                           │ Namespace          │ config-management-monitoring │                              │
│ constraints.gatekeeper.sh │ K8sAllowedRepos    │ allowed-container-registries │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels  │ namespace-required-labels    │                              │
│ constraints.gatekeeper.sh │ K8sRequiredLabels  │ deployment-required-labels   │                              │
│ networking.gke.io         │ NetworkLogging     │ default                      │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate │ k8sallowedrepos              │                              │
│ templates.gatekeeper.sh   │ ConstraintTemplate │ k8srequiredlabels            │                              │
│                           │ ServiceAccount     │ default                      │ config-management-monitoring │
└───────────────────────────┴────────────────────┴──────────────────────────────┴──────────────────────────────┘
```