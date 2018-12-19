#!/bin/sh 
source ~/.profiles/opsman.sh $1
product=$1

curl -s -k -H 'Accept: application/json;charset=utf-8' -d 'grant_type=password' -d username=$OM_USER -d password=$OM_PASSWORD -u 'opsman:' https://$OM_HOSTNAME/uaa/oauth/token > /tmp/auth.txt
ACCESS_TOKEN=`cat /tmp/auth.txt | jq '.access_token' | tr -d '"'`

curl -s -H "Authorization: bearer $ACCESS_TOKEN" -k https://$OM_HOSTNAME/api/v0/deployed/products > /tmp/products.txt
OM_INSTALLATION_NAME=`cat /tmp/products.txt | jq ".[] | select (.type==\"$1\") | .guid" | tr -d '"'`
curl -s -H "Authorization: bearer $ACCESS_TOKEN" -k https://$OM_HOSTNAME/api/v0/deployed/products/$OM_INSTALLATION_NAME/credentials/$2 > /tmp/cred.txt
cat /tmp/cred.txt | jq '.'