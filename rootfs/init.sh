#!/bin/bash
set -e

echo "Initializing"

echo "Checking that Elasticsearch is running and ready"
until [[ "$(curl -sSL 'http://elastic:elastic@es.rancher.home/_cat/health?h=status')" == "green" ]]
do
    echo "Waiting for Elastic to come up"
    sleep 5
done
echo "Elasticsearch up"


echo "Checking that arkime has been initialized Elasticsearch"
if [[ -z "$(curl -sSL ${ELASTIC_AUTH_URL}/_cat/indices/arkime*)" ]] 
then
    echo "Initializing Elasticsearch"
    ${ARKIME_DIR}/db/db.pl $ELASTIC_AUTH_URL initnoprompt
    ${ARKIME_DIR}/bin/arkime_add_user.sh $ARKIME_ADMIN_USER "Admin User" $ARKIME_ADMIN_PASSWORD --admin
    echo "Initialized Elasticsearch"
else
    echo "Elasticsearch already initialized"
fi



echo "Initialized"
mkdir -p /var/run/init
touch /var/run/init/init_done