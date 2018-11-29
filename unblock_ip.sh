#!/usr/bin/env bash
# ============================================================
# Written by Alex S Grebenschikov
# for www.plugins-da.net
# unblock_ip.sh script to run Directadmin`s BFM with CSF/LFD
# Based on directadmin`s official version
# Version: 0.1.5 Thu Nov 29 15:25:57 +07 2018
# Last modified: Thu Nov 29 15:25:57 +07 2018
# ============================================================
# Version: 0.1.5 Thu Nov 29 15:25:57 +07 2018
# Changes: Corrected shebang for better compatibilities
# ============================================================
# Version: 0.1.4 Mon Apr 25 13:55:35 NOVT 2016
# Changes: Added removal of banned IP from temporary blocks
# ============================================================
# Version: 0.1.3 Thu Jan 14 19:20:39 NOVT 2016
# Changes: grep replaced with egrep to support old format of
#          /root/block_ips.txt, when IP comes w/out date.
#          A switcher CSF_GREP_API_CALL added 
# ============================================================
# Version: 0.1.2 Sun May 17 16:37:58 NOVT 2015
# ============================================================
# Version: 0.1.1 Tue Dec  9 23:22:37 NOVT 2014
#
CSF_GREP_API_CALL=0; # SET TO 1 TO USE API CALL TO CSF
                     # WHEN SEARCHING AN IP AGAINST BLOCKLIST
                     # SET TO 0 (ZERO) TO GREP A FILE DIRECTLY
                     # 1 - MORE ACCURATE, USE csf
                     # 0 - MORE SPEEDY, USE egrep
# ============================================================

CSF="/usr/sbin/csf";
CDF="/etc/csf/csf.deny";
CDTF="/var/lib/csf/csf.tempban";

BF=/root/blocked_ips.txt;
EF=/root/exempt_ips.txt;
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

##
## IN SOME CASES THE IP MIGHT BE MISSING IN CSF/LFD
## AND STILL EXIST IN /root/blocked_ips.txt
## SO WE SHOULD REMOVE IT FROM THE FILE 
## TO LET DIRECTADMIN DO ITS JOB
## AND AVOID LOOPS
##
c=`egrep "^${ip}(=|$)" ${BF} -c`
if [ "${c}" -gt "0" ];
then
    echo "[OK] The IP ${ip} was found as blocked in ${BF}<br>";
    cat ${BF} | egrep -v "^${ip}(=|$)" > ${BF}.temp
    mv ${BF}.temp ${BF}
    UNBLOCKED=1;
fi;

if [ "${CSF_GREP_API_CALL}" == "0" ];
then
    # MORE SPEEDY
    egrep "^${ip}($|\s)" ${CDF} -q || grep "|${ip}|" ${CDTF} -q;
    RVAL=$?;
    c=0;
else
    # MORE ACCURATE
    c=`${CSF} -g "${ip}" | egrep 'csf.deny|Temporary Blocks' -c`;
fi;
if [ "${c}" -gt "0" ] || [ "${RVAL}" == "0" ];
then
    echo "[OK] The IP ${ip} was found as blocked in CSF/LFD (API_CALL=${CSF_GREP_API_CALL})<br>";
    ${CSF} -dr ${ip} >/dev/null 2>&1; # Permament block list
    ${CSF} -tr ${ip} >/dev/null 2>&1; # Temporary block list
    UNBLOCKED=1;
fi;

if [ "${UNBLOCKED}" -gt "0" ];
then
    echo "[OK] The IP ${ip} was unblocked";
    exit 0;
else
    echo "[WARNING] The IP ${ip} is not blocked. Terminating...";
    exit 3;
fi;

exit;
