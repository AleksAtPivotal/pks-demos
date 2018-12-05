# PKS PodSecurityPolicy (PSP)

Quick howto on enabling PodSecurityPolciies in PKS.

Goal of the exercise is to create a PSP that does not allow priveledge escalation and priveledged containers by default, however allow it for certain workloads as needed.

## Enable PodSecurityPolicy (PSP) in PKS

***Note that PSP settings are currently (PKS v1.2.3) not supported. The changes made through this section does not persist when BOSH managed state changes such as cluster upgrades or failed-master-resurrection occurs***

Setup BOSH cli and login to master VM(s) within the particular PKS cluster.

```sh
bosh -e pks -d service-instance_eb059d57-e43e-43df-ba7b-a8c66e7dae71 ssh master/0
```

Switch to root and modify kube-apiserver bpm file

```sh
sudo su
vi /var/vcap/jobs/kube-apiserver/config/bpm.yml
```

Append "PodSecurityPolicy" the `enable-admission-plugins` property ie.

```text
  - --enable-admission-plugins=LimitRanger,DefaultTolerationSeconds,ValidatingAdmissionWebhook,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook
```

becomes

```text
  - --enable-admission-plugins=LimitRanger,DefaultTolerationSeconds,ValidatingAdmissionWebhook,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook,PodSecurityPolicy
```

Save the file and restart kube-apiserver

```sh
monit restart kube-apiserver
```

You should now see indication of PodSecurityPolicy being enabled in kube-apiserver logs.

```sh
cat /var/vcap/sys/log/kube-apiserver/kube-apiserver.stderr.log | grep -i podsecuritypolicy
```

command will return "PodSecurityPolicy" being loaded as a mutating admission controller and validating admission controller plugin.

## Setting up high level PodSecurityPolicies

Below flow will create a PSP object `nonprivileged`. Review the policy before proceeding further to understand the implications

```sh
cat psp-restricted.yaml
```

We will also create a new ClusterRole to use this policy and make it accessible to all accounts within the cluster with the clusterrolebinding

```sh
# Create "default" PodSecurityPolicy nonpriveledged
kubectl create -f psp-restricted.yaml
# Create ClusterRole and ClusterRole bindings to allow all users to access "default" PodSecurityPolicy
kubectl create -f cr-privc-denied.yaml
kubectl create -f crb-privc-denied.yaml
```

Validate that a user can create a standard deployment

```sh
kubectl run nginx --image=nginx
kubectl get pods
```

Above example should return Pods running if succesful.

Cleanup the test deployment

```sh
kubectl delete deployment nginx
```

Attempt to create a priveledged pod

```sh
kubectl create -f ./example/deployment-pspdemo-priveledged.yaml
```

You should recieve an error stating Privileged containers are not allowed;

```text
Error from server (Forbidden): error when creating "./example/pod-pspdemo-priveledged.yaml": pods "priveledgedpod" is forbidden: unable to validate against any pod security policy: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]
```

remove the test deployment

```sh
kubectl delete -f ./example/deployment-pspdemo-priveledged.yaml
```

### Creating a namespace for priveledged containers

Let's continue by creating a "priviledged" PodSecurityPolicy to run priveledged containers.

```sh
# Create PodSecurityPolicy priveledged
kubectl create -f psp-priviledged.yaml
```

Create a namespace

```sh
kubectl create namespace psp-test
```

Create a Role in the namespace and RoleBindings for the service account of namespace

```sh
kubectl create -n psp-test -f role-privc-allowed.yaml
kubectl create -n psp-test -f rb-privc-allowed.yaml
```

Create the example deployment in `psp-test` and `default` namespaces and observe the difference

```sh
kubectl create -n psp-test -f ./example/deployment-pspdemo-priveledged.yaml
kubectl create -n default -f ./example/deployment-pspdemo-priveledged.yaml
```

There should be Deployment, ReplicaSet and Pod objects in `psp-test` namespace as this namespace allows running priviledged containers. `default` namespace however will not have Pod object as PodSecurityPolicy denys creation of Priviledged container "by default".

Remove the test deployments & cleanup

```sh
kubectl delete -n psp-test -f ./example/deployment-pspdemo-priveledged.yaml
kubectl delete -n default -f ./example/deployment-pspdemo-priveledged.yaml
```