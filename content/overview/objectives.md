---
title: "Objectives"
weight: 2
---
This workshop is not an introduction to Istio nor Anthos Service Mesh (ASM), if you are not familiar or you are just starting with their concepts, here are the resources you could leverage before running this workshop:
- [Cloud Next 2021 - Managing microservice architectures with ASM](https://youtu.be/OeevDBEDAIA)
- [Cloud Next 2020 - Building globally scalable services with Istio and ASM](https://youtu.be/clu7t0LVhcw)
- [Istio by example](https://istiobyexample.dev/)

Agenda:
- Create a GKE cluster
- Install a secure Managed ASM (Managed Control Plane, Managed Data Plane, Istio CNI and `distroless` proxy container image)
- Deploy workloads (OnlineBoutique)
- Enable ASM for workloads (sidecar proxy injection)
- Configure mTLS STRICT
- Configure `Sidecar` (restrict egress within the mesh)
- Configure `AuthorizationPolicy` (restrict ingress communication)
- Configure `NetworkPolicy` (restrict both ingress and egress between pods)
- Troubleshoot Istio/ASM

Here is the final high-level setup you will accomplish throughout this workshop:
![ASM Security diagram](/images/onlineboutique-secured.png)

What it is not covered yet:
- Muti-cluster Mesh
- Multi-cluster Ingress and Service
- Managed control and data plane
- There is [this on-going backlog to improve this workshop](https://github.com/mathieu-benoit/asm-workshop/issues) too, feel free to contribute! ;)

This workshop uses the following billable components of Google Cloud:
- [Compute Engine](https://cloud.google.com/compute/pricing)
- [Kubenetes Engine](https://cloud.google.com/kubernetes-engine/pricing)
- [Anthos Service Mesh](https://cloud.google.com/service-mesh/pricing)
- [Cloud Load Balancing](https://cloud.google.com/vpc/network-pricing#lb)
- [Networking](https://cloud.google.com/vpc/network-pricing)
- [Cloud Armor](https://cloud.google.com/armor/pricing)
- [Cloud Endpoints](https://cloud.google.com/endpoints/pricing)