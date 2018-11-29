# directadmin-bfm-csf
A set of scripts to let Brute Force Monitor in DirectAdmin to block IPs using CSF/LFD

A common method of gaining access over a server is to use a technique called a brute force attack, or dictionary attack. What the attacker will do, is use a script to try and login to an account with every possible password combination. This tends to require tens of thousands of login attempts, but eventually, the right combination will be found, and they can login normally.

To prevent this, we can use a brute force login detection system in DirectAdmin, so called BFM (Brute Force Monitor).

# Installation guide

```
cd ~
wget -O csf-bfm-install.sh https://raw.githubusercontent.com/poralix/directadmin-bfm-csf/master/install.sh
chmod 700 csf-bfm-install.sh
./csf-bfm-install.sh
```

# Upgrade guide

```
cd ~
wget -O csf-bfm-update.sh https://raw.githubusercontent.com/poralix/directadmin-bfm-csf/master/update.sh
chmod 700 csf-bfm-update.sh
./csf-bfm-update.sh
```

Full Instructions can be found here: https://help.poralix.com/articles/how-to-block-ips-with-csf-directadmin-bfm
