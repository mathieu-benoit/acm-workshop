---
title: "NetworkPolicy logging"
weight: 1
---
In this section we will see how your could leverage the `NetworkPolicy` logging.

```Bash
cat <<EOF | kubectl apply -f -
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