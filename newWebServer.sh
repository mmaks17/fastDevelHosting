#!/bin/bash


setenforce 0

yum install -y net-tools
yum install wget -y
yum install httpd -y
yum --enablerepo="base" -y 
yum install yum-utils -y
yum install yum-config-manager -y
systemctl start httpd.service
systemctl enable httpd.service
yum install mariadb-server mariadb -y
systemctl start mariadb 
systemctl enable mariadb.service


yum install composer
yum install proftpd -y
systemctl enable proftpd
systemctl start proftpd
yum install -y mc




wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm
yum-config-manager --enable remi-php72  
yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-xml -y
yum install composer -y 

composer global require "laravel/installer"

yum install samba samba-client samba-common -y 
cat >  /etc/samba/smb.conf
cat <<EOT >> /etc/samba/smb.conf

[global]
        log file = /var/log/samba/log.%m
        load printers = no
        null passwords = yes
        guest ok = Yes
#       winbind trusted domains only = yes
#       encrypt passwords = yes
#       winbind use default domain = yes
#       passdb backend = tdbsam
        netbios name = server
#       cups options = raw
        server string = S
        workgroup = WORKGROUP
        os level = 20
        auto services = global
        security = user
        map to guest = Bad Password
        max log size = 50


[home]
        path =/home
        browsable =yes
        writable = yes
        guest ok = yes
        read only = no

EOT


cat <<EOT >> /etc/yum.repos.d/webmin.repo
[Webmin]
name=Webmin Distribution Neutral
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1
EOT
wget http://www.webmin.com/jcameron-key.asc
sudo rpm --import jcameron-key.asc

yum install webmin -y
yum install phpmyadmin -y

cat <<EOT>>  /etc/httpd/conf.d/phpMyAdmin.conf

Alias /phpMyAdmin /usr/share/phpMyAdmin
Alias /phpmyadmin /usr/share/phpMyAdmin

<Directory /usr/share/phpMyAdmin/>
   AddDefaultCharset UTF-8

   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
       #Require ip 127.0.0.1
       #Require ip ::1
       Require all granted
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from All
     Allow from 127.0.0.1
     Allow from ::1
   </IfModule>
</Directory>

<Directory /usr/share/phpMyAdmin/setup/>
   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
       Require ip 0.0.0.0
       Require ip ::1
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from None
     Allow from All

   </IfModule>
</Directory>

# These directories do not require access over HTTP - taken from the original
# phpMyAdmin upstream tarball
#
<Directory /usr/share/phpMyAdmin/libraries/>
    Order Deny,Allow
    Deny from All
    Allow from All
</Directory>

<Directory /usr/share/phpMyAdmin/setup/lib/>
    Order Deny,Allow
    Deny from None
    Allow from All
</Directory>

<Directory /usr/share/phpMyAdmin/setup/frames/>
    Order Deny,Allow
    Deny from None
    Allow from All
</Directory>
EOT

apachectl restart




echo "Enter Site Name / user" 
read S
echo $S
echo "Enter Domain" 
read D
echo $D


useradd -G wheel $S  
usermod -a -G  apache $S
echo "$S:$S" | chpasswd


mkdir -p /home/$S/www
mkdir -p /home/$S/www/public
chown -R apache:apache /home/$S/www
chmod -R 775 /home/$S/www



echo "CREATE USER '$S'@'%' IDENTIFIED BY '$S';" |  mysql -uroot -p11
echo "GRANT USAGE ON *.* TO '$S'@'%' IDENTIFIED BY '$S' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"|  mysql -uroot -p11
echo "CREATE DATABASE IF NOT EXISTS $S;"  |  mysql -uroot -p11
echo "GRANT ALL PRIVILEGES ON $S.* TO '$S'@'%';"  |  mysql -uroot -p11


cat <<EOT>>  /etc/httpd/conf.d/$S.$D.conf

<VirtualHost *:80>
DocumentRoot /home/$S/www/public
ErrorLog /home/$S/error_log
CustomLog /home/$S/access_log combined
ServerName $S.$D
<Directory /home/$S/www/public>
allow from all
Options None
Require all granted
Options FollowSymLinks
Options SymLinksIfOwnerMatch
AllowOverride All
</Directory>
</VirtualHost>
EOT


apachectl restart
