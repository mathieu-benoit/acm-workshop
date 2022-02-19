---
title: "Check"
weight: 3
---

- Duration: 2 min

Here is what you should have at this stage:

By running `cd ~/$WORKSHOP_ORG_DIR_NAME && git log --oneline` you should get:
```Plaintext
aff11e5 (HEAD -> main, origin/main) Setting up gitops for gke config.
f95bfb9 Setting up gke namespace/project.
a088c19 Setting up billing api in config controller project.
910571c Setting up new namespace repository.
571205a Initial commit
```

By running `cd ~/$GKE_PLATFORM_DIR_NAME && git log --oneline` you should get:
```Plaintext
0eafad8 (HEAD -> main, origin/main) Initial commit
```

By running `nomos status --contexts $(kubectl config current-context)` you should get:
```Plaintext
*gke_${GKE_PROJECT_ID}_${GKE_LOCATION}_krmapihost-configcontroller
  --------------------
  <root>   https://github.com/mathieu-benoit/workshop-platform-repo/config-sync@main   
  SYNCED   aff11e5                                                                    
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
  SYNCED                  0eafad8                                                                      
```

By running `kubectl get gcp --all-namespaces` you should get:
```Plaintext
NAMESPACE        NAME                                                                                            AGE   READY   STATUS     STATUS AGE
config-control   iampartialpolicy.iam.cnrm.cloud.google.com/mabenoit-workshop-gke-sa-workload-identity-binding   47h   True    UpToDate   47h
NAMESPACE               NAME                                                                                    AGE   READY   STATUS     STATUS AGE
NAMESPACE               NAME                                                                AGE   READY   STATUS     STATUS AGE
config-control          iamserviceaccount.iam.cnrm.cloud.google.com/mabenoit-workshop-gke   47h   True    UpToDate   47h
NAMESPACE        NAME                                                                  AGE   READY   STATUS     STATUS AGE
config-control   project.resourcemanager.cnrm.cloud.google.com/mabenoit-workshop-gke   47h   True    UpToDate   47h
NAMESPACE        NAME                                                                     AGE    READY   STATUS     STATUS AGE
config-control   service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com   2d2h   True    UpToDate   2d2h
```