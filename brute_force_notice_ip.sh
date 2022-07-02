#!/bin/sh

#give your server a name for easy idenfication
SERVER=`hostname -s`

#where you want the email to be sent to
#EMAIL=your@address.com

#echo "IP $value has been blocked for making $count failed login attempts
#
#$data
#
#`dig -x $value`" | mail -s "$SERVER:  blocked $value for $count failed attempts" $EMAIL

SCRIPT=/usr/local/directadmin/scripts/custom/block_ip.sh
ip=$value $SCRIPT
exit $?;
