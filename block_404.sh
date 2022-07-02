#!/usr/bin/env bash
# =====================================================================================
#  DirectAdmin-BFM-CSF:
#    Version: 0.1.5
#    Last updated: Sat Jul  2 20:55:32 +07 2022
# =====================================================================================
#  Written by Alex S Grebenschikov for www.plugins-da.net, www.poralix.com
#  block_404.sh script to run with BFM (Directadmin) or CSF/LFD
# =====================================================================================
#  The script reads Apache/Nginx/LiteSpeed/OpenLiteSpeed domains logs, detects IPs
#  from which a vulnerability scanning is being done and blocks such IPs either with
#  BFM (DirectAdmin) or with CSF/LFD
# =====================================================================================
#  Should be run with cron:
#  */5 * * * * root /usr/local/directadmin/scripts/custom/block_404.sh >/dev/null 2>&1
# =====================================================================================
#  File version: 0.2.1 Sat Jul  2 15:52:48 +07 2022
#  Last modified: Sat Jul  2 15:52:48 +07 2022
# =====================================================================================

TMP_FILE=$(mktemp /home/tmp/block_404.XXXXXXXXXX);
BLOCK_IP_AFTER_404_HITS=1000;
BLOCK_SCRIPT="/usr/local/directadmin/scripts/custom/block_ip.sh";
CSF_SCRIPT="/sbin/csf";

for DOMAIN in $(awk -F: '{print $1}' /etc/virtual/domainowners | sort | uniq); 
do
    LOG_FILE="/var/log/httpd/domains/${DOMAIN}.log";
    test -f "${LOG_FILE}" || LOG_FILE="/var/log/nginx/domains/${DOMAIN}.log";
    test -f "${LOG_FILE}" && awk '{if ($9 == 404) print $1" "$9}' "${LOG_FILE}" >> "${TMP_FILE}";
done;

if [ -f "${TMP_FILE}" ];
then
    if [ "${DEBUG}" == "1" ];
    then
        grep -v -f /usr/local/directadmin/data/admin/ip.list "${TMP_FILE}" | sort | uniq -c | sort -rn;
    else
        for ROW in $(grep -v -f /usr/local/directadmin/data/admin/ip.list "${TMP_FILE}" | sort | uniq -c | sort -rn | awk '{if ($1 > '${BLOCK_IP_AFTER_404_HITS}') print $2"="$1}'); #'
        do
            ip=$(echo "${ROW}" | cut -d= -f1);
            count=$(echo "${ROW}" | cut -d= -f2);
            value="${ip}";
            data="webserver1=${count}&first_entry=$(date +%s)&last_entry=$(date +%s)&last_notify=$(date +%s)";
            ttl=$(/usr/local/directadmin/directadmin c | grep -m1 "unblock_brute_ip_time=" | cut -d= -f2);
            ttl=$((ttl*3*60));

            if [ -x "${BLOCK_SCRIPT}" ];
            then
                echo "[NOTICE] Using DirectAdmin to blacklist IP ${ip} for vulnerability scanning with ${count} requests with HTTP/404";
                export ip;
                export count;
                export value;
                export data;
                ${BLOCK_SCRIPT};
                echo;
            elif [ -x "${CSF_SCRIPT}" ];
            then
                echo "[NOTICE] Using CSF to blacklist IP ${ip} for vulnerability scanning with ${count} requests with HTTP/404";
                port=80;
                ${CSF_SCRIPT} --tempdeny "${ip}" "${ttl}" -p "${port}" -d inout "Blocked port ${port} for vulnerability scanning";
                port=443;
                ${CSF_SCRIPT} --tempdeny "${ip}" "${ttl}" -p "${port}" -d inout "Blocked port ${port} for vulnerability scanning";
            else
                echo "[NOTICE] Manuall action is required to blacklist IP ${ip} for vulnerability scanning with ${count} requests with HTTP/404";
            fi;
        done;
    fi;
    rm -f "${TMP_FILE}";
fi;

exit 0;
