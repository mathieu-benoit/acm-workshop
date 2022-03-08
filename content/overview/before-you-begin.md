---
title: "Before you begin"
weight: 3
---
Before you begin you need to make sure you have the prerequisites in place.

You can run this workshop on Cloud Shell or on your local machine running Linux. Cloud Shell pre-installs all the required tools.

Install the required tools:
- [`gcloud`](https://cloud.google.com/sdk/docs/install)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl)
- `git`
- `gh` (GitHub CLI)
- `kpt`
- `curl`
- `nomos`
- `docker`

You need to have:
- GCP account with the role `owner` in your Organization in order to deploy the resources needed for this workshop
- GitHub account, it's free. We will leverage GitHub throughout this workshop.

Lastly, let's create a bash file you could run at the beginning of each lab and where we will store all the bash variables needed as you will go through this workshop:
```Bash
touch ~/acm-workshop-variables.sh
chmod +x ~/acm-workshop-variables.sh
```