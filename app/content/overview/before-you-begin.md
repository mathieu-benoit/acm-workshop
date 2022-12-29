---
title: "Before you begin"
weight: 4
---
Before you begin you need to make sure you have the prerequisites in place.

## Minimum knowledge

It's recommended that you have a minimum knowledge about Istio, Anthos Service Mesh (ASM), Anthos Config Management (ACM), GitOps, etc. Here is a list of resources you could leverage to get some familiarities depending on where you are at with these concepts:
- [What Is Kubernetes?](https://youtu.be/WxuvwSPSgXA)
- [Managing Kubernetes with Config Sync](https://youtu.be/_MrHbQKbPDY)
- [Using Config Connector for Google Cloud resource management](https://youtu.be/3lAOr2XdAh4)
- [Automating infrastructure compliance with Policy Controller](https://youtu.be/unu6pw5gGo0)
- [Istio in 5 minutes](https://youtu.be/hkR1M6qwpnw)
- [ASM Value over Istio](https://youtu.be/XKYUm0-eUyw)
- [Cloud Armor in a minute](https://youtu.be/fbEubYDGLYY)
- [Memorystore in a minute](https://youtu.be/ra3Vow3-HHg)
- [Cloud Operations Suite in a minute](https://youtu.be/5j8LfmRhHKQ)

Based on these introductions, here are higly recommended resources to watch before running this workshop:
- [Organizing Teams for GitOps and Cloud Native Deployments](https://youtu.be/Kl4-f1d_viY)
- [ACM @ Goldman Sachs](https://youtu.be/5ENId064XLo)
- [Enforcing Service Mesh Structure using OPA Gatekeeper](https://youtu.be/90RHTBinAFU)
- [Managing microservice architectures with ASM](https://youtu.be/OeevDBEDAIA)

## Your setup to run this workshop

You can run this workshop on Cloud Shell or on your local machine running Linux. Cloud Shell pre-installs all the required tools.

Install the required tools:
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- `kustomize`
- `git`
- `gh` (GitHub CLI)
- `kpt`
- `curl`
- `nomos`
- `docker`
- `crane`
- `helm`

You need to have:
- GCP account with the role `owner` in your Organization in order to deploy the resources needed for this workshop
- GitHub account, it's free. We will leverage GitHub throughout this workshop.