#!/bin/bash
set

TMP=$(mktemp -d)
UPDATE_PATH=$(find /opt/crashplan/upgrade/ -mindepth 1 -maxdepth 1 -type d -print | tail -n1)

if [[ -z ${UPDATE_PATH} ]]; then
  echo "False Trigger of update script"
  exit 1
fi

if [[ -z $USER ]]; then
  USER=root
fi

systemctl stop crashplan-pro.service
cp /opt/crashplan/bin/upgrade.sh ${TMP}/upgrade.sh

echo "Editing ${UPDATE_PATH}/install.sh"

# This used to be set to an odd locale otherwise
echo "LC_ALL=$LANG" > ${UPDATE_PATH}/run.conf

# First correct the defaults to match our system
/usr/bin/sed -i  's/^PARENT_DIR=$/PARENT_DIR=\/opt/g' ${UPDATE_PATH}/install.sh
# /usr/bin/sed -i  's/^APP_DIR=$/APP_DIR=\/opt\/crashplan/g' ${UPDATE_PATH}/install.sh
/usr/bin/sed -i  's/^APP_DIR=$/APP_DIR=\/opt/g' ${UPDATE_PATH}/install.sh
/usr/bin/sed -i  's/^BIN_DIR=$/BIN_DIR=\/opt\/crashplan\/bin/g' ${UPDATE_PATH}/install.sh

/usr/bin/sed -i  's/^MANIFEST_DIR=$/MANIFEST_DIR=\/opt\/crashplan\/manifest/g' ${UPDATE_PATH}/install.sh
/usr/bin/sed -i  's/^APP_BASENAME=.*$/APP_BASENAME="CrashPlan"/g' ${UPDATE_PATH}/install.sh

/usr/bin/sed -i '/^install_service_script/ s/./#&/' ${UPDATE_PATH}/install.sh
/usr/bin/sed -i '/^install_launcher/ s/./#&/' ${UPDATE_PATH}/install.sh
/usr/bin/sed -i '/^start_service/ s/./#&/' ${UPDATE_PATH}/install.sh

# And the uninstall section
/usr/bin/sed -i '/^[[:blank:]]*verify_target_user_dir/ s/./:#&/' ${UPDATE_PATH}/uninstall.sh
/usr/bin/sed -i '/^[[:blank:]]*remove_desktop_launchers/ s/./#&/' ${UPDATE_PATH}/uninstall.sh
/usr/bin/sed -i '/^[[:blank:]]*remove_electron_configs/ s/./#&/' ${UPDATE_PATH}/uninstall.sh
/usr/bin/sed -i '/^[[:blank:]]*strip_keys_from_indentity_file/ s/./#&/' ${UPDATE_PATH}/uninstall.sh

echo "Installing update"
set +e
chmod +x ${UPDATE_PATH}/install.sh
chmod +x ${UPDATE_PATH}/uninstall.sh
cd ${UPDATE_PATH} && ${UPDATE_PATH}/install.sh -q -v -u $USER

set -e
cp ${TMP}/upgrade.sh /opt/crashplan/bin/upgrade.sh

echo "Amending installed files"
install -D -m 755 ${UPDATE_PATH}/scripts/desktop.sh /opt/crashplan/bin/desktop.sh
install -D -m 755 ${UPDATE_PATH}/scripts/service.sh /opt/crashplan/bin/service.sh

echo "LC_ALL=$LANG" > /opt/crashplan/bin/run.conf

# Rebuild the additional steps
ln -sf "/opt/crashplan/bin/Code42Service" /opt/crashplan/bin/CrashPlanService
ln -sf "/opt/crashplan/bin/desktop.sh" /opt/crashplan/bin/CrashPlanDesktop
ln -sf "/opt/crashplan/bin/service.sh" /opt/crashplan/bin/CrashPlanEngine

rm -rf ${TMP}
rm -rf /opt/crashplan/upgrade/*

systemctl start crashplan-pro.service
echo "Done!"
