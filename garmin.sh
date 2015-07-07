#!/bin/bash
# Script to automatically upload runs to Garmins website since the android app
# does not work with USB devices.
# 
# Made for Forerunner 10
#
# Requires: KDE dbus, kdialog, and gupload.pl (http://sourceforge.net/p/gcpuploader/wiki/Home/)
#
# Edit the X user, the garmin user (email) and the garmin passoword below.
# Add a rule like this to /etc/udev/rules.d/10-local.rules:
# KERNEL=="sd*", ATTRS{idVendor}=="091e", ATTRS{idProduct}=="25ca" SYMLINK+="garmin%n" RUN+="/path/to/garmin.sh"
# udev can be reloaded without reboot like this: udevadm control --reload-rules
#
# Sends a GUI status bar & summary to the :0 X session using KDE dbus & kdialog.
#


XUSER=""
GUSER=""
GPASS=""

DIR=`mktemp -d /tmp/XXXXXX`
SUBDIR="GARMIN/ACTIVITY"
FULLDIR="${DIR}/${SUBDIR}"
export DISPLAY=:0
export XAUTHORITY=/home/$XUSER/.Xauthority

sleep 3
mount ${DEVNAME} $DIR
env >> /tmp/g.log
cd ${FULLDIR}

COUNT=`ls -1 ${FULLDIR}|wc -l` 
dbusRef=`kdialog --progressbar "Uploading\nFound ${COUNT} records" ${COUNT}`

C=0
EXIST=0
NEW=0

for i in `ls -1 ${FULLDIR}`; do
    OUTPUT=`gupload.py -v 5 -l ${GUSER} ${GPASS} -t "running" $i`
    echo "${OUTPUT}" >> /tmp/g.log
# File: 56D85207.FIT    ID: 815067856    Status: EXISTS    Name: N/A    Type: N/A
    STATUS=${OUTPUT#*Status:[[:space:]]}
    STATUS=${STATUS%%[[:space:]]*}
    echo "status = ${STATUS}" >> /tmp/g.log
    if [ "x${STATUS}" == xEXISTS ];then
            EXIST=$[$EXIST + 1]
    else
            NEW=$[$NEW + 1]
    fi
    C=$[$C + 1]
    qdbus $dbusRef Set "" value ${C}
done
cd /tmp 
umount $DIR
rm -d $DIR

qdbus $dbusRef close

kdialog --msgbox "Uploaded ${C} records\n
New records: (${NEW})\n
Old records: (${EXIST})\n"
