---
title: "Deploy Sidecars"
weight: 7
description: "Duration: 5 min | Persona: Apps Operator"
tags: ["asm", "apps-operator"]
---
![Apps Operator](/images/apps-operator.png)
_{{< param description >}}_

In this section, you will deploy fine granular `Sidecars` in order to optimize the resources (CPU/Memory) usage of the Online Boutique apps's sidecar proxies. By default, each application in the `onlineboutique` `Namespace` can reach to all the endpoints in the mesh. The `Sidecar` resource allows to reduce that list to the strict minimum of which endpoints it needs to communicate with.

_Coming, stay tuned!_