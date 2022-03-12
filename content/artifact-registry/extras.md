---
title: "Extras"
weight: 4
description: "Duration: 3 min"
---
_{{< param description >}}_

Do you want more optional exercises? Here you are!

Initialize variables:
```Bash
source ~/acm-workshop-variables.sh
```

## Validate Policies

Let's define a `Deployment` violating the `allowed-container-registries` `Constraint` previously created:
```Bash
cat <<EOF > ~/$GKE_CONFIGS_DIR_NAME/config-sync/nginx-test.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF
```

And now let's evaluate this `Constraint` on the current Kubernetes manifests we have locally and see the error:
```Bash
kpt fn eval ~/$GKE_CONFIGS_DIR_NAME/config-sync \
    -i gatekeeper:v0.2
```

You could rollback this local change if you want:
```Bash
rm ~/$GKE_CONFIGS_DIR_NAME/config-sync/nginx-test.yaml
```