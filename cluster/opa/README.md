# Install Open Policy Agent on PKS

Original Instructions are located on the Open Policy Agent [website](https://www.openpolicyagent.org/docs/kubernetes-admission-control.html)

Run the TLS generation script

```sh
./create-tls.sh
```

Create Kubernetes namespace and generate secrets

```sh
kubectl create ns opa
kubectl create secret tls opa-server --cert=server.crt --key=server.key -n opa
```

Deploy the Admissions Controller

```sh
kubectl create -f admission-controller.yaml -n opa
```

Generate webhook-configuration.yaml by executing the script and create it in Kubernetes

```sh
./create-webhook.sh
kubectl apply -f webhook-configuration.yaml -n opa
```

You should be able to see the webhook-configuration by executing;

```sh
kubectl get validatingwebhookconfigurations opa-validating-webhook -o yaml
```

Load test policy

```sh
kubectl create configmap opa-policies --from-file=./policies/ -n opa
```

