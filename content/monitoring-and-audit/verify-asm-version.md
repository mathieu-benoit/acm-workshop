---
title: "Verify ASM version"
weight: 2
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["asm", "monitoring", "platform-admin"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will verify in the Google Cloud console the versions of both: the control plane and data plane of ASM.

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

[Managed Anthos Service Mesh](https://cloud.google.com/service-mesh/docs/managed/configure-managed-anthos-service-mesh) is a Google-managed control plane and an optional data plane that you simply configure. Google handles their reliability, upgrades, scaling and security for you.

When we installed Anthos Service Mesh earlier in this workshop, we chose a specific [release channel](https://cloud.google.com/service-mesh/docs/managed/select-a-release-channel#available_release_channels). Anthos Service Mesh release channels are similar conceptually to GKE release channels but are independent of GKE release channels. Google automatically manages the version and upgrade cadence for each release channel.

In Ingress Gateway and Bank of Anthos namespaces, we also enabled the Google-managed data plane. When [Google-managed data plane](https://cloud.google.com/service-mesh/docs/managed/auto-control-plane-with-fleet#managed-data-plane) is enabled, the sidecar proxies and injected gateways are automatically upgraded in conjunction with the managed control plane.

With both features, managed control plane and managed data plane, you don't have to worry anymore about Istio version upgrades.

You can view the versions of the control plane (`revision` column below) and data plane (`proxy-version` column below) in Metrics Explorer. Click on the link displayed by the command below:
```Bash
echo "https://console.cloud.google.com/monitoring/metrics-explorer?pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22istio.io%2Fcontrol%2Fproxy_clients%5C%22%20resource.type%3D%5C%22k8s_container%5C%22%20resource.label.%5C%22container_name%5C%22%3D%5C%22cr-asm-managed-rapid%5C%22%22,%22minAlignmentPeriod%22:%2260s%22,%22unitOverride%22:%221%22,%22aggregations%22:%5B%7B%22perSeriesAligner%22:%22ALIGN_MEAN%22,%22crossSeriesReducer%22:%22REDUCE_SUM%22,%22groupByFields%22:%5B%22metric.label.%5C%22revision%5C%22%22,%22metric.label.%5C%22proxy_version%5C%22%22%5D%7D,%7B%22crossSeriesReducer%22:%22REDUCE_NONE%22%7D%5D%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D,%22isAutoRefresh%22:true,%22timeSelection%22:%7B%22timeRange%22:%221h%22%7D%7D&_ga=2.39844003.1070780175.1650643506-22581792.1650643506"
```

![Anthos Service Mesh versions](/images/asm-version.png)