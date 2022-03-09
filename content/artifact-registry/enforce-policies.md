---
title: "Enforce policies"
weight: 3
description: "Duration: 10 min | Persona: Platform Admin"
---
_Duration: 10 min | Persona: Platform Admin_

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