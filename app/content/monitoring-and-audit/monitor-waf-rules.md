---
title: "Monitor WAF rules"
weight: 5
description: "Duration: 5 min | Persona: Platform Admin"
tags: ["monitoring", "platform-admin", "security-tips"]
---
![Platform Admin](/images/platform-admin.png)
_{{< param description >}}_

In this section, you will [monitor Cloud Armor security policies logs](https://cloud.google.com/armor/docs/request-logging) (WAF rules).

Initialize variables:
```Bash
WORK_DIR=~/
source ${WORK_DIR}acm-workshop-variables.sh
```

In the Google Cloud console, navigate to _Network Security > Cloud Armor_ service. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/net-security/securitypolicies/details/${SECURITY_POLICY_NAME}?project=${TENANT_PROJECT_ID}"
```

![Cloud Armor rules](/images/cloud-armor-rules.png)

Using Cloud Logging, you can view every request evaluated by a Google Cloud Armor security policy and the outcome or action taken.

Select the **Logs** tab and click on **View policy logs**. From here, change _Last 1 hour_ by **Last 7 days** (top left) and enable the **Show query** toggle (top right):

![Cloud Armor logging](/images/cloud-armor-logging.png)

In the **Query** field you could add a new line with `jsonPayload.enforcedSecurityPolicy.outcome="DENY"` for example to see all the denied requests by the WAF rules you set up earlier in this workshop.

You could also leverage the `gcloud` command below to get such insights.

Run this command in Cloud Shell:
```Bash
filter="resource.type=\"http_load_balancer\" "\
"jsonPayload.enforcedSecurityPolicy.name=\"${SECURITY_POLICY_NAME}\" "\
"jsonPayload.enforcedSecurityPolicy.outcome=\"DENY\""

gcloud logging read --project $TENANT_PROJECT_ID "$filter"
```

You can also view the number of allowed and denied requests by Cloud Armor in **Monitoring > Metrics Explorer**. Click on the link displayed by the command below:
```Bash
echo -e "https://console.cloud.google.com/monitoring/metrics-explorer?pageState=%7B%22xyChart%22:%7B%22dataSets%22:%5B%7B%22timeSeriesFilter%22:%7B%22filter%22:%22metric.type%3D%5C%22networksecurity.googleapis.com%2Fhttps%2Frequest_count%5C%22%20resource.type%3D%5C%22network_security_policy%5C%22%22,%22minAlignmentPeriod%22:%2260s%22,%22aggregations%22:%5B%7B%22perSeriesAligner%22:%22ALIGN_SUM%22,%22crossSeriesReducer%22:%22REDUCE_NONE%22,%22alignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%5D%7D,%7B%22crossSeriesReducer%22:%22REDUCE_NONE%22,%22alignmentPeriod%22:%2260s%22,%22groupByFields%22:%5B%5D%7D%5D%7D,%22targetAxis%22:%22Y1%22,%22plotType%22:%22LINE%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22constantLines%22:%5B%5D,%22timeshiftDuration%22:%220s%22,%22y1Axis%22:%7B%22label%22:%22y1Axis%22,%22scale%22:%22LINEAR%22%7D%7D,%22isAutoRefresh%22:true,%22timeSelection%22:%7B%22timeRange%22:%221h%22%7D%7D&project=${TENANT_PROJECT_ID}"
```

![Cloud Armor requests count metric](/images/cloud-armor-metrics.png)