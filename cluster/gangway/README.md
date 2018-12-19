# Install Heptio Gangyway on PKS

Original content available in ; https://github.com/heptiolabs/gangway

## Retrieve PKS API Certificate

Export the PKS API variable ie.

Retrieve the PKS API Sertificate. You can either copy the field `Certificate to secure the PKS API ` from "Pivotal Container Service" Tile's "PKS API" section in Operations Manager. 

*optionally* use a linux/osx shell 

```sh
export PKSAPI=pksapi.lab.alekssaul.com:8443
ex +'/BEGIN CERTIFICATE/,/END CERTIFICATE/p' <(echo |\
  openssl s_client -showcerts -connect $PKSAPI) -scq > file.crt
```

which will retrieve the certificate from PKS API and write it to `file.crt`.

Create a `ca.yaml` file with the PKS API public certificate

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gangway-ca-certs
  namespace: gangway
data:
  rootca.crt: |
    -----BEGIN CERTIFICATE-----

    -----END CERTIFICATE-----
```

## Edit Gangway Configuration

Edit the `config.yaml` file appropiately.

Generally, the only changes you should make should be replacing the Kubernetes cluster master URL and the UAA server URL

## Deploy Gangway

Create Namespace

```sh
kubectl create namespace gangway
```

Generate session key secret

```sh
kubectl -n gangway create secret generic gangway-key \
  --from-literal=sesssionkey=$(openssl rand -base64 32)
```

Modify `ingress.yaml` and replace FQDN of gangway service with a valid entry.

Create Kubernetes configmap,deployment,service(clusterIP),ingress objects

```sh
kubectl -n gangway create -f config.yaml
kubectl -n gangway create -f deployment.yaml
kubectl -n gangway create -f service.yaml
kubectl -n gangway create -f ingress.yaml
```

## Setup UAA URL Redirect

Login to Operations Manager and login to UAA server using UAAC. This should be a similar workflow to the [PKS deployment documentation](https://docs.pivotal.io/runtimes/pks/1-2/configure-api.html#access)

Adjust the uaac client update command

```sh
export GANGWAY_URL="http://gangway.apps.pksvsphere01.lab.alekssaul.com"
uaac client update pks_cluster_client \
  --scope openid,roles,uaa.user \
  --authorized_grant_types password,refresh_token,authorization_code \
  --redirect_uri $GANGWAY_URL/callback \
  --signup_redirect_url  $GANGWAY_URL
```