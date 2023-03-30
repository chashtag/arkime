#!/bin/bash
set -e


until [[ -f /var/run/init/init_done ]]
do
    echo "Waiting for init to finish"
    sleep 5
done

echo "Starting as ${SERVICE_NAME}"

if [[ "$SERVICE_NAME" == "viewer" ]]
then
    pushd $ARKIME_DIR/viewer
    $ARKIME_DIR/bin/node viewer.js --insecure -c $ARKIME_DIR/etc/config.ini | tee -a $ARKIME_DIR/logs/viewer.log 2>&1
    popd
elif [[ "$SERVICE_NAME" == "wise" ]]
then
    echo would start wise here
elif [[ "$SERVICE_NAME" == "capture" ]]
then
    pushd $ARKIME_DIR
    . $ARKIME_DIR/etc/capture.env || true
    $ARKIME_DIR/bin/arkime_config_interfaces.sh -c $ARKIME_DIR/etc/config.ini -n default
    $ARKIME_DIR/bin/capture -c $ARKIME_DIR/etc/config.ini ${OPTIONS} | tee -a $ARKIME_DIR/logs/capture.log 2>&1
    popd
fi