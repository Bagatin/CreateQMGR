#!/bin/ksh
# crtqmgr.sh
# Copyright IBM Corp. 2006, 2011
# Carlos Alberto Bagatin - cbagatin@br.ibm.com
# 03/07/2008 - v0.1
################################################################################
# Script to create the qmgr based of parameters file crtqmgr_QMGR.ini
#
{
SCRIPTVER="1.0"
SCRIPTDATE="09 Dec 2014"
#
# Script to create QMGR based on files:
# - crtqmgr_chls.ini -
# - crtqmgr_mqsin.ini -
# - crtqmgr_QMGR.ini -
# - crtqmgr_xtras.ini -
#
# USAGE: crtqmgr.sh
#
# NOTE - 0.4 version was included on file crtqmgr_QMGR.ini the parameters
#        for High Availability
#        LD=/MQHA/<QMGR>/log  << Indicate the MQ Log Files on external file system
#        MD=/MQHA/<QMGR>/data << Indicate the MQ Data Files on external file system
#        HACMD=YES << Indicate that scripts will provide the command line
#                     to run in another node.
#REVISION HISTORY##############################################################
# 0.1 10/24/02 First tested-working version
# 0.2 03/29/03 Minor formatting
# 0.3 04/15/03
# 0.4 10/24/11 Included features related with MQ Statistics
#              and parameters to create QMGR on High Availability
# 0.5 10/17/12 Changed the way to create the SDLQ getting the parameter
#              SDLQ from crtqmgr_QMGR.ini then moving process to SYSTEM.DEAD.LETTER.QUEUE
# 0.6 12/09/14 Included the field QMDESCR where is described the QMGR
#-----------------------------------------------------------------------------
#
# ENVIRONMENT
#
function Sintaxe
{
   echo "ERROR: File [${ARQ}] with QMGR parameters is not found ..."
   echo "       Check if it was created on the same directory and retry !!!!!"
   echo "Exiting !!! "
   exit -1
}
function Sintaxe2
{
   echo "ERROR: Parameter QM on file [${ARQ}] with ${QM} is invalide ..."
   echo "       And there's no QMGR Name specified as the parameter "
   echo "       ./crtqmgr.sh -q QMGR_NAME"
   echo "Exiting !!! "
   exit -1
}
# export the current PATH and set the QMGR.ini file parameters
export HCHG="${PWD}"
export ARQ="${HCHG}/crtqmgr_QMGR.ini"
# Check if file with QMGR parameters exist
if [[ ! -f ${ARQ} ]]; then
   Sintaxe ${ARQ}
   exit -1
fi
# Check if was informed the QMGR Name as first parameters
# ATTENTION: The QMGR Name will by passed as informed on crtqmgr_QMGR.ini
if [[ "$1" != "" ]] ; then
   export QM=$1
   echo "$0 - Setting Queue Manager Name: [${QM}]"
else
   # Get the QMGR Name from parameter's file or $1
   export QM=`grep '^QM' $ARQ|awk -F= '{print $2}'`
   if [[ "${QM}" == "<QMGR>" ]] ; then
      Sintaxe2
   fi
fi
# Get the current parameters from QMGR.ini file

export QMDESCR=`grep '^QMDESCR' $ARQ|awk -F= '{print $2}'`
export LOG=`grep '^LOG' $ARQ|awk -F= '{print $2}'`
export QM=`grep '^QM' $ARQ|awk -F= '{print $2}'`
export QMDIR=`echo $QM|sed "s/\./\\\!/g"`
export LP=`grep '^LP' $ARQ|awk -F= '{print $2}'`
export LS=`grep '^LS' $ARQ|awk -F= '{print $2}'`
export LF=`grep '^LF' $ARQ|awk -F= '{print $2}'`
export PORT=`grep '^PORT' $ARQ|awk -F= '{print $2}'`
export LISTENER="LISTENER.$PORT"
export DEADP="DEAD.PROCESS"
export DLQN="SYSTEM.DEAD.LETTER.QUEUE"
export SDLQ=`grep '^SDLQ' $ARQ|awk -F= '{print $2}'`
#export SDIQ="SYSTEM.DEFAULT.INITIATION.QUEUE"
# once the SDIQ is diferent from SYSTEM.DEFAULT, it must be include the
# def ql on crtqmgr_xtras.ini file
export SDIQ="INITQ"
export DEADRULE="${HCHG}/deadrules.$SDLQ"
export WLOG="-lc"
export QMGRX="$HCHG/crtqmgr_xtras.ini"
export MQSIN="$HCHG/crtqmgr_mqsin.ini"
export MQCHL="$HCHG/crtqmgr_chls.ini"
export MQNOD="$HCHG/crtqmgr_node.sh"
# Get parameters for High Availability
export LD=`grep '^LD' $ARQ|awk -F= '{print $2}'`
export MD=`grep '^MD' $ARQ|awk -F= '{print $2}'`
export HACMD=`grep '^HACMD' $ARQ|awk -F= '{print $2}'`
# Check with SO to provide the path of mq binary
if [ "`uname -s`" = "AIX" ] ; then
   export RUNDLQ='/usr/bin/runmqdlq'
   export STARTCMD='/usr/mqm/bin/runmqtrm'
   export STOPCMD='/usr/mqm/bin/amqsstop'
elif [ "`uname -s`" = "Linux" ] ; then
   export RUNDLQ='/opt/mqm/bin/runmqdlq'
   export STARTCMD='/opt/mqm/bin/runmqtrm'
   export STOPCMD='/opt/mqm/bin/amqsstop'
else
   echo "ERROR: No OS found by uname [`uname -s`]"
   echo "Exiting !!!!"
   exit -1
fi
# Setting parameters to creat a LINEAR MQ LOG
if [ "${LOG}" = "LINEAR" ] ; then export WLOG="-ll" ; fi
if [ "${LP}" != "" ] ; then export WLP="-lp ${LP} " ; fi
if [ "${LS}" != "" ] ; then export WLS="-ls ${LS} " ; fi
if [ "${LF}" != "" ] ; then export WLF="-lf ${LF} " ; fi
# Set the mq.ini file based on MQ configuration
if [ "${HACMD}" = "YES" ] ; then
   # Setting parameters to creat MQ on High Availability environment
   if [ "${LD}" != "" ] ; then export WLD="-ld ${LD} " ; fi
   if [ "${MD}" != "" ] ; then export WMD="-md ${MD} " ; fi
   export MQS="${MD}/${QMDIR}/qm.ini"
else
   export MQS="/var/mqm/qmgrs/${QMDIR}/qm.ini"
fi

####################################################
###   M A I N   ####################################
####################################################
#
echo "$0 - This script will create and configurate the QMGR based on crtqmgr files "
echo "$0 - Wait a moment please !!!"
####
#
echo "STEP1: ### Creating the qmgr using the parameters from file ${ARQ} ###"
#
crtmqm -u ${SDLQ} ${WLOG} ${WLP} ${WLS} ${WLF} ${WLD} ${WMD} -q $QM
#
echo "STEP1: done !!"
#
####
#
echo "STEP2: ### Checking if needs to append entries on ${MQS} ###"
echo "STEP2: ### from file ${MQSIN} (don't create it if you don't need this aditional entries. ###"
if [[ -f ${MQSIN} ]] ; then
   grep ^Channels\: ${MQS} >/dev/null
   if [ $? -eq 1 ] ; then
      cp ${MQS} ${MQS}.old
      cat ${MQSIN}|grep -v ^# >> ${MQS}
   fi
fi
#
echo "STEP2: done !!"
#
####
#
echo "STEP3: ### Starting Queue Manager ${QM} ###"
strmqm $QM
echo "STEP3: done !!"
#
#####
#
echo "STEP4: ### Checking if needs extra entries on QMGR parameters from ${QMGRX} ###"
if [[ -f ${QMGRX} ]] ; then
   runmqsc ${QM} < ${QMGRX}
fi
#
echo "STEP4: done !!!"
#
#####
#
echo "STEP5: ### Checking we have Channels  from ${MQCHL} ###"
if [[ -f ${MQCHL} ]] ; then
   echo "STEP5: ### Starting the customization from QMGR based on MQSeries Stardards ###"
   runmqsc ${QM} < ${MQCHL}
fi
echo "STEP5: done !!!"
#
#####
#
echo "STEP6: ### Creating Listener based on var PORT=${PORT} ###"
if [ "${PORT}" != "" ] ; then

   runmqsc $QM <<-EOF
*
DEFINE LISTENER(${LISTENER}) TRPTYPE(TCP)                         +
       DESCR('Listener to QMGR: ${QM} on Port ${PORT}')           +
* Requested by Lenny Luo - see on qmgr_details.txt
       BACKLOG(0)                                                 +
       CONTROL(QMGR)                                              +
       PORT(${PORT})

START LISTENER(${LISTENER})

DISPLAY LSSTATUS(${LISTENER})
*
EOF

fi
echo "STEP6: done !!!"
#
#####
#
echo "STEP7: ### Creating a service for Trig monitor  ###"
   runmqsc $QM <<-EOF
*
DEFINE QL(${SDIQ}) LIKE (SYSTEM.CHANNEL.INITQ)
*
DEFINE SERVICE(TRIGMON1)                                          +
       CONTROL(QMGR)                                              +
       SERVTYPE(SERVER)                                           +
       STARTCMD('${STARTCMD}')                                    +
       STARTARG('-m +QMNAME+ -q ${SDIQ}')                         +
       STOPCMD('${STOPCMD}')                                      +
       STOPARG('-m +QMNAME+ -p +MQ_SERVER_PID+')

START  SERVICE(TRIGMON1)

DISPLAY SVSTATUS(TRIGMON1)

EOF

echo "STEP7: done !!!"
#
#####
#
echo "STEP8: ### Checking if have SYSTEM DEAD LETTER QUEUE customization ###"
if [ "${SDLQ}" != "" ] ; then
#
   echo "STEP8: ### Creating the file to handle for SYSTEM.DEAD.LETTER.QUEUE ###"
   cat > ${DEADRULE} <<-EOF
* dead letter queue handler rules  ${QM}
* Copyright IBM Corp. 2001, 2005
*
* control parameters (defaults)
RETRYINT(60) WAIT(60)

* for msgs placed on DLQ because dest q is full, attempt to put msg on dest q
REASON(MQRC_Q_FULL) ACTION(RETRY) RETRY(5)

* for msgs placed on DLQ because dest q is put-inhibited, attempt to put msg on
* dest q
REASON(MQRC_PUT_INHIBITED) ACTION(RETRY) RETRY(5)

* sample app-specific rules
*DESTQ(APPNAME.*) ACTION (FWD)  FWDQ(APPNAME.DEADQ)

* If nonpersistent messages then discard before sending to system queue (not currently used)
*PERSIST(MQPER_NOT_PERSISTENT) ACTION(DISCARD)

* default action if no rules match and retries met
ACTION (FWD) FWDQ(SYSTEM.DEAD.LETTER.QUEUE) HEADER(YES)

EOF
fi
echo "STEP8: done !!!"
#
#####
#
echo "STEP9: ### Starting the customization from QMGR based on MQSeries Stardards ###"
runmqsc $QM <<-EOF
* Put here the information with new parameters for handle of SDLQ
ALTER QMGR MAXMSGL(104857600)

ALTER QMGR DEADQ(${SDLQ})

DEFINE QL(${SDLQ})                                                +
       DESCR('Local Queue to handle DLQ')                         +
       MAXDEPTH(9999999)
*
ALTER  QL(${SDLQ})                                                +
       TRIGGER                                                    +
       TRIGTYPE(FIRST)                                            +
       PROCESS(${DEADP})                                          +
       INITQ(${SDIQ})
*
DEFINE PROCESS(${DEADP})                                          +
       DESCR('Triggermon for DLQ Handler')                        +
       APPLICID('${RUNDLQ} ${SDLQ} ${QM} < ${DEADRULE}')         +
       ENVRDATA('&')
*
ALTER  QL(SYSTEM.ADMIN.STATISTICS.QUEUE)                          +
       MAXDEPTH(500000)
*
ALTER  QL(SYSTEM.ADMIN.ACCOUNTING.QUEUE)                          +
       MAXDEPTH(500000)
*
EOF
echo "STEP9: done !!!"
#
#####
#
echo .
echo "### Queue Manager $QM created ###"
echo "### Finishing ###"
#} > crtqmgr.out
echo "$0 - Done !!!"
echo "$0 - All tasks will be available on the file crtqmgr.out"
echo "."
if [ "${HACMD}" = "YES" ] ; then
   echo "$0 - This qmgr was setting up to run on High Availability"
   echo "$0 - Please, copy the command bellow the run on another node"
   echo "$0 NOTE: The /MQHA file system must be mounted before to run"
   echo "..."
   dspmqinf -o command $QM
   dspmqinf -o command $QM > $MQNOD
   echo ".."
fi
} | tee -i crtqmgr.out
#
# EOF - crtqmgr.sh


