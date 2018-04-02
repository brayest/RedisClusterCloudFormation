#!/bin/bash

echo "Gettin Configuration"

CONFIG=./bootstrap.conf
CONSUL=$(cat $CONFIG | grep CONSUL | awk -F "::" '{print $2}')
REDIS_MASTER=$(cat $CONFIG | grep REDIS_MASTER | awk -F "::" '{print $2}')
REDIS_SLAVE1=$(cat $CONFIG | grep REDIS_SLAVE1 | awk -F "::" '{print $2}')
REDIS_SLAVE2=$(cat $CONFIG | grep REDIS_SLAVE2 | awk -F "::" '{print $2}')
REDIS_SLAVE3=$(cat $CONFIG | grep REDIS_SLAVE3 | awk -F "::" '{print $2}')
WEB_APP=$(cat $CONFIG | grep WEB_APP | awk -F "::" '{print $2}')
KEY=$(cat $CONFIG | grep KEY | awk -F "::" '{print $2}')

echo "Uploading cookbooks"
knife cookbook upload redis_master consul_server redis_slave web_app
echo "Bootstraping instances"
knife bootstrap $CONSUL --ssh-user ec2-user --sudo --identity-file $KEY --node-name CONSUL --run-list 'recipe[consul_server]'
knife bootstrap $REDIS_MASTER --ssh-user ubuntu --sudo --identity-file $KEY --node-name REDIS_MASTER --run-list 'recipe[redis_master]'
knife bootstrap $REDIS_SLAVE1 --ssh-user ubuntu --sudo --identity-file $KEY --node-name REDIS_SLAVE1 --run-list 'recipe[redis_slave]'
knife bootstrap $REDIS_SLAVE2 --ssh-user ubuntu --sudo --identity-file $KEY --node-name REDIS_SLAVE2 --run-list 'recipe[redis_slave]'
knife bootstrap $REDIS_SLAVE3 --ssh-user ubuntu --sudo --identity-file $KEY --node-name REDIS_SLAVE3 --run-list 'recipe[redis_slave]'
knife bootstrap $WEB_APP --ssh-user ubuntu --sudo --identity-file $KEY --node-name WEB_APP --run-list 'recipe[web_app]'
