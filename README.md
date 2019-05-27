# directadmin-bfm-csf

A set of scripts to let Brute Force Monitor in DirectAdmin to block IPs using CSF/LFD

A common method of gaining access over a server is to use a technique called a brute force attack, or dictionary attack. What the attacker will do, is use a script to try and login to an account with every possible password combination. This tends to require tens of thousands of login attempts, but eventually, the right combination will be found, and they can login normally.

To prevent this, we can use a brute force login detection system in DirectAdmin, so called BFM (Brute Force Monitor).

# Release details

- Version: 0.1.4
- Last updated: Tue May 28 03:19:25 +07 2019

# Installation guide

```
cd ~
wget -O csf-bfm-install.sh https://raw.githubusercontent.com/poralix/directadmin-bfm-csf/master/install.sh
chmod 700 csf-bfm-install.sh
./csf-bfm-install.sh
```

Full Instructions can be found here: https://help.poralix.com/articles/how-to-block-ips-with-csf-directadmin-bfm

# Upgrade guide

```
cd ~
wget -O csf-bfm-update.sh https://raw.githubusercontent.com/poralix/directadmin-bfm-csf/master/update.sh
chmod 700 csf-bfm-update.sh
./csf-bfm-update.sh
```

# Change defaults

Whenever you need to change the defaults:


```
USE_PORT_SELECTED_BLOCK="1";
CSF_GREP_API_CALL="0";
DEBUG="0";
FTP_PORTS="20 21";
SSH_PORTS="22";
WEB_PORTS="80 443";
EXIM_PORTS="25 465 587";
DOVECOT_PORTS="110 143 993 995";
DIRECTADMIN_PORTS="2222";
```

you can do it in `/root/directadmin-bfm-csf.conf`. Add the lines which you want to change with your values.

For example if you run DirectAdmin on a custom port, and you should add the line (change 1345 with your value):


```
DIRECTADMIN_PORTS="1345";
```

If you want to block access for an offensive IP to all ports on your server, then add:

```
USE_PORT_SELECTED_BLOCK="0";
```

in `/root/directadmin-bfm-csf.conf`. Create the file if it's missing.
