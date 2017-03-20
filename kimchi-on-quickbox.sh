#!/bin/bash

# Install Virtualization packages
apt-get install -y qemu qemu-kvm libvirt-bin

# Download the wok, ginger-base, and kimchi .deb packages
wget http://kimchi-project.github.io/wok/downloads/latest/wok.noarch.deb &&\
wget http://kimchi-project.github.io/gingerbase/downloads/latest/ginger-base.noarch.deb &&\
wget http://kimchi-project.github.io/kimchi/downloads/latest/kimchi.noarch.deb

# Disable apache2 so that or it will cause problems with the nginx install
# nginx will want to fight apache2 for port 80 until we tell it not to.
systemctl stop apache2

# Installing nginx right away so we can edit it's config and bring apache back online..
apt-get install -y -q nginx

# Disable nginx default page so that it won't try to bind to port 80
rm -f /etc/nginx/sites-available/default
systemctl restart nginx

# Apache and nginx can coexist now
systemctl start apache2

# Install Wok, then Ginger-base, then Kimchi, and missing dependencies in between (including nginx)
dpkg -i wok.noarch.deb
apt-get install -y -q -f
dpkg -i ginger-base.noarch.deb
apt-get install -y -q -f
dpkg -i kimchi.noarch.deb
apt-get install -y -q -f

# Add custom link to Quickbox dashboard
sed -i "40i\$kimchiURL\ =\ \"https:\/\/\"\ .\ \$_SERVER[\'HTTP_HOST\']\ .\ \":8001\/\";" /srv/rutorrent/home/custom/custom.menu.php
echo '<li><a class="grayscale" href="<?php echo "$kimchiURL"; ?>" target="_blank"><img src="img/brands/kimchi.png" class="brand-ico"> <span>Kimchi</span></a></li>' >> /srv/rutorrent/home/custom/custom.menu.php
#wget -0 /srv/rutorrent/home/img/brands/kimchi.png http://kimchi.png.url

# Fix the "unsupported configuration: Memory cgroup is not available on this host" error which prevents VMs from booting:
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory swapaccount=1"/' /etc/default/grub
update-grub

# Web interface may be present, but VMs will not work until a reboot due to the error fixed above.
# Manually reboot when you're ready or uncomment the following line to make it automatic!
echo "now reboot and everything should be groovy!"
