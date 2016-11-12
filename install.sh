#!/bin/sh
# ============================================================
# Written by Alex S Grebenschikov
# for www.plugins-da.net
# ============================================================
# Version: 0.1.0 Mon Aug  8 18:42:39 +07 2016
# Last modified:                  Nov 12 2016
# ============================================================

CSF="/usr/sbin/csf";
CDF="/etc/csf/csf.deny";
DIR="/usr/local/directadmin/scripts/custom/";

if [ ! -x "${CSF}" ] || [ ! -f "${CDF}" ];
then
    echo "[ERROR] CSF/LFD was not found on your server! Terminating...";
    exit 1;
fi;

cd ${DIR} || exit 1;

do_install()
{
    echo "[OK] Installing ${1} into ${DIR}";
    [ -f "${1}" ] && cp -f ${1} ${1}.bak && chmod 600 ${1}.bak;
    wget --no-check-certificate -q -O ${1} ${2};
    chmod 700 ${1};
    chown diradmin:diradmin ${1};
}

do_install "block_ip.sh" "http://files.plugins-da.net/dl/csf_block_ip.sh.txt";
do_install "unblock_ip.sh" "http://files.plugins-da.net/dl/csf_unblock_ip.sh.txt";
do_install "show_blocked_ips.sh" "http://files.plugins-da.net/dl/csf_show_blocked_ips.sh.txt";
do_install "brute_force_notice_ip.sh" "http://files.directadmin.com/services/all/brute_force_notice_ip.sh";

[ -f "/root/blocked_ips.txt" ] || touch /root/blocked_ips.txt;
[ -f "/root/exempt_ips.txt" ] || touch /root/exempt_ips.txt;

echo "[OK] Scripts installed!";
echo "[OK] Make sure that Brute-force monitor is enabled in Directadmin with bruteforce=1";
echo "[NOTICE] Current value: `/usr/local/directadmin/directadmin c | grep ^bruteforce=`";

exit 0;
