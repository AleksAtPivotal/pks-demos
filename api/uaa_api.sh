#!/bin/bash

export UAA_DOMAIN=pksapi.lab.alekssaul.com
export UAA_USERNAME=admin
export UAA_PASSWORD=XTtoTVjxEMTAOuEkQ

function init(){
    UAA_ACCESSTOKEN=$(curl "https://$UAA_DOMAIN:8443/oauth/token" -s -k -u "$UAA_USERNAME:$UAA_PASSWORD" -X POST \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        -H 'Accept: application/json' \
        -d 'grant_type=client_credentials&token_format=opaque' \
        | jq '.access_token' \
        | tr -d '"' )


    if [ "$UAA_ACCESSTOKEN" = "" ] ; then
        echo "Could Not fetch UAA API ACCESS Token"
        exit 1
    fi
}

# lists all the external group mappings (ie. LDAP to UAA mapping)
## !! This needs to be called as it returns groupID information for PKS groups
function groupmappings_get(){
    GROUPMAPPINS=$(curl "https://$UAA_DOMAIN:8443/Groups/External?startIndex=1&count=50&origin=ldap&externalGroup=&filter=" -k \
    -s -H "Authorization: Bearer $UAA_ACCESSTOKEN" ) 
    GROUPID_PKSCLUSTERSMANAGE=$(echo $GROUPMAPPINS | \
        jq '.resources[] | select (.displayName == "pks.clusters.manage") | .groupId' | \
        tr -d '"')
    GROUPID_PKSCLUSTERSADMIN=$(echo $GROUPMAPPINS | \
        jq '.resources[] | select (.displayName == "pks.clusters.admin") | .groupId' | \
        tr -d '"')

    ##### sample output  #####
    ## !!! Notice pks.cluster.manage and admin groups map to LDAP groups
    # {
    #   "displayName": "organizations.acme",
    #   "externalGroup": "cn=test_org,ou=people,o=springsource,o=org",
    #   "groupId": "6b5ce376-2906-4369-a4ac-6d5b78a82783",
    #   "origin": "ldap"
    # }
    # {
    #   "displayName": "pks.clusters.manage",
    #   "externalGroup": "cn=pks_clusters_manage,ou=groups,ou=pivotal,dc=alekssaul,dc=local",
    #   "groupId": "9b7b3e2f-17b0-4fa8-9fc0-9fafce997c93",
    #   "origin": "ldap"
    # }
    # {
    #   "displayName": "pks.clusters.admin",
    #   "externalGroup": "cn=pks_clusters_admin,ou=groups,ou=pivotal,dc=alekssaul,dc=local",
    #   "groupId": "f1d55427-0e9d-42a4-b704-56cd3048fdf4",
    #   "origin": "ldap"
    # }    

}

# performs function similar to uaac group map --name $1 $2
# $1 must be pks.clusters.admin or pks.clusters.manage for PKS v1.2
# $2 is the DN to LDAP group
function groupmappings_map(){
    check_group $1
    local group_name=$1 
    local ldap_group_dn=$2
    local payload="{
    \"groupId\" : \"$groupid\",
    \"externalGroup\" : \"$ldap_group_dn\",
    \"origin\" : \"ldap\",
    \"schemas\" : [ \"urn:scim:schemas:core:1.0\" ]
    }
    "

    curl "https://$UAA_DOMAIN:8443/Groups/External" \
    -X POST -k \
    -s -H "Authorization: Bearer $UAA_ACCESSTOKEN" \
    -H 'Content-Type: application/json' \
    -d "$payload"
    
    groupid=""
}

# performs function similar to uaac group unmap
# $1 must be pks.clusters.admin or pks.clusters.manage for PKS v1.2
# $2 is the DN to LDAP group
function groupmappings_unmap(){
    check_group $1
    local group_name=$1 
    local ldap_group_dn=$2

    curl "https://$UAA_DOMAIN:8443/Groups/External/groupId/$groupid/externalGroup/$ldap_group_dn/origin/ldap" \
    -X DELETE -k \
    -s -H "Authorization: Bearer $UAA_ACCESSTOKEN" 

    groupid=""
}

function check_group(){
    groupid=""
    local groupname=$1
    if [ $groupname != "pks.clusters.admin" ] && [ $groupname != "pks.clusters.manage" ] ; then
        echo "GroupName $1 is not supported, PKS group name must be pks.clusters.admin or pks.clusters.manage"
        exit 1
    fi
    if [ $groupname == "pks.clusters.admin" ] ; then
        groupid=$GROUPID_PKSCLUSTERSADMIN
    elif [ $groupname == "pks.clusters.manage" ] ; then
        groupid=$GROUPID_PKSCLUSTERSMANAGE
    fi
}

init
groupmappings_get
