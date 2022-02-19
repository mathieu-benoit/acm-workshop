---
title: "Check"
weight: 3
---

- Duration: 5 min

Here is what you should have at this stage:
```Bash
git logs...
kubectl get gcp...
gh run list --workflow ci.yml

$ nomos status --contexts $(kubectl config current-context)
*gke_mabenoit-workshop_us-east1_krmapihost-configcontroller
  --------------------
  <root>   https://github.com/mathieu-benoit/workshop-platform-repo/config-sync@main   
  SYNCED   redacted                                                                    
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
  SYNCED                  redacted                                                                      
  Managed resources:
     NAMESPACE               NAME                                                  STATUS
     mabenoit-workshop-gke   computenetwork.compute.cnrm.cloud.google.com/gke      Current
     mabenoit-workshop-gke   computerouter.compute.cnrm.cloud.google.com/gke       Current
     mabenoit-workshop-gke   computerouternat.compute.cnrm.cloud.google.com/gke    Current
     mabenoit-workshop-gke   computesubnetwork.compute.cnrm.cloud.google.com/gke   Current
```