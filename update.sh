#!/usr/bin/env bash
# =====================================================================================
#  DirectAdmin-BFM-CSF:
#    Version: 0.1.7
#    Last updated: Thu Feb 27 00:54:42 +07 2025
# =====================================================================================
#  Written by Alex S Grebenschikov for www.plugins-da.net, www.poralix.com
# =====================================================================================
#
CSF="/usr/sbin/csf";
DIR="/usr/local/directadmin/scripts/custom/";

do_update()
{
    echo "[OK] Updating in ${DIR}${1}";
    if [ -f "${1}" ]; then
        cp -f "${1}" "${1}.bak"
        chmod 600 "${1}.bak";
    fi;
    wget --no-check-certificate -q -O "${1}" "${2}";
    chmod 700 "${1}";
    chown diradmin:diradmin "${1}";
}

die()
{
    echo "$1" echo ""; exit "$2";
}

[ -x "${CSF}" ] || die "[ERROR] CSF/LFD not found! You should install it first!" 1;
[ -x "/usr/local/directadmin/directadmin" ] || die "[ERROR] Directadmin not found! You should install it first!" 2;
cd "${DIR}" || die "[ERROR] Could not change directory to ${DIR}" 1;

do_update "block_404.sh" "https://files.plugins-da.net/dl/block_404.sh.txt";
do_update "block_ip.sh" "https://files.plugins-da.net/dl/csf_block_ip.sh.txt";
do_update "unblock_ip.sh" "https://files.plugins-da.net/dl/csf_unblock_ip.sh.txt";
do_update "show_blocked_ips.sh" "https://files.plugins-da.net/dl/csf_show_blocked_ips.sh.txt";
do_update "brute_force_notice_ip.sh" "https://files.plugins-da.net/dl/brute_force_notice_ip.sh.txt";

[ -f "/root/blocked_ips.txt" ] || touch /root/blocked_ips.txt;
[ -f "/root/exempt_ips.txt" ] || touch /root/exempt_ips.txt;

echo "[OK] Scripts Updated!";
echo "";
echo "Upgrade complete!";
echo "";
exit 0;
