---
title: "Check"
weight: 3
---

- Duration: 2 min

Here is what you should have at this stage:

`cd ~/$WORKSHOP_ORG_DIR_NAME && git log --oneline`
```Plaintext
495d32e (HEAD -> main, origin/main) Setting up network admin role for ${GKE_PROJECT_ID} sa.
aff11e5 Setting up gitops for gke config.
f95bfb9 Setting up gke namespace/project.
a088c19 Setting up billing api in config controller project.
910571c Setting up new namespace repository.
571205a Initial commit
```

`cd ~/$GKE_PLATFORM_DIR_NAME && git log --oneline`
```Plaintext
6627884 (HEAD -> main, origin/main) Setting up network for ${GKE_PROJECT_ID}.
0eafad8 Initial commit
```

`nomos status --contexts $(kubectl config current-context)`
```Plaintext
*gke_${GKE_PROJECT_ID}_${GKE_LOCATION}_krmapihost-configcontroller
  --------------------
  <root>   https://github.com/mathieu-benoit/workshop-platform-repo/config-sync@main   
  SYNCED   495d32e                                                                    
  Managed resources:
     NAMESPACE               NAME                                                                                                  STATUS
                             namespace/config-control                                                                              Current
                             namespace/default                                                                                     Current
                             namespace/mabenoit-workshop-gke                                                                       Current
     config-control          iampartialpolicy.iam.cnrm.cloud.google.com/mabenoit-workshop-gke-sa-workload-identity-binding         Current
     config-control          iampolicymember.iam.cnrm.cloud.google.com/network-admin-mabenoit-workshop-gke                         Current
     config-control          iamserviceaccount.iam.cnrm.cloud.google.com/mabenoit-workshop-gke                                     Current
     config-control          project.resourcemanager.cnrm.cloud.google.com/mabenoit-workshop-gke                                   Current
     config-control          service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com                                Current
     mabenoit-workshop-gke   configconnectorcontext.core.cnrm.cloud.google.com/configconnectorcontext.core.cnrm.cloud.google.com   Current
     mabenoit-workshop-gke   reposync.configsync.gke.io/repo-sync                                                                  Current
     mabenoit-workshop-gke   rolebinding.rbac.authorization.k8s.io/syncs-repo                                                      Current
  --------------------
  mabenoit-workshop-gke   https://github.com/mathieu-benoit/workshop-gke-config-repo/config-sync@main   
  SYNCED                  6627884                                                                      
  Managed resources:
     NAMESPACE               NAME                                                  STATUS
     mabenoit-workshop-gke   computenetwork.compute.cnrm.cloud.google.com/gke      Current
     mabenoit-workshop-gke   computerouter.compute.cnrm.cloud.google.com/gke       Current
     mabenoit-workshop-gke   computerouternat.compute.cnrm.cloud.google.com/gke    Current
     mabenoit-workshop-gke   computesubnetwork.compute.cnrm.cloud.google.com/gke   Current
```

`kubectl get gcp --all-namespaces`
```Plaintext
NAMESPACE               NAME                                              AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computerouter.compute.cnrm.cloud.google.com/gke   36m   True    UpToDate   36m
NAMESPACE               NAME                                               AGE    READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computenetwork.compute.cnrm.cloud.google.com/gke   106m   True    UpToDate   106m
NAMESPACE               NAME                                                 AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computerouternat.compute.cnrm.cloud.google.com/gke   33m   True    UpToDate   33m
NAMESPACE               NAME                                                  AGE   READY   STATUS     STATUS AGE
mabenoit-workshop-gke   computesubnetwork.compute.cnrm.cloud.google.com/gke   48m   True    UpToDate   48m
NAMESPACE        NAME                                                                              AGE     READY   STATUS     STATUS AGE
config-control   iampolicymember.iam.cnrm.cloud.google.com/network-admin-mabenoit-workshop-gke     108m    True    UpToDate   108m
NAMESPACE        NAME                                                                AGE   READY   STATUS     STATUS AGE
config-control   iamserviceaccount.iam.cnrm.cloud.google.com/mabenoit-workshop-gke   35h   True    UpToDate   35h
NAMESPACE        NAME                                                                                            AGE   READY   STATUS     STATUS AGE
config-control   iampartialpolicy.iam.cnrm.cloud.google.com/mabenoit-workshop-gke-sa-workload-identity-binding   35h   True    UpToDate   35h
NAMESPACE        NAME                                                                  AGE   READY   STATUS     STATUS AGE
config-control   project.resourcemanager.cnrm.cloud.google.com/mabenoit-workshop-gke   35h   True    UpToDate   35h
NAMESPACE        NAME                                                                     AGE   READY   STATUS     STATUS AGE
config-control   service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com   38h   True    UpToDate   38h
```