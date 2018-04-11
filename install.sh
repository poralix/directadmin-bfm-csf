#!/bin/sh
# ============================================================
# Written by Alex S Grebenschikov
# for www.plugins-da.net
# ============================================================
# Version: 0.1.2 Wed Apr 11 12:40:40 +07 2018
# Last modified: Wed Apr 11 12:40:40 +07 2018
# ============================================================
# Version: 0.1.1 Sat Oct  7 12:23:43 +07 2017
# ============================================================

CSF="/usr/sbin/csf";
CDF="/etc/csf/csf.deny";
DIR="/usr/local/directadmin/scripts/custom/";

if [ ! -x "${CSF}" ] || [ ! -f "${CDF}" ];
then
    echo "[NOTICE] CSF/LFD was not found on your server! Installing...";

    cd /usr/local/src;
    wget --no-check-certificate -q https://download.configserver.com/csf.tgz -O csf.tgz;
    tar -xzf csf.tgz;
    cd /usr/local/src/csf;
    sh ./install.sh;

    if [ -x "${CSF}" ]; then
        echo "[NOTICE] CSF/LFD was installed! You need to configure /etc/csf/csf.conf";
    else
        echo "[NOTICE] CSF/LFD failed to install! Terminating...";
        exit 1;
    fi;
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

csf_reconfig()
{
    echo "[OK] Disabling alerts in CSF/LFD about temporary blocks of an IP brute-forcing server";
    perl -pi -e 's#^LF_EMAIL_ALERT = "1"#LF_EMAIL_ALERT = "0"#' /etc/csf/csf.conf;
    echo "[OK] Disabling alerts in CSF/LFD about temporary blocks of an IP attacking Apache";
    perl -pi -e 's#^LT_EMAIL_ALERT = "1"#LT_EMAIL_ALERT = "0"#' /etc/csf/csf.conf;
    echo "[OK] Disabling alerts in CSF/LFD about permament blocks of an IP";
    perl -pi -e 's#^LF_PERMBLOCK_ALERT = "1"#LF_PERMBLOCK_ALERT = "0"#' /etc/csf/csf.conf;

}

do_install "block_ip.sh" "http://files.plugins-da.net/dl/csf_block_ip.sh.txt";
do_install "unblock_ip.sh" "http://files.plugins-da.net/dl/csf_unblock_ip.sh.txt";
do_install "show_blocked_ips.sh" "http://files.plugins-da.net/dl/csf_show_blocked_ips.sh.txt";
do_install "brute_force_notice_ip.sh" "http://files.directadmin.com/services/all/brute_force_notice_ip.sh";

[ -f "/root/blocked_ips.txt" ] || touch /root/blocked_ips.txt;
[ -f "/root/exempt_ips.txt" ] || touch /root/exempt_ips.txt;

csf_reconfig;

echo "[OK] Scripts installed!";
echo "[OK] Make sure that Brute-force monitor is enabled in Directadmin with bruteforce=1";
echo "[NOTICE] Current value: `/usr/local/directadmin/directadmin c | grep ^bruteforce=`";
echo "";
echo "[INFO] Suggested settings:
    bruteforce=1
    brute_force_log_scanner=1
    brute_force_scan_apache_logs=2
    brute_force_time_limit=1200
    clear_brute_log_time=48
    hide_brute_force_notifications=1
    ip_brutecount=30
    unblock_brute_ip_time=2880
    user_brutecount=30
";
echo "You can change them in Directadmin interface at admin level or in directadmin.conf";

service lfd restart;
exit 0;
