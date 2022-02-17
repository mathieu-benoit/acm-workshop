---
title: "Secure Ingress Gateway"
chapter: true
weight: 10
---
In this section you will secure the Ingress Gateway previously deployed with an HTTPS GCLB (L7) and Cloud Armor (WAF).

{{% notice warning %}}
This section is still under construction... stay tuned!
{{% /notice %}}

{{% children showhidden="false" %}}

Here is the high-level setup you will accomplish with this section:
![ASM Security diagram](/images/onlineboutique-secured.png)

Resources:
- [Tutorial - From edge to mesh: Exposing service mesh applications through GKE Ingress](https://cloud.google.com/architecture/exposing-service-mesh-apps-through-gke-ingress)
- [Tutorial - Automate TLS certificate management for Anthos Service Mesh ingress gateway using Certificate Authority Service](https://cloud.google.com/service-mesh/docs/automate-tls)