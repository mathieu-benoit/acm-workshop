---
title: "Configure mTLS for OnlineBoutique"
weight: 2
---
In this section we will configure auto `mTLS` `STRICT` for the OnlineBoutique namespace.

```Bash
cat <<EOF | kubectl apply -n $ONLINEBOUTIQUE_NAMESPACE -f -
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
```