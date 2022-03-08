---
title: "Set up Memorystore"
weight: 3
---
- Persona: Platform Admin
- Duration: 10 min

Initialize variables:
```Bash
echo "export REDIS_NAME=cart" >> ~/acm-workshop-variables.sh
source ~/acm-workshop-variables.sh
```

```Bash
mkdir ~/$GKE_PROJECT_DIR_NAME/config-sync/$ONLINEBOUTIQUE_NAMESPACE
```

## Define Memorystore (redis)

Define the [Memorystore (redis) resource](https://cloud.google.com/config-connector/docs/reference/resource-docs/redis/redisinstance):
```Bash
cat <<EOF > ~/$GKE_PROJECT_DIR_NAME/config-sync/$ONLINEBOUTIQUE_NAMESPACE/memorystore.yaml
apiVersion: redis.cnrm.cloud.google.com/v1beta1
kind: RedisInstance
metadata:
  name: ${REDIS_NAME}
  namespace: ${GKE_PROJECT_ID}
spec:
  region: ${GKE_LOCATION}
  tier: BASIC
  memorySizeGb: 1
  redisVersion: REDIS_6_X
  authorizedNetworkRef:
    name: ${GKE_NAME}
EOF
```

## Deploy Kubernetes manifests

```Bash
cd ~/$GKE_PROJECT_DIR_NAME/
git add .
git commit -m "Memorystore (redis) instance"
git push
```

## Grab Memorystore (redis) connection information

Make sure the Memorystore (redis) instance is successfully provisioned and grab its associated connection information we will leverage in the next section:
```Bash
export REDIS_IP=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(host)')
export REDIS_PORT=$(gcloud redis instances describe $REDIS_NAME --region=$GKE_LOCATION --project=$GKE_PROJECT_ID --format='get(port)')
echo $REDIS_IP
echo $REDIS_PORT
echo "export REDIS_IP=${REDIS_IP}" >> ~/acm-workshop-variables.sh
echo "export REDIS_PORT=${REDIS_PORT}" >> ~/acm-workshop-variables.sh
```