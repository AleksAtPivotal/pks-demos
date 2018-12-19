#!/bin/sh

if [[ ! $(which kubectl) ]]; then
		echo `date` - ERROR: Could Not Found kubectl binary
		exit 1 ;
fi

if [[ ! $(which jq) ]]; then
		echo `date` - ERROR: Could Not Found jq binary
		exit 1 ;
fi

if [[ ! $(which curl) ]]; then
		echo `date` - ERROR: Could Not Found curl binary
		exit 1 ;
fi

if [[ ! $1 ]]; then 
		echo ERROR: Please provide kubectl context name
        echo Example: create-user-kubeconfig.sh cluster01
		exit 1 ;
fi 

pkscluster=$1
ClusterCAdata=$(kubectl config view --raw -o json | jq '.clusters[]|select(.name == "'$pkscluster'") | .cluster."certificate-authority-data" ' | tr -d '"' )
ClusterServer=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name == "'$pkscluster'")].cluster.server}')
Username=$(kubectl config view --raw -o jsonpath='{.contexts[?(@.name == "'$pkscluster'")].context.user}')
UserIDPurl=$(kubectl config view --raw -o jsonpath='{.users[?(@.name == "'$Username'")].user.auth-provider.config.idp-issuer-url}')

read -p "PKS Username: " pksusername
read -s -p "PKS Password: " pkspassword
echo -e

userresp=$(curl "$UserIDPurl" -k -XPOST -s \
    -H 'Accept: application/json' \
    -d "client_id=pks_cluster_client&client_secret=""&grant_type=password&username=$pksusername&password=$pkspassword&response_type=id_token")

id_token=$(echo $userresp | jq '.id_token' |  tr -d '"' )
refresh_token=$(echo $userresp | jq '.refresh_token' |  tr -d '"' )

cat <<EOF >"$pkscluster_$pksusername.config"
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $ClusterCAdata
    server: $ClusterServer
  name: $pkscluster
contexts:
- context:
    cluster: $pkscluster
    user: $pksusername
  name:  $pkscluster
current-context: $pkscluster
kind: Config
preferences: {}
users:
- name:  $pksusername
  user: 
    auth-provider:
      config:
        client-id: pks_cluster_client
        cluster_client_secret: ""
        id-token: $id_token
        idp-issuer-url: $UserIDPurl
        refresh-token:  $refresh_token
      name: oidc
EOF
