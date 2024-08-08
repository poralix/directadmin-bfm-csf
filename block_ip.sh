#!/usr/bin/env bash
# =====================================================================================
#  DirectAdmin-BFM-CSF:
#    Version: 0.1.5
#    Last updated: Sat Jul  2 20:55:32 +07 2022
# =====================================================================================
#  Written by Alex S Grebenschikov for www.plugins-da.net, www.poralix.com
#  block_ip.sh script to run BFM (Directadmin) with CSF/LFD
# =====================================================================================
# Script Version: 0.2.2 Thu Aug  8 11:45:35 +07 2024
# Changes: Added date of a block to comments for CSF
# =====================================================================================
# Version: 0.2.1 Sat Jul  2 18:37:47 +07 2022
# Last modified: Sat Jul  2 18:37:47 +07 2022
# =====================================================================================
# Version: 0.2.1 Sat Jul  2 18:37:47 +07 2022
# Changes: Extended cases for HTTP/HTTPs webservices blocks
# =====================================================================================
# Version: 0.2.0 Wed Oct 23 16:19:54 +07 2019
# Changes: Multiports are now supported. DirectAdmin sends a list of
#          attacked services in a single line
# =====================================================================================
# Version: 0.1.9 Tue May 28 02:20:21 +07 2019
# Changes: Support for an external config file added, 
#          Normalized logging
# =====================================================================================
# Version: 0.1.8 Thu Nov 29 15:25:57 +07 2018
# Changes: Corrected shebang for better compatibilities
# =====================================================================================
# Version: 0.1.7 Mon Aug  8 18:06:23 +07 2016
# Bugfix:  A support for TTL=0 (in Directadmin) added
# =====================================================================================
# Version: 0.1.5 Mon Apr 25 11:30:01 NOVT 2016
# Changes: A switcher USE_PORT_SELECTED_BLOCK added
# =====================================================================================
# Version: 0.1.4 Thu Jan 14 19:20:39 NOVT 2016
# Changes: grep replaced with egrep to support old format of
#          /root/block_ips.txt, when IP comes w/out date.
#          A switcher CSF_GREP_API_CALL added
# =====================================================================================
#
USE_PORT_SELECTED_BLOCK=1;  # SET TO 1 OR 0
                            # 1: TO BAN ACCESS ONLY TO A PORT WHICH
                            #    WAS BRUTEFORCED
                            # 0: TO BLOCK ACCESS TO ALL PORTS
                            #
                            # NOTICE: MANUAL TRIGGER FROM DIRECTADMIN
                            # WILL STILL BLOCK ACCESS TO ALL PORTS
                            # FOR AN IP

CSF_GREP_API_CALL=0;        # SET TO 1 TO USE API CALL TO CSF
                            # WHEN SEARCHING AN IP AGAINST BLOCKLIST
                            # SET TO 0 (ZERO) TO GREP A FILE DIRECTLY
                            # 1 - MORE ACCURATE, USE csf
                            # 0 - MORE SPEEDY, USE egrep
DEBUG=0;
# ============================================================

FTP_PORTS="20 21";
SSH_PORTS="22";
WEB_PORTS="80 443";
EXIM_PORTS="25 465 587";
DOVECOT_PORTS="110 143 993 995";
DIRECTADMIN_PORTS="2222";

CONF_FILE="/root/directadmin-bfm-csf.conf";

if [ -f "${CONF_FILE}" ]; then
    source "${CONF_FILE}";
fi;

BF="/root/blocked_ips.txt";
EF="/root/exempt_ips.txt";
SLF="/usr/local/directadmin/data/admin/brute_skip.list";
CAF="/etc/csf/csf.allow";
CATF="/var/lib/csf/csf.tempallow";
CDF="/etc/csf/csf.deny";
CDTF="/var/lib/csf/csf.tempban";

CSF="/usr/sbin/csf";

de()
{
    [ "${DEBUG}" == "1" ] && echo "$1";
}

detect_attacked_service()
{
    local loc_block_ports="";
    # FTP
    c=$(echo "${data}" | grep -c "ftpd[0-9]=");
    if [ "${c}" -gt "0" ]; then
        loc_block_ports="${loc_block_ports} ${FTP_PORTS}";
    fi;

    # SSH
    c=$(echo "${data}" | grep -c "ssh[0-9]=");
    if [ "${c}" -gt "0" ]; then
        loc_block_ports="${loc_block_ports} ${SSH_PORTS}";
    fi;

    # WEB
    c=$(echo "${data}" | grep -Ec "(wordpress|webserver|mod_security)[0-9]="); #"
    if [ "${c}" -gt "0" ]; then
        loc_block_ports="${loc_block_ports} ${WEB_PORTS}";
    fi;

    # EXIM
    c=$(echo "${data}" | grep -c "exim[0-9]=");
    if [ "${c}" -gt "0" ]; then
        loc_block_ports="${loc_block_ports} ${EXIM_PORTS}";
    fi;

    # DOVECOT
    c=$(echo "${data}" | grep -c "dovecot[0-9]=");
    if [ "${c}" -gt "0" ]; then
        loc_block_ports="${loc_block_ports} ${DOVECOT_PORTS}";
    fi;

    # DIRECTADMIN
    c=$(echo "${data}" | grep -c "directadmin[0-9]=");
    if [ "${c}" -gt "0" ]; then
        loc_block_ports="${loc_block_ports} ${DIRECTADMIN_PORTS}";
    fi;

    if [ -z "${loc_block_ports}" ]; then
        echo "0";
        return 1;
    else
        echo "${loc_block_ports}";
        return 0;
    fi;
}

if [ -z "${ip}" ];
then
    echo "[ERROR] We've got no IP to block! Terminating...";
    exit 1;
fi;

if [ ! -x "${CSF}" ] || [ ! -f "${CDF}" ];
then
    echo "[ERROR] CSF/LFD was not found on your server! Terminating...";
    exit 2;
fi;

[ -e "${BF}" ] || touch "${BF}";
[ -e "${EF}" ] || touch "${EF}";


# SHOULD WE NEED TO BLOCK ACCESS ONLY TO SELECTED PORTS
# WE NEED FIRST DETECT WHAT SERVICE IS UNDER A BRUTEFORCE ATTACK
if [ "${USE_PORT_SELECTED_BLOCK}" == "1" ];
then
    TTL=$(/usr/local/directadmin/directadmin c | grep -m1 "unblock_brute_ip_time=" | cut -d= -f2);

    if [ "${TTL}" == "0" ];
    then
        TTL="1825d";       # If TTL=0 then IP should be blocked forever
                           # here we set TTL to 5 years = 365d * 5
    else
        TTL=$((TTL*3*60)); # It is Directadmin which unblocks IP, so we need to have enough long TTL
                           # so that Directadmin have a chance to unblock it
                           # Additionaly convert minutes to seconds *60
    fi;
    BLOCK_PORTS="";

    # We should have data= from Directadmin in order to detect 
    # what service was bruteforced
    # If there was no data= passed to the script we set USE_PORT_SELECTED_BLOCK to 0
    if [ -z "${data}" ];
    then
        USE_PORT_SELECTED_BLOCK=0;
    else
        BLOCK_PORTS=$(detect_attacked_service);
        if [ "$?" -ne 0 ] || [ "${BLOCK_PORTS}" == "0" ];
        then
            USE_PORT_SELECTED_BLOCK=0;
            BLOCK_PORTS="";
        fi;
    fi;
fi;


# Is the IP whitelisted by Directadmin?
c=$(grep -c "^${ip}\$" "${EF}");
if [ "${c}" -gt 0 ];
then
    echo "[WARNING] The IP ${ip} is whitelisted in ${EF}. Not going to block it...";
    exit 3;
fi;


# Is the IP added into a skiplist by Directadmin?
if [ -f "${SLF}" ];
then
    c=$(grep -c "^${ip}=" "${SLF}");
    if [ "${c}" -gt 0 ];
    then
        echo "[WARNING] The IP ${ip} is whitelisted in ${SLF}. Not going to block it...";
        exit 4;
    fi;
fi;


# Is the IP whitelisted permamently by CSF?
c=$(egrep -c "(^|=)${ip}($|\s|#)" "${CAF}");
if [ "${c}" -gt 0 ];
then
    echo "[WARNING] The IP ${ip} is whitelisted in ${CAF}. Not going to block it...";
    exit 5;
fi;

# Is the IP whitelisted temporary by CSF?
c=$(grep -c "|${ip}|" "${CATF}");
if [ "${c}" -gt 0 ];
then
    echo "[WARNING] The IP ${ip} is whitelisted in ${CATF}. Not going to block it...";
    exit 5;
fi;


# If the IP is already blocked in CSF/LFD
# We do not want the IP to be managed by BFM in this case
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

if [ "${c}" -gt 0 ] || [ "${RVAL}" == "0" ];
then
    echo -n "[WARNING] The IP ${ip} is already blocked: ";
    if [ "${CSF_GREP_API_CALL}" == "0" ];
    then
        details=`egrep "^${ip}($|\s)" "${CDF}" | cut -d\# -f2 | head -1 | xargs`;
        [ -z "${details}" ] && details=$(grep "|${ip}|" "${CDTF}" | cut -d\| -f6 | head -1 | xargs);
        echo -n "${details}";
    else
        ${CSF} -g "${ip}" | egrep 'csf.deny|Temporary Blocks' | cut -d\# -f2 | head -1;
    fi;
    exit 6;
fi;


TF=$(mktemp);
if [ -z "${BLOCK_PORTS}" ];
then
    ${CSF} -d "${ip}" "Blocked with Directadmin BFM on $(date -R)" > "${TF}" 2>&1;
else
    for port in ${BLOCK_PORTS};
    do
        ${CSF} --tempdeny "${ip}" "${TTL}" -p "${port}" -d inout "Blocked port ${port} with Directadmin BFM on $(date -R)" >> "${TF}" 2>&1;
    done;
fi;

c=$(grep -c " DENY_IP_LIMIT " "${TF}");
if [ "${c}" -gt 0 ];
then
    ip2=$(grep --after=1 " DENY_IP_LIMIT " "${TF}" | tail -1 | awk '{print $1}');
    echo -n "[WARNING] DENY_IP_LIMIT was met in CSF. ";
    if [ ! -z "${ip2}" ];
    then
        grep -v "^${ip2}=" "${BF}" > "${BF}.temp";
        mv "${BF}.temp" "${BF}";
        echo -n "The IP ${ip2} was removed from ban list.";
    fi;
fi;


if [ "${CSF_GREP_API_CALL}" == "0" ];
then
    egrep -q "^${ip}($|\s)" "${CDF}" || grep -q "|${ip}|" "${CDTF}";
    RVAL=$?;
    c=0;
else
    c=$(${CSF} -g "${ip}" | egrep -c 'csf.deny|Temporary Blocks');
fi;
if [ "${c}" -gt 0 ] || [ "${RVAL}" == "0" ];
then
    echo -n "[OK] The IP ${ip} was blocked with CSF, BLOCK_PORTS=${BLOCK_PORTS}";
    echo "${ip}=dateblocked=$(date +%s)" >> "${BF}";
fi;

[ ! -f "${TF}" ] || rm -f "${TF}";

exit 0;
