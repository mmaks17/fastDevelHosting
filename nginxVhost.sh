#!/bin/bash

echo "Enter Site Name / user" 
read S
echo $S
echo "Enter Domain" 
read D
echo $D
useradd -G ftp $S  
usermod -a -G  nginx $S
echo "$S:$S" | chpasswd
mkdir -p /home/$S/www
mkdir -p /home/$S/www/public
chown -R nginx:nginx /home/$S/www
chmod -R 775 /home/$S/www
echo "CREATE USER '$S'@'%' IDENTIFIED BY '$S';" |  mysql -uroot -pPASSWORD
echo "GRANT USAGE ON *.* TO '$S'@'%' IDENTIFIED BY '$S' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"|  mysql -uroot -pPASSWORD
echo "CREATE DATABASE IF NOT EXISTS $S;"  |  mysql -uroot -pPASSWORD
echo "GRANT ALL PRIVILEGES ON $S.* TO '$S'@'%';"  |  mysql -uroot -pPASSWORD


cat <<EOT>>  /etc/nginx/sites-enabled/$S.$D.conf

server {
 	listen  80;
	server_name $S.$D;
	root  /home/$S/www/public/;
	index index.php;
	access_log  /home/$S/www/access.log;
	error_log  /home/$S/www/error.log;

	location / {

     try_files $uri $uri/ /index.php?$query_string;

    }
    location ~ \.php$ {
          try_files $uri =404;
          fastcgi_pass unix:/run/php-fpm/www.sock;
          fastcgi_index index.php;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          include fastcgi_params;
    }




    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
        root  /usr/share/nginx/html;
    }
}

EOT


nginx -s reload


