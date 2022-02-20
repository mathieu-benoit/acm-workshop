---
title: "Check"
weight: 3
---
- Duration: 2 min

Here is what you should have at this stage:

By running `cd ~/$WORKSHOP_ORG_DIR_NAME && git log --oneline` you should get:
```Plaintext
a088c19 (HEAD -> main, origin/main) Setting up billing api in config controller project.
910571c Setting up new namespace repository.
571205a Initial commit
```

By running `nomos status --contexts $(kubectl config current-context)` you should get:
```Plaintext
*gke_${GKE_PROJECT_ID}_${GKE_LOCATION}_krmapihost-configcontroller
  --------------------
  <root>   https://github.com/mathieu-benoit/workshop-platform-repo/config-sync@main   
  SYNCED   a088c19                                                                    
  Managed resources:
     NAMESPACE               NAME                                                                                                  STATUS
                             namespace/config-control                                                                              Current
     config-control          service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com                                Current
```

By running `kubectl get gcp --all-namespaces` you should get:
```Plaintext
NAMESPACE        NAME                                                                     AGE    READY   STATUS     STATUS AGE
config-control   service.serviceusage.cnrm.cloud.google.com/cloudbilling.googleapis.com   2d2h   True    UpToDate   2d2h
```