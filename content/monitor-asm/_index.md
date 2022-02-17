---
title: "Monitor ASM"
chapter: true
weight: 12
---
In this section you will monitor Anthos Service Mesh (ASM).

{{% notice warning %}}
This section is still under construction... stay tuned!
{{% /notice %}}

{{% children showhidden="false" %}}

- Cloud Trace
- Monitoring Dashboards
  - Pre-built dashboards: https://cloud.google.com/monitoring/dashboards/dashboard-templates#gcloud-tool
  - Istio/ASM versions: https://cloud.google.com/service-mesh/docs/managed/service-mesh#verify_control_plane_metrics
- SLOs/SLIs - alerts

_Note: For each Google / Kubernetes SA, mounted via Workload Identity, grant them this `roles/cloudtrace.agent` role in order to leverage ASM's option: Cloud Tracing._