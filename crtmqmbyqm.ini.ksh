#!/bin/ksh
# crtmqmbyqm.ini.ksh
# This script is to create QMGR based on qm.ini
# And should be run only if the files from /var/mqm/ and /var/mqm/log were missing
# 
# parameter:
# -c : Create QMGRs, otherwise will only display the command
# -f <path>/qm.ini : by defaul this script get qm.ini from /var/mqm
#
# QMINI="`cat ./*qm.ini`"
# crtmqm -u ${SDLQ} ${WLOG} ${WLP} ${WLS} ${WLF} ${WLD} ${WMD} -q $QM


WLOG="-lc"
SDLQ="SYSTEM.DEAD.LETTER.QUEUE"
for i in `ls ./*qm.ini` ; do
#    pwd
#    echo "cat [$i]"
#    cat $i
#${WLOG} ${WLP} ${WLS} ${WLF} ${WLD} ${WMD} -q $QM
    WLP="-lp `cat $i|grep LogPrimaryFiles|awk -F= '{print $2}'`"
#${WLOG}  ${WLS} ${WLF} ${WLD} ${WMD} -q $QM
    WLS="-ls `cat $i|grep LogSecondaryFiles|awk -F= '{print $2}'`"
#${WLOG}  ${WLF} ${WLD} ${WMD} -q $QM
    WLF="-lf `cat $i|grep LogFilePages|awk -F= '{print $2}'`"
#${WLOG}  ${WLD} ${WMD} -q $QM
    LOG="`cat $i|grep LogType|awk -F= '{print $2}'`"
    if [ "${LOG}" = "LINEAR" ] ; then export WLOG="-ll" ; fi
# ${WLD} ${WMD} -q $QM
    QM="`cat $i|grep LogPath|awk -F\/ '{print $5}'`"
    echo "crtmqm -u ${SDLQ} ${WLOG} ${WLP} ${WLS} ${WLF} ${WLD} ${WMD} -q $QM"
#    crtmqm -u ${SDLQ} ${WLOG} ${WLP} ${WLS} ${WLF} ${WLD} ${WMD} -q $QM
done


