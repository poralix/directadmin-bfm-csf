#!/bin/sh
# ============================================================
# Written by Alex S Grebenschikov
# for www.plugins-da.net
# ============================================================
# Version: 0.1.0 Mon Aug  8 18:42:39 +07 2016
# Last modified: Mon Aug  8 18:42:39 +07 2016
# ============================================================

CSF="/usr/sbin/csf";
CDF="/etc/csf/csf.deny";

if [ ! -x "${CSF}" ] || [ ! -f "${CDF}" ];
then
    echo "[ERROR] CSF/LFD was not found on your server! Terminating...";
    exit 1;
fi;

cd /usr/local/directadmin/scripts/custom/;
[ -f "block_ip.sh" ] && cp -f block_ip.sh block_ip.sh.bak;
[ -f "unblock_ip.sh" ] && cp -f unblock_ip.sh unblock_ip.sh.bak;
[ -f "show_blocked_ips.sh" ] && cp -f show_blocked_ips.sh show_blocked_ips.sh.bak;
[ -f "brute_force_notice_ip.sh" ] && cp -f brute_force_notice_ip.sh brute_force_notice_ip.sh.bak;

wget -q -O block_ip.sh http://files.plugins-da.net/dl/csf_block_ip.sh.txt;
wget -q -O unblock_ip.sh http://files.plugins-da.net/dl/csf_unblock_ip.sh.txt;
wget -q -O show_blocked_ips.sh http://files.plugins-da.net/dl/csf_show_blocked_ips.sh.txt;
wget -q -O brute_force_notice_ip.sh http://files.directadmin.com/services/all/brute_force_notice_ip.sh
chmod 700 brute_force_notice_ip.sh block_ip.sh show_blocked_ips.sh unblock_ip.sh;

[ -f "/root/blocked_ips.txt" ] || touch /root/blocked_ips.txt;
[ -f "/root/exempt_ips.txt" ] || touch /root/exempt_ips.txt;

echo "[OK] Scripts installed!";
echo "[OK] Make sure that Brute-force monitor is enabled in Directadmin";

exit 0;
