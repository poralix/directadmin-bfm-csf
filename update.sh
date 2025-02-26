#!/usr/bin/env bash
# =====================================================================================
#  DirectAdmin-BFM-CSF:
#    Version: 0.1.6
#    Last updated: Thu Aug  8 17:00:49 +07 2024
# =====================================================================================
#  Written by Alex S Grebenschikov for www.plugins-da.net, www.poralix.com
# =====================================================================================
# File Version: 0.1.6 $ Sat Jul  2 20:55:32 +07 2022
# Last modified: Sat Jul  2 20:55:32 +07 2022
# =====================================================================================
# Version: 0.1.4 Thu Nov 29 15:25:57 +07 2018
# Changes: Corrected shebang for better compatibilities
# =====================================================================================
# Versions: 
#           - 0.1.3 Tue Jun 12 13:38:56 +07 2018
#           - 0.1.2 Wed Apr 11 12:40:40 +07 2018
#           - 0.1.1 Sat Oct  7 12:23:43 +07 2017
# =====================================================================================

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
