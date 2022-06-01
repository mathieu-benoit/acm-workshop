---
title: "Agenda"
weight: 3
tags: ["apps-operator", "org-admin", "platform-admin"]
---
1. Host project
    1. As Org Admin, create a Host project
    1. As Org Admin, create a Config Controller instance
    1. As Org Admin, set up Host project's Git repo
1. Tenant project
    1. As Org Admin, set up the Tenant project
    1. As Org Admin, set up the Tenant project's Git repo
1. Networking
    1. As Org Admin, allow Networking for Tenant project
    1. As Platform Admin, set up Network in Tenant project
1. GKE cluster
    1. As Org Admin, allow GKE for Tenant project
    1. As Platform Admin, create GKE cluster in Tenant project
    1. As Org Admin, allow GKE Hub for Tenant project
    1. As Platform Admin, set up GKE configs's Git repo in Tenant project
    1. As Platform Admin, set up `NetworkPolicy` logging in GKE cluster
1. Artifact Registry
    1. As Org Admin, allow Artifact Registry for Tenant project
    1. As Platform Admin, create Artifact Registry in Tenant project and allow GKE cluster to pull containers
    1. As Platform Admin, enforce Artifact Registry policies (allowed container registries)
1. Service Mesh
    1. As Org Admin, allow ASM for Tenant project
    1. As Platform Admin, install Managed ASM in GKE cluster
    1. As Platform Admin, set up ASM configs in GKE cluster
1. Ingress Gateway
    1. As Platform Admin, create the Public static IP address for the Ingress Gateway
    1. As Org Admin, allow Cloud Armor for Tenant project
    1. As Platform Admin, set up Cloud Armor in Tenant project
    1. As Platform Admin, deploy the Ingress Gateway linked to Cloud Armor in GKE cluster
    1. As Platform Admin, deploy `NetworkPolicies` for the Ingress Gateway namespace in GKE cluster
    1. As Platform Admin, deploy `AuthorizationPolicies` for the Ingress Gateway namespace in GKE cluster
1. Whereami app
    1. As Platform Admin, set up the Whereami app's Git repo in GKE cluster
    1. As Apps Operator, deploy the Whereami app
    1. As Apps Operator, deploy `NetworkPolicies` for the Whereami namespace in GKE cluster
    1. As Apps Operator, deploy `Sidecars` for the Whereami namespace in GKE cluster
    1. As Apps Operator, deploy `AuthorizationPolicies` for the Whereami namespace in GKE cluster
1. Online Boutique apps
    1. As Platform Admin, set up the Online Boutique apps's Git repo in GKE cluster
    1. As Apps Operator, deploy the Online Boutique apps
    1. As Org Admin, allow Memorystore (redis) for Tenant project
    1. As Platform Admin, create Memorystore (redis) in Tenant project
    1. As Apps Operator, deploy `NetworkPolicies` for the Online Boutique namespace in GKE cluster
    1. As Apps Operator, deploy `Sidecars` for the Online Boutique namespace in GKE cluster
    1. As Apps Operator, deploy `AuthorizationPolicies` for the Online Boutique namespace in GKE cluster