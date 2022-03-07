---
title: "Set up Sidecar"
weight: 4
---
- Persona: Apps Operator
- Duration: 5 min
- Objectives:
  - FIXME

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

```Bash
cat <<EOF > ~/$WHERE_AMI_DIR_NAME/config-sync/sidecar.yaml
apiVersion: networking.istio.io/v1beta1
kind: Sidecar
metadata:
  name: whereami
  namespace: ${WHEREAMI_NAMESPACE}
spec:
  workloadSelector:
    labels:
      app: whereami
  egress:
  - hosts:
    - "istio-system/*"
EOF
```

Deploy all these Kubernetes manifests via a GitOps approach:
```Bash
cd ~/$WHERE_AMI_DIR_NAME/
git add .
git commit -m "Whereami Sidecar"
git push
```