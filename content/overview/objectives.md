---
title: "Objectives"
weight: 1
---
## Objectives

- Provision infrastructure via Kubernetes manifests with Config Controller
- Apply Kubernetes manifests (mostly) with a GitOps approach with GitHub and Config Sync
- Set up security best practices such as least privilege principle, etc.

## Agenda

1. Config Controller
    1. As Org Admin, create a Config Controller instance
    1. As Org Admin, set up Config Controller's Git repo
1. GKE project
    1. As Org Admin, set up the GKE project in Config Controller
    1. As Org Admin, set up the GKE project's Git repo in Config Controller
1. Networking
    1. As Org Admin, allow Networking rights for GKE project in Config Controller
    1. As Platform Admin, set up Network in GKE project
1. GKE cluster
    1. As Org Admin, allow GKE rights for GKE project in Config Controller
    1. As Platform Admin, create GKE cluster in GKE project
    1. As Org Admin, allow GKE Hub rights for GKE project in Config Controller
    1. As Platform Admin, set up GKE configs's Git repo in GKE project
1. Service Mesh
    1. As Org Admin, allow ASM rights for GKE project in Config Controller
    1. As Platform Admin, install ASM in GKE cluster in GKE project

## GCP services involved

- Config Controller
- GKE
- Artifact Registry
- Config Sync
- Policy Controller
- Config Connector
- ASM
- VPC
- Global Cloud Load Balancer
- Managed Certificates
- Cloud Armor
- Memorystore (redis)