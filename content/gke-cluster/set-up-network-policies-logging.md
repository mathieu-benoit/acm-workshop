---
title: "Set up Network Policies logging"
weight: 5
---
- Persona: Platform Admin
- Duration: 5 min
- Objectives:
  - FIXME

```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/networkpolicies-logging.yaml
kind: NetworkLogging
apiVersion: networking.gke.io/v1alpha1
metadata:
  name: default
spec:
  cluster:
    allow:
      log: false
      delegate: false
    deny:
      log: true
      delegate: false
EOF
```

Deploy all this `NetworkLogging` resource via a GitOps approach:
```Bash
cd ~/$GKE_CONFIGS_DIR_NAME/
git add .
git commit -m "Network Policies logging"
git push
```