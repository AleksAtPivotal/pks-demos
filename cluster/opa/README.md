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

## Test Ingress whitelist Policy

Test ingress routes policy(./policies/ingress-whitelist.rego) by attempting to create an ingress object with "bad" host route. The idea is that the platform operator will whitelist allowed ingress domains by annotating the namespace during the namespace creation time. In example, annotating the namespace with `ingress-whitelist=alekssaul.com` will allow the OpenPolicyAgent to whitelist "alekssaul.com" domain as an allowed route for ingress.

```sh
kubectl create -f ./test/ingress.yaml
```

Should create a namespace however the ingress creation should fail as OPA denies the creation of ingress since it's not whitelist.

```text
namespace/test-opa created
Error from server (invalid ingress host "aleks.qa.acmecorp.com"): error when creating "./test/ingress.yaml": admission webhook "validating-webhook.openpolicyagent.org" denied the request: invalid ingress host "aleks.qa.acmecorp.com"
```

Execute below to clean up the test objects

```sh
kubectl delete namespace test-opa
```

## Test Restrict Registry Policy

Restrict Registry policy (./policies/restrict-registry.rego) enabled the OpenPolicyAgent to deny creation of Deployment and Replicasets if the image registry is not explicitly specified in the policy. This policy can help platform operators to restrict use of Public registries such as dockerhub, gcr.io etc. As an example policy in this repository only allows images to be deployed from "Quay.io" and "gcr.io".

```sh
kubectl create -f ./test/registry.yaml
```

Will create `test-opa-registry` namespace however the replicaset and deployment objects will fail with

```text
namespace/test-opa-registry created
Error from server (invalid deployment: whitelisted registry not found. namespace="test-opa-registry", name="bad-registry", registry="nginx:alpine"): error when creating "./test/registry.yaml": admission webhook "validating-webhook.openpolicyagent.org" denied the request: invalid deployment: whitelisted registry not found. namespace="test-opa-registry", name="bad-registry", registry="nginx:alpine"
Error from server (invalid replicaset: whitelisted registry not found. namespace="test-opa-registry", name="bad-registry-rs", registry="nginx:alpine"): error when creating "./test/registry.yaml": admission webhook "validating-webhook.openpolicyagent.org" denied the request: invalid replicaset: whitelisted registry not found. namespace="test-opa-registry", name="bad-registry-rs", registry="nginx:alpine"
```

Delete the namespace once completed

```sh
kubectl delete namespace test-opa-registry
```

## Test Pod allowPrivilegeEscalation policy

Pod Priveledge Escalation policy (./policies/pod-priveledgeescalation.rego) denies creation of Pod's with container Spec.SecurityContext `allowPrivilegeEscalation: true` if the namespace is not annotate by  `opa-allowPrivilegeEscalation: "true"`.

Execute the Pod Securuty Escalation YAML to create the appropiate namespace and Deployment, ReplicaSet, Pod objects

```sh
kubectl create -f ./test/pod-securityescalation.yaml
```

You should get a response stating that Namespace and replicaset objects were created however other objects are not allowed. This is because the ReplicaSet is set to `allowPrivilegeEscalation: false` whereas Deployment and Pod objects use `allowPrivilegeEscalation: true`.

```text
namespace/test-opa-podsecurity created
replicaset.apps/securitycontext-replicaset created
Error from server (allowPrivilegeEscalation is not allowed for the namespace: "test-opa-podsecurity"): error when creating "./test/pod-securityescalation.yaml": admission webhook "validating-webhook.openpolicyagent.org" denied the request: allowPrivilegeEscalation is not allowed for the namespace: "test-opa-podsecurity"
Error from server (allowPrivilegeEscalation is not allowed for the namespace: "test-opa-podsecurity"): error when creating "./test/pod-securityescalation.yaml": admission webhook "validating-webhook.openpolicyagent.org" denied the request: allowPrivilegeEscalation is not allowed for the namespace: "test-opa-podsecurity"
```

Let's clean up the namespace and re-create the objects using the namespace with correct annotations from the "pod-securityescalation-allowed.yaml" file. Notice the difference between the two files:

```sh
diff ./test/pod-securityescalation.yaml ./test/pod-securityescalation-allowed.yaml
6c6
<     #opa-allowPrivilegeEscalation: "true"
---
>     opa-allowPrivilegeEscalation: "true"
```

Cleanup the namespace and re-create the objects;

```sh
kubectl delete namespace test-opa-podsecurity
kubectl create -f ./test/pod-securityescalation-allowed.yaml
```

You should notice that all the objects have been created successfully.

```text
namespace/test-opa-podsecurity created
pod/security-context-demo created
deployment.apps/securitycontext-deployment created
replicaset.apps/securitycontext-replicaset created
```

Remember to remove the namespace
```sh
kubectl delete namespace test-opa-podsecurity
```