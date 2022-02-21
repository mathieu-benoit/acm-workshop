---
title: "Check"
weight: 3
---
- Duration: 2 min

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                       WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Billing API in Config Controller project   ci        main    push   1856221804  56s      4d
✓       Initial commit                             ci        main    push   1856056661  1m11s    4d
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
  --project $CONFIG_CONTROLLER_PROJECT_ID \
  --managed-resources all \
  --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1,status)')"
```
You should see:
```Plaintext
getting 1 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬─────────────────────────┬────────────────────────────────────────────────────┬───────────────────────┬──────────┐
│                 GROUP                 │           KIND          │                        NAME                        │       NAMESPACE       │   STATUS │
├───────────────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼───────────────────────┼──────────│
│                                       │ Namespace               │ config-control                                     │                       │ Current  │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ cloudbilling.googleapis.com                        │ config-control        │ Current  │
└───────────────────────────────────────┴─────────────────────────┴────────────────────────────────────────────────────┴───────────────────────┴──────────┘
```