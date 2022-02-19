---
title: "Set up GKE configs's Git repo"
weight: 3
---

- Persona: Org Admin
- Duration: 10 min
- Objectives:
  - FIXME

```
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubFeature
metadata:
  name: feat-acm-cluster-name
  namespace: config-control
spec:
  projectRef:
    external: project-id # kpt-set: ${project-id}
  location: global
  # The resourceID must be "configmanagement" if you want to use Anthos Config Management feature.
  resourceID: configmanagement
```

```
apiVersion: gkehub.cnrm.cloud.google.com/v1beta1
kind: GKEHubMembership
metadata:
  name: hub-membership-cluster-name
  namespace: config-control
spec:
  location: global
  authority:
    # Issuer must contain a link to a valid JWT issuer.
    issuer: https://container.googleapis.com/v1/projects/project-id/locations/us-east4/clusters/cluster-name
  endpoint:
    gkeCluster:
      resourceRef:
        external: //container.googleapis.com/projects/project-id/locations/us-east4/clusters/cluster-name
```