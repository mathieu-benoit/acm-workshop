---
title: "Check"
weight: 8
---
- Duration: 5 min

Here is what you should have at this stage:

If you run:
```Bash
cd ~/$WORKSHOP_ORG_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                           WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Security rights for GKE project                ci        main    push   1879564426  1m8s     2m
✓       ASM rights for GKE project                     ci        main    push   1878084640  1m13s    14m
✓       GKE Hub rights for GKE project                 ci        main    push   1872423084  1m2s     1d
✓       GKE rights for GKE project                     ci        main    push   1867720906  1m4s     2d
✓       Network rights for GKE project                 ci        main    push   1865477672  1m13s    3d
✓       GitOps for GKE project                         ci        main    push   1856916572  58s      4d
✓       GKE cluster namespace/project                  ci        main    push   1856812048  1m4s     4d
✓       Billing API in Config Controller project       ci        main    push   1856221804  56s      4d
✓       Initial commit                                 ci        main    push   1856056661  1m11s    4d
```

If you run:
```Bash
cd ~/$GKE_PROJECT_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                                   WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       Ingress Gateway's SSL policy                           ci        main    push   1879568827  1m1s     1m
✓       Ingress Gateway's Cloud Armor rules                    ci        main    push   1879567800  1m1s     1m
✓       Ingress Gateway's public static IP address             ci        main    push   1878251710  1m5s     7h
✓       ASM MCP for GKE project                                ci        main    push   1873575037  1m3s     17h
✓       GitOps for GKE cluster configs                         ci        main    push   1872389473  57s      1d
✓       GKE cluster, primary nodepool and SA for GKE project   ci        main    push   1867725616  1m0s     2d
✓       Network for GKE project                                ci        main    push   1865498665  1m0s     3d
✓       Initial commit                                         ci        main    push   1856902085  1m3s     4d
```

If you run:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME && gh run list
```
You should see:
```Plaintext
STATUS  NAME                                 WORKFLOW  BRANCH  EVENT  ID          ELAPSED  AGE
✓       GitOps for Online Boutique apps      ci        main    push   1890870682  1m20s    3m
✓       ASM Ingress Gateway in GKE cluster   ci        main    push   1876989926  58s      1d
✓       mTLS STRICT in GKE cluster           ci        main    push   1879538509  1m1s     3d
✓       ASM configs in GKE cluster           ci        main    push   1879538479  1m2s     5d
✓       ASM MCP for GKE cluster              ci        main    push   1873631390  1m6s     2d
✓       Initial commit                       ci        main    push   1870893382  56s      3d
```

If you run:
```Bash
gcloud alpha anthos config sync repo describe \
   --project $GKE_PROJECT_ID \
   --managed-resources all \
   --format="multi(statuses:format=none,managed_resources:format='table[box](group:sort=2,kind,name,namespace:sort=1)')"
```
You should see:
```Plaintext
getting 2 RepoSync and RootSync from gke-hub-membership
┌───────────────────────────┬──────────────────────┬─────────────────────────┬────────────────┬─────────┐
│           GROUP           │         KIND         │           NAME          │   NAMESPACE    │  STATUS │
├───────────────────────────┼──────────────────────┼─────────────────────────┼────────────────┼─────────┤
│                           │ Namespace            │ istio-system            │                │ Current │
│                           │ Namespace            │ onlineboutique          │                │ Current │
│                           │ Namespace            │ asm-ingress             │                │ Current │
│                           │ ServiceAccount       │ asm-ingressgateway      │ asm-ingress    │ Current │
│                           │ Service              │ asm-ingressgateway      │ asm-ingress    │ Current │
│ apps                      │ Deployment           │ asm-ingressgateway      │ asm-ingress    │ Current │
│ cloud.google.com          │ BackendConfig        │ asm-ingressgateway      │ asm-ingress    │ Current │
│ networking.gke.io         │ ManagedCertificate   │ onlineboutique          │ asm-ingress    │ Current │
│ networking.gke.io         │ FrontendConfig       │ asm-ingressgateway      │ asm-ingress    │ Current │
│ networking.gke.io         │ ManagedCertificate   │ bankofanthos            │ asm-ingress    │ Current │
│ networking.istio.io       │ Gateway              │ asm-ingressgateway      │ asm-ingress    │ Current │
│ networking.k8s.io         │ Ingress              │ asm-ingressgateway      │ asm-ingress    │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ asm-ingressgateway      │ asm-ingress    │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ denyall                 │ asm-ingress    │ Current │
│ rbac.authorization.k8s.io │ RoleBinding          │ asm-ingressgateway      │ asm-ingress    │ Current │
│ rbac.authorization.k8s.io │ Role                 │ asm-ingressgateway      │ asm-ingress    │ Current │
│                           │ ConfigMap            │ istio-asm-managed-rapid │ istio-system   │ Current │
│ mesh.cloud.google.com     │ ControlPlaneRevision │ asm-managed-rapid       │ istio-system   │ Current │
│ security.istio.io         │ PeerAuthentication   │ default                 │ istio-system   │ Current │
│                           │ Service              │ frontend                │ onlineboutique │ Current │
│                           │ Service              │ shippingservice         │ onlineboutique │ Current │
│                           │ Service              │ checkoutservice         │ onlineboutique │ Current │
│                           │ Service              │ cartservice             │ onlineboutique │ Current │
│                           │ Service              │ productcatalogservice   │ onlineboutique │ Current │
│                           │ Service              │ adservice               │ onlineboutique │ Current │
│                           │ Service              │ frontend-external       │ onlineboutique │ Current │
│                           │ Service              │ currencyservice         │ onlineboutique │ Current │
│                           │ Service              │ emailservice            │ onlineboutique │ Current │
│                           │ Service              │ paymentservice          │ onlineboutique │ Current │
│                           │ Service              │ recommendationservice   │ onlineboutique │ Current │
│ apps                      │ Deployment           │ emailservice            │ onlineboutique │ Current │
│ apps                      │ Deployment           │ adservice               │ onlineboutique │ Current │
│ apps                      │ Deployment           │ cartservice             │ onlineboutique │ Current │
│ apps                      │ Deployment           │ currencyservice         │ onlineboutique │ Current │
│ apps                      │ Deployment           │ loadgenerator           │ onlineboutique │ Current │
│ apps                      │ Deployment           │ shippingservice         │ onlineboutique │ Current │
│ apps                      │ Deployment           │ checkoutservice         │ onlineboutique │ Current │
│ apps                      │ Deployment           │ recommendationservice   │ onlineboutique │ Current │
│ apps                      │ Deployment           │ paymentservice          │ onlineboutique │ Current │
│ apps                      │ Deployment           │ productcatalogservice   │ onlineboutique │ Current │
│ apps                      │ Deployment           │ frontend                │ onlineboutique │ Current │
│ configsync.gke.io         │ RepoSync             │ repo-sync               │ onlineboutique │ Current │
│ networking.istio.io       │ VirtualService       │ frontend                │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ adservice               │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ checkoutservice         │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ frontend                │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ emailservice            │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ denyall                 │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ paymentservice          │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ currencyservice         │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ recommendationservice   │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ shippingservice         │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ loadgenerator           │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ cartservice             │ onlineboutique │ Current │
│ networking.k8s.io         │ NetworkPolicy        │ productcatalogservice   │ onlineboutique │ Current │
│ rbac.authorization.k8s.io │ RoleBinding          │ repo-sync               │ onlineboutique │ Current │
│ rbac.authorization.k8s.io │ RoleBinding          │ syncs-repo              │ onlineboutique │ Current │
└───────────────────────────┴──────────────────────┴─────────────────────────┴────────────────┴─────────┘
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
getting 2 RepoSync and RootSync from krmapihost-configcontroller
┌───────────────────────────────────────┬─────────────────────────┬────────────────────────────────────────────────────┬───────────────────────┬────────────┐
│                 GROUP                 │           KIND          │                        NAME                        │       NAMESPACE       │   STATUS   │
├───────────────────────────────────────┼─────────────────────────┼────────────────────────────────────────────────────┼───────────────────────┼────────────┤
│                                       │ Namespace               │ mabenoit-workshop-gke                              │                       │ Current    │
│                                       │ Namespace               │ config-control                                     │                       │ Current    │
│                                       │ Namespace               │ default                                            │                       │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ gke-hub-admin-mabenoit-workshop-gke                │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ service-account-admin-mabenoit-workshop-gke        │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount       │ mabenoit-workshop-gke                              │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ container-admin-mabenoit-workshop-gke              │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ security-admin-mabenoit-workshop-gke               │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ service-account-user-mabenoit-workshop-gke         │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPartialPolicy        │ mabenoit-workshop-gke-sa-workload-identity-binding │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ network-admin-mabenoit-workshop-gke                │ config-control        │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ iam-admin-mabenoit-workshop-gke                    │ config-control        │ Current    │
│ resourcemanager.cnrm.cloud.google.com │ Project                 │ mabenoit-workshop-gke                              │ config-control        │ Current    │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ gkehub.googleapis.com                              │ config-control        │ Current    │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ cloudbilling.googleapis.com                        │ config-control        │ Current    │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ anthosconfigmanagement.googleapis.com              │ config-control        │ Current    │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ container.googleapis.com                           │ config-control        │ Current    │
│ serviceusage.cnrm.cloud.google.com    │ Service                 │ mesh.googleapis.com                                │ config-control        │ Current    │
│ compute.cnrm.cloud.google.com         │ ComputeSubnetwork       │ gke                                                │ mabenoit-workshop-gke │ Current    │
│ compute.cnrm.cloud.google.com         │ ComputeSSLPolicy        │ gke-asm-ingressgateway                             │ mabenoit-workshop-gke │ Current    │
│ compute.cnrm.cloud.google.com         │ ComputeSecurityPolicy   │ gke-asm-ingressgateway                             │ mabenoit-workshop-gke │ Current    │
│ compute.cnrm.cloud.google.com         │ ComputeAddress          │ gke-asm-ingressgateway                             │ mabenoit-workshop-gke │ Current    │
│ compute.cnrm.cloud.google.com         │ ComputeNetwork          │ gke                                                │ mabenoit-workshop-gke │ Current    │
│ compute.cnrm.cloud.google.com         │ ComputeRouter           │ gke                                                │ mabenoit-workshop-gke │ Current    │
│ compute.cnrm.cloud.google.com         │ ComputeRouterNAT        │ gke                                                │ mabenoit-workshop-gke │ Current    │
│ configsync.gke.io                     │ RepoSync                │ repo-sync                                          │ mabenoit-workshop-gke │ Current    │
│ container.cnrm.cloud.google.com       │ ContainerNodePool       │ primary                                            │ mabenoit-workshop-gke │ Current    │
│ container.cnrm.cloud.google.com       │ ContainerCluster        │ gke                                                │ mabenoit-workshop-gke │ Current    │
│ core.cnrm.cloud.google.com            │ ConfigConnectorContext  │ configconnectorcontext.core.cnrm.cloud.google.com  │ mabenoit-workshop-gke │ Current    │
│ gkehub.cnrm.cloud.google.com          │ GKEHubFeature           │ gke-asm                                            │ mabenoit-workshop-gke │ Current    │
│ gkehub.cnrm.cloud.google.com          │ GKEHubMembership        │ gke-hub-membership                                 │ mabenoit-workshop-gke │ Current    │
│ gkehub.cnrm.cloud.google.com          │ GKEHubFeatureMembership │ gke-acm-membership                                 │ mabenoit-workshop-gke │ Current    │
│ gkehub.cnrm.cloud.google.com          │ GKEHubFeature           │ gke-acm                                            │ mabenoit-workshop-gke │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ log-writer-gke                                     │ mabenoit-workshop-gke │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ monitoring-viewer-gke                              │ mabenoit-workshop-gke │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMServiceAccount       │ gke-primary-pool                                   │ mabenoit-workshop-gke │ Current    │
│ iam.cnrm.cloud.google.com             │ IAMPolicyMember         │ metric-writer-gke                                  │ mabenoit-workshop-gke │ Current    │
│ rbac.authorization.k8s.io             │ RoleBinding             │ syncs-repo                                         │ mabenoit-workshop-gke │ Current    │
└───────────────────────────────────────┴─────────────────────────┴────────────────────────────────────────────────────┴───────────────────────┴────────────┘
```