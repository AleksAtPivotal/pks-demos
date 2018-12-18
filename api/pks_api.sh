#!/bin/bash

export PKSAPI_DOMAIN=pksapi.lab.alekssaul.com
export PKSAPI_USERNAME=pksuaa
export PKSAPI_PASSWORD=Password!

function init(){
    PKSAPI_ACCESSTOKEN=$(curl https://$PKSAPI_DOMAIN:8443/oauth/token -s -k -XPOST -H \
        'Accept: application/json' \
        -d "client_id=pks_cli&client_secret=""&grant_type=password&username=$PKSAPI_USERNAME&response_type=id_token" --data-urlencode password=$PKSAPI_PASSWORD \
        | jq '.access_token' \
        | tr -d '"' )


    if [ "$PKSAPI_ACCESSTOKEN" = "" ] || [ "$PKSAPI_REFRESHTOKEN" = "null"  ]; then
        echo "Could Not fetch PKS API ACCESS Token"
        exit 1
    fi
}

# pks_clusters lists PKS clusters to sysout
function pks_clusters(){
    curl -s --header "Authorization: Bearer $PKSAPI_ACCESSTOKEN"\
    -X GET "https://$PKSAPI_DOMAIN:9021/v1/clusters" \
    -H "accept: application/json" -k | jq '.' 
   
}


# pks_delete_cluster $PKS_ClusterName - Deletes a cluster
## !!!THIS IS DISTRUPTIVE!!!
function pks_delete_cluster(){
    local PKS_ClusterName=$1
    curl -s --header "Authorization: Bearer $PKSAPI_ACCESSTOKEN"\
    -X DELETE "https://$PKSAPI_DOMAIN:9021/v1/clusters/$PKS_ClusterName" \
    -H "accept: application/json" -k | jq '.' 
   
}

# pks_resize_cluster $PKS_ClusterName $PKS_NumberOfNodes - Resizes the number of nodes 
function pks_resize_cluster(){
    local PKS_ClusterName=$1
    local PKS_NumberOfNodes=$2

    curl -k -s --header "Authorization: Bearer $PKSAPI_ACCESSTOKEN"\
    -X PATCH "https://$PKSAPI_DOMAIN:9021/v1/clusters/$PKS_ClusterName" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{ \"kubernetes_worker_instances\": $PKS_NumberOfNodes}" | jq '.' 

}

# pks_create_cluster $PKS_ClusterName $PKS_ExternalHostname $PKS_ClusterPlan $PKS_NumberOfNodes - Creates a new cluster 
function pks_create_cluster(){
    local PKS_ClusterName=$1
    local PKS_ExternalHostname=$2
    local PKS_ClusterPlan=$3
    local PKS_NumberOfNodes=$4
    
    curl -k -s --header "Authorization: Bearer $PKSAPI_ACCESSTOKEN"\
    -X POST "https://$PKSAPI_DOMAIN:9021/v1/clusters/" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{ \"name\": \"$PKS_ClusterName\", \"parameters\": { \"kubernetes_master_host\": \"$PKS_ExternalHostname\", \"kubernetes_master_port\": 8443, \"kubernetes_worker_instances\": $PKS_NumberOfNodes }, \"plan_name\": \"$PKS_ClusterPlan\"}" | jq '.'     
}

# pks_get_credentials  $PKS_ClusterName - Gets K8s Credentials for the cluster
function pks_get_credentials(){
    local PKS_ClusterName=$1

    kubeconfig_json=$(curl -k -s --header "Authorization: Bearer $PKSAPI_ACCESSTOKEN"\
    -X POST "https://$PKSAPI_DOMAIN:9021/v1/clusters/$PKS_ClusterName/binds" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" )
    
    K8s_API=$(echo $kubeconfig_json | jq '.clusters[].cluster.server' | tr -d '"') 
    echo $K8s_API

    K8sAPI_ACCESSTOKEN=$(curl https://$PKSAPI_DOMAIN:8443/oauth/token -s -k -XPOST -H \
        'Accept: application/json' \
        -d "client_id=pks_cluster_client&client_secret=""&grant_type=password&username=$PKSAPI_USERNAME&response_type=id_token" --data-urlencode password=$PKSAPI_PASSWORD \
        | jq '.access_token' \
        | tr -d '"' )
    
    if [ "$K8sAPI_ACCESSTOKEN" = "" ] || [ "$K8sAPI_ACCESSTOKEN" = "null"  ]; then
        echo "Could Not fetch PKS API ACCESS Token"
        exit 1
    fi
}

# k8s_get_namespaces - Get Kubernetes namespaces
function k8s_get_namespaces(){
    curl -k -s --header "Authorization: Bearer $K8sAPI_ACCESSTOKEN"\
    -X GET "$K8s_API/api/v1/namespaces" \
    -H "accept: application/json" 
}

# k8s_get_namespaces $K8s_NamespaceName - Get Kubernetes namespaces
function k8s_create_namespace(){
    local K8s_NamespaceName=$1

    curl -k -s --header "Authorization: Bearer $K8sAPI_ACCESSTOKEN"\
    -X POST "$K8s_API/api/v1/namespaces" \
    -H "accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{ \"apiVersion\": \"v1\", \"metadata\": { \"name\": \"$K8s_NamespaceName\" }, \"kind\": \"Namespace\"}" \
    | jq '.'     
}

init
# pks_clusters 
# pks_create_cluster test test.lab.alekssaul.com small 2
# pks_resize_cluster test 3
# pks_delete_cluster test 
# pks_get_credentials test
# k8s_get_namespaces examplenamespace