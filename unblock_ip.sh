#!/usr/bin/env bash
# =====================================================================================
#  DirectAdmin-BFM-CSF:
#    Version: 0.1.6
#    Last updated: Thu Aug  8 17:00:49 +07 2024
# =====================================================================================
#  Written by Alex S Grebenschikov for www.plugins-da.net, www.poralix.com
#  unblock_ip.sh script to run Directadmin`s BFM with CSF/LFD
#  Based on directadmin`s official version
# =====================================================================================
# Script Version: 0.1.7 Thu Aug  8 11:45:35 +07 2024
# Changes: Remove an IP from the temporary IP ban list only (excluding allow list)
# =====================================================================================
# Version: 0.1.6 Tue May 28 01:30:02 +07 2019
# Changes: Support for an external config and debug added
# =====================================================================================
# Version: 0.1.5 Thu Nov 29 15:25:57 +07 2018
# Changes: Corrected shebang for better compatibilities
# =====================================================================================
# Version: 0.1.4 Mon Apr 25 13:55:35 NOVT 2016
# Changes: Added removal of banned IP from temporary blocks
# =====================================================================================
# Version: 0.1.3 Thu Jan 14 19:20:39 NOVT 2016
# Changes: grep replaced with egrep to support old format of
#          /root/block_ips.txt, when IP comes w/out date.
#          A switcher CSF_GREP_API_CALL added 
# =====================================================================================
# Version: 0.1.2 Sun May 17 16:37:58 NOVT 2015
# =====================================================================================
# Version: 0.1.1 Tue Dec  9 23:22:37 NOVT 2014
#
CSF_GREP_API_CALL=0; # SET TO 1 TO USE API CALL TO CSF
                     # WHEN SEARCHING AN IP AGAINST BLOCKLIST
                     # SET TO 0 (ZERO) TO GREP A FILE DIRECTLY
                     # 1 - MORE ACCURATE, USE csf
                     # 0 - MORE SPEEDY, USE egrep
DEBUG=0;
# =====================================================================================

CONF_FILE="/root/directadmin-bfm-csf.conf";

if [ -f "${CONF_FILE}" ]; then
    source "${CONF_FILE}";
fi;

CSF="/usr/sbin/csf";
CDF="/etc/csf/csf.deny";
CDTF="/var/lib/csf/csf.tempban";

BF="/root/blocked_ips.txt";
UNBLOCKED=0;

if [ -z "${ip}" ];
then
    echo "[ERROR] We've got no IP to unblock! Terminating...";
    exit 1;
fi;

if [ ! -x "${CSF}" ] || [ ! -f "${CDF}" ];
then
    echo "[ERROR] CSF/LFD was not found on your server! Terminating...";
    exit 2;
fi;

de()
{
    [ "${DEBUG}" == "1" ] && echo "$1";
}

##
## IN SOME CASES THE IP MIGHT BE MISSING IN CSF/LFD
## AND STILL EXIST IN /root/blocked_ips.txt
## SO WE SHOULD REMOVE IT FROM THE FILE 
## TO LET DIRECTADMIN DO ITS JOB
## AND AVOID LOOPS
##
c=`egrep -c "^${ip}(=|$)" "${BF}"`;
if [ "${c}" -gt "0" ];
then
    de "[DEBUG] The IP ${ip} was found in ${BF}";
    egrep -v "^${ip}(=|$)" "${BF}" > "${BF}.temp";
    mv "${BF}.temp" "${BF}";
    UNBLOCKED=1;
fi;

if [ "${CSF_GREP_API_CALL}" == "0" ];
then
    # MORE SPEEDY
    egrep -q "^${ip}($|\s)" "${CDF}" || grep -q "|${ip}|" "${CDTF}";
    RVAL=$?;
    c=0;
else
    # MORE ACCURATE
    c=$(${CSF} -g "${ip}" | egrep -c 'csf.deny|Temporary Blocks');
fi;
if [ "${c}" -gt "0" ] || [ "${RVAL}" == "0" ];
then
    de "[DEBUG] The IP ${ip} was found as blocked in CSF/LFD (API_CALL=${CSF_GREP_API_CALL})";
    ${CSF} -dr "${ip}" >/dev/null 2>&1; # Unblock an IP and remove from /etc/csf/csf.deny
    ${CSF} -trd "${ip}" >/dev/null 2>&1; # Remove an IP from the temporary IP ban list only
    UNBLOCKED=1;
fi;

if [ "${UNBLOCKED}" -gt "0" ];
then
    echo -n "[OK] The IP ${ip} was unblocked";
    exit 0;
else
    echo -n "[WARNING] The IP ${ip} is not blocked. Terminating...";
    exit 3;
fi;

exit;
