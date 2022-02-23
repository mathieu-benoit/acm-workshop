---
title: "Agenda"
weight: 2
---
1. Config Controller
    1. As Org Admin, create a Config Controller instance
    1. As Org Admin, set up Config Controller's Git repo
1. GKE project
    1. As Org Admin, set up the GKE project in Config Controller
    1. As Org Admin, set up the GKE project's Git repo in Config Controller
1. Networking
    1. As Org Admin, allow Networking for GKE project in Config Controller
    1. As Platform Admin, set up Network in GKE project
1. GKE cluster
    1. As Org Admin, allow GKE for GKE project in Config Controller
    1. As Platform Admin, create GKE cluster in GKE project
    1. As Org Admin, allow GKE Hub for GKE project in Config Controller
    1. As Platform Admin, set up GKE configs's Git repo in GKE project
1. Service Mesh
    1. As Org Admin, allow ASM for GKE project in Config Controller
    1. As Platform Admin, install ASM in GKE cluster in GKE project
1. Ingress Gateway
    1. As Platform Admin, set up the Public static IP address and DNS for the Ingress Gateway
    1. As Org Admin, allow Cloud Armor for GKE project in Config Controller
    1. As Platform Admin, set up Cloud Armor in GKE project
    1. As Platform Admin, deploy the Ingress Gateway linked to Cloud Armor in GKE cluster in GKE project