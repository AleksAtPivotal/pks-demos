#!/bin/sh

if [[ ! $(which kubectl) ]]; then
		echo `date` - ERROR: Could Not Found kubectl binary
		exit 1 ;
fi

if [[ ! $(which jq) ]]; then
		echo `date` - ERROR: Could Not Found jq binary
		exit 1 ;
fi

if [[ ! $1 ]]; then 
		echo ERROR: Please provide kubectl context name
        echo Example: create-blank-kubeconfig.sh cluster01
		exit 1 ;
fi 

pkscluster=$1
# Below seem to cause an issue with Kubectl v1.11.2 & v1.11.3 but works on v1.12.0
# ClusterCAdata=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name == "'$pkscluster'")].cluster.certificate-authority-data}')
ClusterCAdata=$(kubectl config view --raw -o json | jq '.clusters[]|select(.name == "'$pkscluster'") | .cluster."certificate-authority-data" ' | tr -d '"' )
ClusterServer=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name == "'$pkscluster'")].cluster.server}')
Username=$(kubectl config view --raw -o jsonpath='{.contexts[?(@.name == "'$pkscluster'")].context.user}')
UserIDPurl=$(kubectl config view --raw -o jsonpath='{.users[?(@.name == "'$Username'")].user.auth-provider.config.idp-issuer-url}')

cat <<EOF >$pkscluster.config
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $ClusterCAdata
    server: $ClusterServer
  name: $pkscluster
contexts:
- context:
    cluster: $pkscluster
    user: PROVIDED-BY-USER
  name:  $pkscluster
current-context: $pkscluster
kind: Config
preferences: {}
users:
- name:  $Username
  user: 
    auth-provider:
      config:
        client-id: pks_cluster_client
        cluster_client_secret: ""
        id-token: PROVIDED-BY-USER
        idp-issuer-url: $UserIDPurl
        refresh-token:  PROVIDED-BY-USER
      name: oidc
EOF
