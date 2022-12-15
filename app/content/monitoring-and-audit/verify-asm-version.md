---
title: "Verify ASM version"
weight: 1
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

[Managed Anthos Service Mesh](https://cloud.google.com/service-mesh/docs/managed/configure-managed-anthos-service-mesh) is a Google-managed control plane and data plane that you simply configure. Google handles their reliability, upgrades, scaling and security for you.

You can view the versions of the control plane (`revision` column below) and data plane (`proxy-version` column below) in Metrics Explorer. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/monitoring/metrics-explorer?pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22istio.io%2Fcontrol%2Fproxy_clients%5C%22%20resource.type%3D%5C%22k8s_container%5C%22%20resource.label.%5C%22container_name%5C%22%3D%5C%22cr-${ASM_VERSION}%5C%22%22,%22minAlignmentPeriod%22:%2260s%22,%22aggregations%22:%5B%7B%22perSeriesAligner%22:%22ALIGN_MEAN%22,%22crossSeriesReducer%22:%22REDUCE_SUM%22,%22alignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%22metric.label.%5C%22revision%5C%22%22,%22metric.label.%5C%22proxy_version%5C%22%22%5D%7D,%7B%22perSeriesAligner%22:%22ALIGN_NONE%22,%22crossSeriesReducer%22:%22REDUCE_NONE%22,%22alignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%5D%7D%5D%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D,%22isAutoRefresh%22:true,%22timeSelection%22:%7B%22timeRange%22:%221h%22%7D%7D&project=${TENANT_PROJECT_ID}"
```

![Anthos Service Mesh versions](/images/asm-version.png)