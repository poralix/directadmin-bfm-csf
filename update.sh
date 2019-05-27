#!/usr/bin/env bash
# ============================================================
# Written by Alex S Grebenschikov for www.plugins-da.net
# ============================================================
# Version: 0.1.5 Tue May 28 02:55:59 +07 2019
# Last modified: Tue May 28 02:55:59 +07 2019
# ============================================================
# Version: 0.1.4 Thu Nov 29 15:25:57 +07 2018
# Changes: Corrected shebang for better compatibilities
# ============================================================
# Versions: 
#           - 0.1.3 Tue Jun 12 13:38:56 +07 2018
#           - 0.1.2 Wed Apr 11 12:40:40 +07 2018
#           - 0.1.1 Sat Oct  7 12:23:43 +07 2017
# ============================================================

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

[ -x "${CSF}" ] || csf_install;

[ -x "/usr/local/directadmin/directadmin" ] || die "[ERROR] Directadmin not found! You should install it first!" 1;
cd "${DIR}" || die "[ERROR] Could not change directory to ${DIR}" 1;

do_update "block_ip.sh" "http://files.plugins-da.net/dl/csf_block_ip.sh.txt";
do_update "unblock_ip.sh" "http://files.plugins-da.net/dl/csf_unblock_ip.sh.txt";
do_update "show_blocked_ips.sh" "http://files.plugins-da.net/dl/csf_show_blocked_ips.sh.txt";
do_update "brute_force_notice_ip.sh" "http://files.directadmin.com/services/all/brute_force_notice_ip.sh";

[ -f "/root/blocked_ips.txt" ] || touch /root/blocked_ips.txt;
[ -f "/root/exempt_ips.txt" ] || touch /root/exempt_ips.txt;

echo "[OK] Scripts Updated!";
echo "";
echo "Upgrade complete!";
echo "";
exit 0;
