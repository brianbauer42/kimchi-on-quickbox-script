#!/bin/bash
# 1. git clone https://github.com/bbauer-io/kimchi-on-quickbox-script
# 2. cd kimchi-on-quickbox-script
# 3. run sudo sh kimchi-on-quickbox.sh

# Check for root priviliges
[ "$(whoami)" != "root" ] && exec sudo -- "$0" "$@"

# Install Virtualization packages
apt-get install -y qemu qemu-kvm libvirt-bin wget

# Download the wok, ginger-base, and kimchi .deb packages
wget http://kimchi-project.github.io/wok/downloads/latest/wok.noarch.deb &&\
wget http://kimchi-project.github.io/gingerbase/downloads/latest/ginger-base.noarch.deb &&\
wget http://kimchi-project.github.io/kimchi/downloads/latest/kimchi.noarch.deb

# Disable apache2 so that it won't  cause problems with the nginx install.
# (nginx will want to fight apache2 for port 80 until we tell it not to.
systemctl stop apache2

# Installing nginx right away so we can edit it's config and bring apache back online..
apt-get install -y -q nginx

# Disable nginx default page so that it won't try to bind to port 80.
rm -f /etc/nginx/sites-available/default
systemctl restart nginx

# Apache and nginx can coexist now.
systemctl start apache2

# Recommended package mdadm wants to interact on install, but I don't want to.
export DEBIAN_FRONTEND=noninteractive

# Install Wok, then Ginger-base, then Kimchi, and missing dependencies in between.
dpkg -i wok.noarch.deb
apt-get install -y -q -f
dpkg -i ginger-base.noarch.deb
apt-get install -y -q -f
dpkg -i kimchi.noarch.deb
apt-get install -y -q -f

# Add custom link with image to Quickbox dashboard.
sed -i "40i\$kimchiURL\ =\ \"https:\/\/\"\ .\ \$_SERVER[\'HTTP_HOST\']\ .\ \":8001\/\";" /srv/rutorrent/home/custom/custom.menu.php
echo '<li><a class="grayscale" href="<?php echo "$kimchiURL"; ?>" target="_blank"><img src="img/brands/kimchi.png" class="brand-ico"> <span>Kimchi</span></a></li>' >> /srv/rutorrent/home/custom/custom.menu.php
mv kimchi.png /srv/rutorrent/home/img/brands/kimchi.png
chown www-data:www-data /srv/rutorrent/home/img/brands/kimchi.png

# Fix the "unsupported configuration: Memory cgroup is not available on this host" error which prevents VMs from booting:
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory swapaccount=1"/' /etc/default/grub
update-grub

# Web interface may be present, but VMs will not work until a reboot due to the error fixed above.
# Manually reboot when you're ready or uncomment the following line to make it automatic!
echo "Setup complete. A reboot is required before it will work."
# reboot now
