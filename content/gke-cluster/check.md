---
title: "Check"
weight: 5
---
- Duration: 2 min

Here is what you should have at this stage:

By running `cd ~/$WORKSHOP_ORG_DIR_NAME && git log --oneline` you should get:
```Plaintext
a0dfa11 (HEAD -> main, origin/main) Setting up GKE Hub rights for project mabenoit-workshop-gke.
42ebeff Setting up GKE rights for project mabenoit-workshop-gke.
5eb80f5 Container admin role for mabenoit-workshop-gke sa and container service enablement for project mabenoit-workshop-gke.
3554281 Setting up container admin role for mabenoit-workshop-gke sa.
495d32e Setting up network admin role for ${GKE_PROJECT_ID} sa.
aff11e5 Setting up gitops for gke config.
f95bfb9 Setting up gke namespace/project.
a088c19 Setting up billing api in config controller project.
910571c Setting up new namespace repository.
571205a Initial commit
```

By running `cd ~/$GKE_PROJECT_DIR_NAME && git log --oneline` you should get:
```Plaintext
beb5f76 (HEAD -> main, origin/main) Set up GKE configs's Git repo
a57e8df Create GKE cluster, GKE primary nodepool and associated sa for project mabenoit-workshop-gke.
6627884 Setting up network for ${GKE_PROJECT_ID}.
0eafad8 Initial commit
```

By running `nomos status --contexts $(kubectl config current-context)` you should get:
```Plaintext
*gke_mabenoit-workshop_us-east1_krmapihost-configcontroller
  --------------------
  <root>   https://github.com/mathieu-benoit/workshop-platform-repo/config-sync@main   
  SYNCED   a0dfa113                                                                    
  Managed resources:
     NAMESPACE               NAME                                                                                                  STATUS
                             namespace/config-control                                                                              Current
                             namespace/default                                                                                     Current
                             namespace/mabenoit-workshop-gke                                                                       Current
     config-control          iampartialpolicy.iam.cnrm.cloud.google.com/mabenoit-workshop-gke-sa-workload-identity-binding         Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/container-admin-mabenoit-workshop-gke                       Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/gke-hub-admin-mabenoit-workshop-gke                         Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/iam-admin-mabenoit-workshop-gke                             Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/network-admin-mabenoit-workshop-gke                         Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-admin-mabenoit-workshop-gke                 Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-user-mabenoit-workshop-gke                  Current
     config-control          iamserviceaccount.iam.cnrm.cloud.google.com/mabenoit-workshop-gke                                     Current
     config-control          project.resourcemanager.cnrm.cloud.google.com/mabenoit-workshop-gke                                   Current
     config-control          service.serviceusage.cnrm.cloud.google.com/anthosconfigmanagement.googleapis.com                      Current
     config-control          service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com                                Current
     config-control          service.serviceusage.cnrm.cloud.google.com/container.googleapis.com                                   Current
     config-control          service.serviceusage.cnrm.cloud.google.com/gkehub.googleapis.com                                      Current
     mabenoit-workshop-gke   configconnectorcontext.core.cnrm.cloud.google.com/configconnectorcontext.core.cnrm.cloud.google.com   Current
     mabenoit-workshop-gke   reposync.configsync.gke.io/repo-sync                                                                  Current
     mabenoit-workshop-gke   rolebinding.rbac.authorization.k8s.io/syncs-repo                                                      Current
  --------------------
  mabenoit-workshop-gke   https://github.com/mathieu-benoit/workshop-gke-config-repo/config-sync@main   
  SYNCED                  beb5f76c                                                                      
  Managed resources:
     NAMESPACE               NAME                                                                      STATUS
     mabenoit-workshop-gke   computenetwork.compute.cnrm.cloud.google.com/gke                          Current
     mabenoit-workshop-gke   computerouter.compute.cnrm.cloud.google.com/gke                           Current
     mabenoit-workshop-gke   computerouternat.compute.cnrm.cloud.google.com/gke                        Current
     mabenoit-workshop-gke   computesubnetwork.compute.cnrm.cloud.google.com/gke                       Current
     mabenoit-workshop-gke   containercluster.container.cnrm.cloud.google.com/gke                      Current
     mabenoit-workshop-gke   containernodepool.container.cnrm.cloud.google.com/primary                 Current
     mabenoit-workshop-gke   gkehubfeature.gkehub.cnrm.cloud.google.com/gke-acm                        Current
     mabenoit-workshop-gke   gkehubfeaturemembership.gkehub.cnrm.cloud.google.com/gke-acm-membership   Current
     mabenoit-workshop-gke   gkehubmembership.gkehub.cnrm.cloud.google.com/gke-hub-membership          Current
     mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/log-writer-gke                  Current
     mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/metric-writer-gke               Current
     mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/monitoring-viewer-gke           Current
     mabenoit-workshop-gke   iamserviceaccount.iam.cnrm.cloud.google.com/gke-primary-pool              Current
```

By running `kubectl get gcp --all-namespaces`
```Plaintext
NAMESPACE               NAME                                               AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computenetwork.compute.cnrm.cloud.google.com/gke   2d    True    UpToDate   67m
NAMESPACE               NAME                                                 AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computerouternat.compute.cnrm.cloud.google.com/gke   47h   True    UpToDate   6h58m
NAMESPACE               NAME                                                  AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computesubnetwork.compute.cnrm.cloud.google.com/gke   47h   True    UpToDate   67m
NAMESPACE               NAME                                              AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computerouter.compute.cnrm.cloud.google.com/gke   47h   True    UpToDate   67m
NAMESPACE               NAME                                                   AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   containercluster.container.cnrm.cloud.google.com/gke   42h   True    UpToDate   67m
NAMESPACE               NAME                                                        AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   containernodepool.container.cnrm.cloud.google.com/primary   36h   True    UpToDate   143m
NAMESPACE               NAME                                                 AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   gkehubfeature.gkehub.cnrm.cloud.google.com/gke-acm   12h   True    UpToDate   143m
NAMESPACE               NAME                                                               AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   gkehubmembership.gkehub.cnrm.cloud.google.com/gke-hub-membership   11h   True    UpToDate   100m
NAMESPACE               NAME                                                                      AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   gkehubfeaturemembership.gkehub.cnrm.cloud.google.com/gke-acm-membership   11h   True    UpToDate   100m
NAMESPACE               NAME                                                                                    AGE   READY   STATUS     STATUS AGE
config-control          iampolicymember.iam.cnrm.cloud.google.com/container-admin-mabenoit-workshop-gke         47h   True    UpToDate   47h
config-control          iampolicymember.iam.cnrm.cloud.google.com/gke-hub-admin-mabenoit-workshop-gke           12h   True    UpToDate   12h
config-control          iampolicymember.iam.cnrm.cloud.google.com/iam-admin-mabenoit-workshop-gke               36h   True    UpToDate   36h
config-control          iampolicymember.iam.cnrm.cloud.google.com/network-admin-mabenoit-workshop-gke           2d    True    UpToDate   2d
config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-admin-mabenoit-workshop-gke   44h   True    UpToDate   44h
config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-user-mabenoit-workshop-gke    43h   True    UpToDate   43h
mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/log-writer-gke                                36h   True    UpToDate   68m
mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/metric-writer-gke                             36h   True    UpToDate   101m
mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/monitoring-viewer-gke                         36h   True    UpToDate   101m
NAMESPACE               NAME                                                                AGE     READY   STATUS     STATUS AGE
config-control          iamserviceaccount.iam.cnrm.cloud.google.com/mabenoit-workshop-gke   3d11h   True    UpToDate   3d11h
mabenoit-workshop-gke   iamserviceaccount.iam.cnrm.cloud.google.com/gke-primary-pool        44h     True    UpToDate   101m
NAMESPACE        NAME                                                                                            AGE     READY   STATUS     STATUS AGE
config-control   iampartialpolicy.iam.cnrm.cloud.google.com/mabenoit-workshop-gke-sa-workload-identity-binding   3d11h   True    UpToDate   3d11h
NAMESPACE        NAME                                                                  AGE     READY   STATUS     STATUS AGE
config-control   project.resourcemanager.cnrm.cloud.google.com/mabenoit-workshop-gke   3d11h   True    UpToDate   3d10h
NAMESPACE        NAME                                                                               AGE     READY   STATUS     STATUS AGE
config-control   service.serviceusage.cnrm.cloud.google.com/anthosconfigmanagement.googleapis.com   12h     True    UpToDate   12h
config-control   service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com             3d13h   True    UpToDate   3d13h
config-control   service.serviceusage.cnrm.cloud.google.com/container.googleapis.com                45h     True    UpToDate   45h
config-control   service.serviceusage.cnrm.cloud.google.com/gkehub.googleapis.com                   17h     True    UpToDate   17h
```