#!/bin/ksh

#disable backup script
#author - aqmal zaki
#edit 9-8-2019

function check-pbrun ()
{
if id == root
PBRUN=""
DEVNULL=""
else
PBRUN = pbrun
DEVNULL= '2>/dev/null'
function show-menu ()
{ 
echo " ========= Schedule Enable/Disable Backup ========== "
echo "E: Enable Backup."
echo "D: Disable Backup."
echo "Q: Press 'Q' to quit."
}

function list-cells ()
{
#i limit this script to localhost only now
echo " Current cell," `cat /etc/opt/omni/client/cell_server`
}

function get-info-spec ()
{
echo " Please Enter spec name eg : gvu0081_TIAP"
read SPECNAME
SPECLIST=`$PBRUN /sbin/ls -d /etc/opt/omni/server/schedules/*DEVNULL $|grep -i $SPECNAME ; \
$PBRUN /sbin/ls -d /etc/opt/omni/server/barschedules/oracle8/* $DEVNULL | grep -i $SPECNAME ;\
$PBRUN /sbin/ls -d /etc/opt/omni/server/barschedules/mssql/* $DEVNULL |grep -i $SPECNAME"`
#echo "$SPECLIST" |awk '{print $7,$8}'
}

function get-info-disableday ()
{
echo "Type in Days to Disable. p = permanent"
read DAYS2DISABLE
echo "Disable Spec above for $DAYS2DISABLE days? (Y/N):
read REP1
if [ $REP1 = N ]
then
echo "=========== exitting ============="
fi
)

function get-info-reason ()
{
echo "Reason"
read $Reason
}

function test-date ()
{
if [ $DAYS2DISABLE = "p" ] ;then disable-p
elseif [ $DAYS2DISABLE = ^[0-9]+$ ] ; then disable-d
else echo "unrecognized. exitting"
exit
fi
}

function date-format ()
{
DDATE=`date "+%d%m%Y"`
}

function disable-date-format ()


function enable ()
{
echo "enable all spec above? (Y/N)"
read REP2
if ![ $REP2 = Y ]
echo "====exitting======"
exit
fi
for i in `echo "$SPECLIST"
do 
$PBRUN cat $i $DEVNULL |grep -v disable |grep -v starting > /db_unload/aqmal/disable_backup/tmp/$i_$DDATE $DEVNULL
$PBRUN cp /db_unload/aqmal/disable_backup/tmp/$i_$DDATE $i $DEVNULL
}

function disable-p ()
{
echo "disable all spec above permanently? (Y/N)"
read REP2
if ![ $REP2 = Y ]
echo "====exitting======"
exit
fi
for i in `echo "$SPECLIST"
do 
$PBRUN cat $i $DEVNULL |grep -v disable |grep -v starting > /db_unload/aqmal/disable_backup/tmp/$i_$DDATE
perl -p -e 'print "-disabled\n" if $. == 1' /db_unload/aqmal/disable_backup/tmp/$i_$DDATE_2
$PBRUN cp /db_unload/aqmal/disable_backup/tmp/$i_$DDATE_2 $i $DEVNULL
}

function disable-d ()
{
echo "disable all spec above for $DAYS2DISABLE days? (Y/N)"
read REP2
if ![ $REP2 = Y ]
echo "====exitting======"
exit
fi
for i in `echo "$SPECLIST"
do 
$PBRUN cat $i $DEVNULL |grep -v disable |grep -v starting > /db_unload/aqmal/disable_backup/tmp/$i_$DDATE
perl -p -e 's/-every/-starting $NEWDATE \n-every/g' /db_unload/aqmal/disable_backup/tmp/$i_$DDATE_2
$PBRUN cp /db_unload/aqmal/disable_backup/tmp/$i_$DDATE_2 $i $DEVNULL
}