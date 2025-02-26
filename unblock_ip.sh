#!/usr/bin/env bash
# =====================================================================================
#  DirectAdmin-BFM-CSF:
#    Version: 0.1.7
#    Last updated: Thu Feb 27 00:54:42 +07 2025
# =====================================================================================
#  Written by Alex S Grebenschikov for www.plugins-da.net, www.poralix.com
#  unblock_ip.sh script to run Directadmin`s BFM with CSF/LFD
#  Based on directadmin`s official version
# =====================================================================================
#
CSF_GREP_API_CALL=0;     # SET TO 1 TO USE API CALL TO CSF
                         # WHEN SEARCHING AN IP AGAINST BLOCKLIST
                         # SET TO 0 (ZERO) TO GREP A FILE DIRECTLY
                         # 1 - MORE ACCURATE, USE csf
                         # 0 - MORE SPEEDY, USE grep

CSF_USE_CLUSTER_BLOCK=1; # SET TO 1 TO USE API CALL TO CSF WITH CLUSTER MODE
                         # SET TO 0 (ZERO) TO USE REGULAR CSF API CALLS

DEBUG=0;
# =====================================================================================

CONF_FILE="/root/directadmin-bfm-csf.conf";

if [ -f "${CONF_FILE}" ]; then
    source "${CONF_FILE}";
fi;

CSF="/usr/sbin/csf";
CDF="/etc/csf/csf.deny";
CDTF="/var/lib/csf/csf.tempban";
CCF="/etc/csf/csf.conf";

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
c=`grep -Ec "^${ip}(=|$)" "${BF}"`;
if [ "${c}" -gt "0" ];
then
    de "[DEBUG] The IP ${ip} was found in ${BF}";
    grep -Ev "^${ip}(=|$)" "${BF}" > "${BF}.temp";
    mv "${BF}.temp" "${BF}";
    UNBLOCKED=1;
fi;

if [ "${CSF_GREP_API_CALL}" == "0" ];
then
    # MORE SPEEDY
    grep -Eq "^${ip}($|\s)" "${CDF}" || grep -q "|${ip}|" "${CDTF}";
    RVAL=$?;
    c=0;
else
    # MORE ACCURATE
    c=$(${CSF} -g "${ip}" | grep -Ec 'csf.deny|Temporary Blocks');
fi;
if [ "${c}" -gt "0" ] || [ "${RVAL}" == "0" ];
then
    # CHECK WHETHER THE CLUSTER MODE IS ENABLED
    if [ "${CSF_USE_CLUSTER_BLOCK}" == "1" ];
    then
        # IS IT ENABLED IN CSF/LFD?
        CSF_USE_CLUSTER_BLOCK=$(grep "^CLUSTER_CONFIG" "${CCF}" | cut -d= -f2 | xargs echo);
    fi;

    # CHECK THE CLUSTER MODE THE SECOND TIME
    if [ "${CSF_USE_CLUSTER_BLOCK}" == "1" ];
    then
        de "[DEBUG] Unblocking the IP ${ip} in CSF/LFD Cluster (API_CALL=${CSF_GREP_API_CALL})";
        ${CSF} --crm "${ip}" >/dev/null 2>&1; # Unblock an IP and remove from each remote /etc/csf/csf.deny and temporary list
    else
        de "[DEBUG] Unblocking the IP ${ip} in CSF/LFD (API_CALL=${CSF_GREP_API_CALL})";
        ${CSF} -dr "${ip}" >/dev/null 2>&1; # Unblock an IP and remove from /etc/csf/csf.deny
        ${CSF} -trd "${ip}" >/dev/null 2>&1; # Remove an IP from the temporary IP ban list only
    fi;
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
