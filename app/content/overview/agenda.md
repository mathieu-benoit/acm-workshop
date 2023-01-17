---
title: "Agenda"
weight: 3
tags: ["apps-operator", "org-admin", "platform-admin"]
---
1. Host project
    1. As Org Admin, create a Host project
    1. As Org Admin, create a Config Controller instance
    1. As Org Admin, set up Host project's Git repo
    1. As Org Admin, enforce policies for tenant projects
1. Tenant project
    1. As Org Admin, set up the Tenant project
    1. As Org Admin, set up the Tenant project's Git repo
    1. As Org Admin, enforce policies for Google Cloud resources
    1. As Org Admin, allow Monitoring for Tenant project
    1. As Platform Admin, set up Monitoring in Tenant project
1. Networking
    1. As Org Admin, allow Networking for Tenant project
    1. As Platform Admin, set up Network in Tenant project
1. GKE cluster
    1. As Org Admin, allow GKE for Tenant project
    1. As Org Admin, enforce policies for GKE cluster resources
    1. As Platform Admin, create GKE cluster in Tenant project
    1. As Org Admin, allow Fleet for Tenant project
    1. As Platform Admin, set up GKE configs's Git repo in Tenant project
    1. As Platform Admin, enforce Kubernetes policies with Pod Security Admission (PSA) and `NetworkPolicies`
    1. As Platform Admin, set up `NetworkPolicies` logging in GKE cluster
1. Artifact Registry
    1. As Org Admin, allow Artifact Registry for Tenant project
    1. As Platform Admin, create Artifact Registry in Tenant project and allow GKE cluster to pull containers
    1. As Platform Admin, enforce policies for Artifact Registry (allowed container registries)
1. Service Mesh
    1. As Org Admin, allow ASM for Tenant project
    1. As Platform Admin, install Managed ASM in GKE cluster
    1. As Platform Admin, set up ASM configs in GKE cluster
    1. As Platform Admin, enforce policies for ASM
1. Ingress Gateway
    1. As Platform Admin, create the Public static IP address for the Ingress Gateway
    1. As Org Admin, allow Cloud Armor for Tenant project
    1. As Platform Admin, set up Cloud Armor in Tenant project
    1. As Platform Admin, deploy the Ingress Gateway linked to Cloud Armor in GKE cluster
    1. As Platform Admin, deploy `NetworkPolicies` for the Ingress Gateway namespace in GKE cluster
    1. As Platform Admin, deploy `AuthorizationPolicies` for the Ingress Gateway namespace in GKE cluster
1. Whereami app
    1. As Platform Admin, set up DNS for the Whereami app
    1. As Platform Admin, set up URL uptime check on the Whereami app
    1. As Platform Admin, configure Config Sync for the Whereami app in GKE cluster
    1. As Apps Operator, copy Whereami container in private Artifact Registry
    1. As Apps Operator, deploy the Whereami app in GKE cluster
    1. As Apps Operator, deploy `AuthorizationPolicies` for the Whereami namespace in GKE cluster
    1. As Apps Operator, deploy `NetworkPolicies` for the Whereami namespace in GKE cluster
    1. As Apps Operator, deploy `Sidecars` for the Whereami namespace in GKE cluster
1. Online Boutique apps
    1. As Platform Admin, set up DNS for the Online Boutique website
    1. As Platform Admin, set up URL uptime check on the Online Boutique website
    1. As Platform Admin, allow Config Sync for the Online Boutique apps in GKE cluster
    1. As Platform Admin, configure Config Sync for the Online Boutique apps in GKE cluster
    1. As Apps Operator, copy Online Boutique containers in private Artifact Registry
    1. As Apps Operator, deploy the Online Boutique apps in GKE cluster
    1. As Apps Operator, deploy `AuthorizationPolicies` for the Online Boutique namespace in GKE cluster
    1. As Apps Operator, deploy `NetworkPolicies` for the Online Boutique namespace in GKE cluster
    1. As Apps Operator, deploy `Sidecars` for the Online Boutique namespace in GKE cluster
    1. Memorystore (Redis)
        1. As Org Admin, allow Memorystore (Redis) for Tenant project
        1. As Org Admin, enforce policies for Memorystore (Redis) resources
        1. As Platform Admin, create Memorystore (Redis) instances with and without TLS in Tenant project
        1. As Apps Operator, configure Online Boutique apps to use Memorystore (Redis) instance
        1. As Apps Operator, secure Online Boutique apps to access Memorystore (Redis) instance via TLS
    1. Spanner
        1. As Org Admin, allow Spanner for Tenant project
        1. As Platform Admin, create Spanner instance in Tenant project
        1. As Apps Operator, configure Online Boutique apps to use Spanner instance
1. Bank of Anthos apps
    1. As Platform Admin, set up DNS for the Bank of Anthos website
    1. As Platform Admin, set up URL uptime check on the Bank of Anthos website
    1. As Platform Admin, configure Config Sync for the Bank of Anthos apps in GKE cluster
    1. As Apps Operator, copy Bank of Anthos containers in private Artifact Registry
    1. As Apps Operator, deploy the Bank of Anthos apps in GKE cluster
    1. As Apps Operator, deploy `AuthorizationPolicies` for the Bank of Anthos namespace in GKE cluster
    1. As Apps Operator, deploy `NetworkPolicies` for the Bank of Anthos namespace in GKE cluster
    1. As Apps Operator, deploy `Sidecars` for the Bank of Anthos namespace in GKE cluster
1. Monitoring & Audit
    1. As Platform Admin, verify ASM versions
    1. As Apps Operator, monitor apps security
    1. As Apps Operator, monitor apps health
    1. As Apps Operator, trace apps
    1. As Apps Operator, monitor Cloud Armor (WAF) rules
    1. As Apps Operator, scan workloads and configurations
    1. As Apps Operator, monitor resources synced by Config Sync
    1. As Apps Operator, monitor policies violations by Policy Controller
    1. As Apps Operator, monitor URLs uptime checks