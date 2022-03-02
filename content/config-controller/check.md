---
title: "Check"
weight: 3
---
- Duration: 2 min

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                      WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Billing API in Config Controller project  ci        main    push   1923237183  14s      0m
✓       Initial commit                            ci        main    push   1922899373  1m2s     1h
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
  --project $CONFIG_CONTROLLER_PROJECT_ID \
  --managed-resources all \
  --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌────────────────────────────────────┬───────────┬─────────────────────────────┬────────────────┐
│               GROUP                │    KIND   │             NAME            │   NAMESPACE    │
├────────────────────────────────────┼───────────┼─────────────────────────────┼────────────────┤
│                                    │ Namespace │ config-control              │                │
│ serviceusage.cnrm.cloud.google.com │ Service   │ cloudbilling.googleapis.com │ config-control │
└────────────────────────────────────┴───────────┴─────────────────────────────┴────────────────┘
```