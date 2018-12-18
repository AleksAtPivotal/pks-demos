# Deploy NGINX container with a static page

Create an nginx deployment with static webpage

```sh
export configmapname=appconfig
kubectl create configmap $configmapname --from-file=./static
```

Deploy the nginx deployment and expose it as a service