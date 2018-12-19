# Kubernetes RBAC

Document covers a sample setup for granting access to users within a kubernetes cluster.

## Workflow

1. Create a new namespace
1. Create service accounts
1. Grant appropiate RBAC rights to the user(s)
1. Generate kubeconfig files for the User(s)
1. Validate

### Create a new namespace

We will use Kubernetes namespaces to group/limit access for particular user(s). Namespaces can be individually setup with Access controls and quotas

Create a new namespace

```sh
$ kubectl create namespace example
namespace/example created

```

### Create service accounts

We will create ServiceAccount objects within a namespace. We will use these accounts as a subject for Role Based Access Control

Create `sa-example-user01.yaml` manifest to create `ServiceAccounts` for user(s).

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: example-user01
```

Create example-user01 and other users as necessary

```sh
$ kubectl --namespace example create -f sa-example-user01.yaml
serviceaccount "example-user01" created
```

### Grant appropiate RBAC rights to the user(s)

Create a new `ClusterRoleBinding` to bind the user(s) to a view only ClusterRole. This role/binding will be used as the base access level for the user to the cluster. Create `crb-example-users.yaml` file with below content.

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: example-users
subjects:
  - kind: ServiceAccount
    name: example-user01
    namespace: example
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
```

Create the ClusterRoleBinding object

```sh
$ kubectl --namespace example create -f crb-example-users.yaml
clusterrolebinding.rbac.authorization.k8s.io "example-users" created
```

Create `Role` for administrating all objects within the namespace `example`. Create `role-namespace-admin.yaml` file with below content.

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: namespace-admin
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```

Create the namespace-admin Role

```sh
$ kubectl --namespace example create -f role-namespace-admin.yaml
role.rbac.authorization.k8s.io "namespace-admin" created
```

Bind the serviceaccounts to the Role. Create `rb-example-admin.yaml` file with below content.

```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: example-admin
subjects:
  - kind: ServiceAccount 
    name: example-user01
roleRef:
  kind: Role
  name: namespace-admin
  apiGroup: rbac.authorization.k8s.io
```

Create the example-admin role binding in example namespace

```sh
$ kubectl --namespace example create -f rb-example-admin.yaml
rolebinding.rbac.authorization.k8s.io "example-admin" created
```

### Generate kubeconfig files for the User(s)

Now that we have the users setup and access granted, we'll want to generate kubeconfig files to provide to our end users.

User `create-kubeconfig.sh` to generate a kubeconfig file for the user.

```sh
./create-kubeconfig.sh example-user01 -n example > example-user01.config
```

### Validate

Change the kubectl context to example01 user

```sh
export KUBECONFIG=$PWD/example-user01.config
```

One of the limitations of the "view" only role is that, we can't access `Secret` objects cluster-wide.

```sh
$ kubectl get secrets --all-namespaces
Error from server (Forbidden): secrets is forbidden: User "system:serviceaccount:example:example-user01" cannot list secrets at the cluster scope
```

However this works within the namespace

```sh
$ kubectl --namespace example get secrets
NAME                         TYPE                                  DATA      AGE
default-token-j8hb6          kubernetes.io/service-account-token   3         58m
example-user01-token-j5nrb   kubernetes.io/service-account-token   3         51m
```

Similarly we can create/view/delete objects within our namespace

```sh
$ kubectl --namespace example run nginx --image=nginx --replicas=1
deployment.apps "nginx" created
$ kubectl --namespace example get pods
NAME                   READY     STATUS    RESTARTS   AGE
nginx-8586cf59-7zwcv   1/1       Running   0          16s
$ kubectl --namespace example delete deployment nginx
deployment.extensions "nginx" deleted
```

However we can't do this on other namespaces such as `default`

```sh
$ kubectl --namespace=default run nginx --image=nginx --replicas=1
Error from server (Forbidden): deployments.extensions is forbidden: User "system:serviceaccount:example:example-user01" cannot create deployments.extensions in the namespace "default"
```