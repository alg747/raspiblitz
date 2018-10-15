#!/bin/bash

# This script runs on every start and makes sure the system
# is configured like the default values or as in the config
# file /mnt/hdd/raspiblitz.cfg
# For more details see background_raspiblitzSettings.md

# load codeVersion
source /home/admin/_version.info

logfile="/home/admin/raspiblitz.log"
echo "Writing logs to: ${logfile}"
echo "" > $logfile
echo "***********************************************" >> $logfile
echo "Running RaspiBlitz Bootstrap ${codeVersion}" >> $logfile
date >> $logfile
echo "***********************************************" >> $logfile

################################
# HDD CHECK / INIT
################################

# check if the HDD is mounted
hddAvailable=$(ls -la /mnt/hdd 2>/dev/null)
if [ ${#hddAvailable} -eq 0 ]; then
  echo "HDD is NOT available" >> $logfile
  echo "TODO: Try to mount."
  exit 1
fi

################################
# CONFIGFILE BASICS
################################

# check if there is a config file
configFile="/mnt/hdd/raspiblitz.conf"
configExists=$(ls ${configFile} >/dev/null | grep -c '.conf')
if [ ${configExists} -eq 0 ]; then

  # create new config
  echo "creating config file: ${configFile}" >> $logfile
  echo "# RASPIBLITZ CONFIG FILE" > $configExists
  echo "raspiBlitzVersion='${version}'" >> $configExists

else

  # load & check config version
  source $configExists
  if [ "${raspiBlitzVersion}" != "${raspiBlitzVersion}" ]; then
      echo "detected version change ... starting migration script" >> $logfile
      /home/admin/_migrateVersion.sh
  fi

fi

################################
# DEFAULT VALUES
################################

# AUTOPILOT
# autoPilot=off|on
if [ ${#autoPilot} -eq 0 ]; then
  echo "autoPilot=off" >> $configExists
fi

# after all default values written to config - reload config
source $configExists


################################
# AUTOPILOT
################################

echo "" >> $logfile
echo "** AUTOPILOT" >> $logfile

# check if LND is installed
lndExists=$(ls /mnt/hdd/lnd/lnd.conf >/dev/null | grep -c '.conf')
if [ ${lndExists} -eq 1 ]; then

  # check if autopilot is active in LND config
  lndAutopilot=$( grep -c "autopilot.active=1" /mnt/hdd/lnd/lnd.conf )
  echo "confAutopilot(${autoPilot})" >> $logfile
  echo "lndAutopilot(${lndAutopilot})" >> $logfile

  # switch on
  if [ ${lndAutopilot} -eq 0 ] && [ "${autoPilot}" = "on" ]; then
    echo "switching the LND autopilot ON" >> $logfile
    sudo sed -i "s/^autopilot.active=.*/autopilot.active=1/g" /mnt/hdd/lnd/lnd.conf
  fi

  # switch off
  if [ ${lndAutopilot} -eq 1 ] && [ "${autoPilot}" = "off" ]; then
    echo "switching the LND autopilot OFF" >> $logfile
    sudo sed -i "s/^autopilot.active=.*/autopilot.active=0/g" /mnt/hdd/lnd/lnd.conf
  fi

else

 echo "WARNING: /mnt/hdd/lnd/lnd.conf does not exists. Setup needs to run properly first!" >> $logfile

fi

echo "" >> $logfile
echo "DONE BOOTSTRAP" >> $logfile