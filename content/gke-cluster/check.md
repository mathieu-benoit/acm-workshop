---
title: "Check"
weight: 3
---

- Duration: 2 min

Here is what you should have at this stage:

`cd ~/$WORKSHOP_ORG_DIR_NAME && git log --oneline`
```Plaintext
42ebeff (HEAD -> main, origin/main) Setting up GKE rights for project ${GKE_PROJECT_ID}.
5eb80f5 Container admin role for ${GKE_PROJECT_ID} sa and container service enablement for project ${GKE_PROJECT_ID}.
3554281 Setting up container admin role for ${GKE_PROJECT_ID} sa.
495d32e Setting up network admin role for ${GKE_PROJECT_ID} sa.
aff11e5 Setting up gitops for gke config.
f95bfb9 Setting up gke namespace/project.
a088c19 Setting up billing api in config controller project.
910571c Setting up new namespace repository.
571205a Initial commit
```

`cd ~/$GKE_PLATFORM_DIR_NAME && git log --oneline`
```Plaintext
a57e8df (HEAD -> main, origin/main) Create GKE cluster, GKE primary nodepool and associated sa for project ${GKE_PROJECT_ID}.
6627884 Setting up network for ${GKE_PROJECT_ID}.
0eafad8 Initial commit
```

`nomos status --contexts $(kubectl config current-context)`
```Plaintext
*gke_${GKE_PROJECT_ID}_${GKE_LOCATION}_krmapihost-configcontroller
  --------------------
  <root>   https://github.com/mathieu-benoit/workshop-platform-repo/config-sync@main   
  SYNCED   42ebeffe                                                                    
  Managed resources:
     NAMESPACE               NAME                                                                                                  STATUS
                             namespace/config-control                                                                              Current
                             namespace/default                                                                                     Current
                             namespace/mabenoit-workshop-gke                                                                       Current
     config-control          iampartialpolicy.iam.cnrm.cloud.google.com/mabenoit-workshop-gke-sa-workload-identity-binding         Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/container-admin-mabenoit-workshop-gke                       Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/iam-admin-mabenoit-workshop-gke                             Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/network-admin-mabenoit-workshop-gke                         Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-admin-mabenoit-workshop-gke                 Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-user-mabenoit-workshop-gke                  Current
     config-control          iamserviceaccount.iam.cnrm.cloud.google.com/mabenoit-workshop-gke                                     Current
     config-control          project.resourcemanager.cnrm.cloud.google.com/mabenoit-workshop-gke                                   Current
     config-control          service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com                                Current
     config-control          service.serviceusage.cnrm.cloud.google.com/container.googleapis.com                                   Current
     mabenoit-workshop-gke   configconnectorcontext.core.cnrm.cloud.google.com/configconnectorcontext.core.cnrm.cloud.google.com   Current
     mabenoit-workshop-gke   reposync.configsync.gke.io/repo-sync                                                                  Current
     mabenoit-workshop-gke   rolebinding.rbac.authorization.k8s.io/syncs-repo                                                      Current
  --------------------
  mabenoit-workshop-gke   https://github.com/mathieu-benoit/workshop-gke-config-repo/config-sync@main   
  SYNCED                  a57e8df8                                                                      
  Managed resources:
     NAMESPACE               NAME                                                              STATUS
     mabenoit-workshop-gke   computenetwork.compute.cnrm.cloud.google.com/gke                  Current
     mabenoit-workshop-gke   computerouter.compute.cnrm.cloud.google.com/gke                   Current
     mabenoit-workshop-gke   computerouternat.compute.cnrm.cloud.google.com/gke                Current
     mabenoit-workshop-gke   computesubnetwork.compute.cnrm.cloud.google.com/gke               Current
     mabenoit-workshop-gke   containercluster.container.cnrm.cloud.google.com/gke              Current
     mabenoit-workshop-gke   containernodepool.container.cnrm.cloud.google.com/primary         Current
     mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/log-writer-gke          Current
     mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/metric-writer-gke       Current
     mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/monitoring-viewer-gke   Current
     mabenoit-workshop-gke   iamserviceaccount.iam.cnrm.cloud.google.com/gke-primary-pool      Current
```

`kubectl get gcp --all-namespaces`
```Plaintext
NAMESPACE               NAME                                                 AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computerouternat.compute.cnrm.cloud.google.com/gke   12h   True    UpToDate   8h
NAMESPACE               NAME                                                  AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computesubnetwork.compute.cnrm.cloud.google.com/gke   12h   True    UpToDate   12h
NAMESPACE               NAME                                              AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computerouter.compute.cnrm.cloud.google.com/gke   12h   True    UpToDate   8h
NAMESPACE               NAME                                               AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computenetwork.compute.cnrm.cloud.google.com/gke   13h   True    UpToDate   13h
NAMESPACE               NAME                                                        AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   containernodepool.container.cnrm.cloud.google.com/primary   41m   True    UpToDate   39m
NAMESPACE               NAME                                                   AGE     READY   STATUS     STATUS AGE
mabenoit-workshop-gke   containercluster.container.cnrm.cloud.google.com/gke   7h18m   True    UpToDate   7h8m
NAMESPACE        NAME                                                                                            AGE   READY   STATUS     STATUS AGE
config-control   iampartialpolicy.iam.cnrm.cloud.google.com/mabenoit-workshop-gke-sa-workload-identity-binding   47h   True    UpToDate   47h
NAMESPACE               NAME                                                                                    AGE   READY   STATUS     STATUS AGE
config-control          iampolicymember.iam.cnrm.cloud.google.com/container-admin-mabenoit-workshop-gke         11h   True    UpToDate   11h
config-control          iampolicymember.iam.cnrm.cloud.google.com/iam-admin-mabenoit-workshop-gke               69m   True    UpToDate   69m
config-control          iampolicymember.iam.cnrm.cloud.google.com/network-admin-mabenoit-workshop-gke           13h   True    UpToDate   13h
config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-admin-mabenoit-workshop-gke   8h    True    UpToDate   8h
config-control          iampolicymember.iam.cnrm.cloud.google.com/service-account-user-mabenoit-workshop-gke    8h    True    UpToDate   8h
mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/log-writer-gke                                67m   True    UpToDate   67m
mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/metric-writer-gke                             64m   True    UpToDate   64m
mabenoit-workshop-gke   iampolicymember.iam.cnrm.cloud.google.com/monitoring-viewer-gke                         64m   True    UpToDate   63m
NAMESPACE               NAME                                                                AGE   READY   STATUS     STATUS AGE
config-control          iamserviceaccount.iam.cnrm.cloud.google.com/mabenoit-workshop-gke   47h   True    UpToDate   47h
mabenoit-workshop-gke   iamserviceaccount.iam.cnrm.cloud.google.com/gke-primary-pool        8h    True    UpToDate   8h
NAMESPACE        NAME                                                                  AGE   READY   STATUS     STATUS AGE
config-control   project.resourcemanager.cnrm.cloud.google.com/mabenoit-workshop-gke   47h   True    UpToDate   47h
NAMESPACE        NAME                                                                     AGE    READY   STATUS     STATUS AGE
config-control   service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com   2d2h   True    UpToDate   2d2h
config-control   service.serviceusage.cnrm.cloud.google.com/container.googleapis.com      10h    True    UpToDate   10h
```