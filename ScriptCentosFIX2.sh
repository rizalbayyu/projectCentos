#!/bin/bash

echo "=========================================================================="
echo "===============================Preparing=================================="
echo "=========================================================================="
sudo -i
yum -y install wget expect unzip yum-utils vim
# Install and enable Remi repository
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
# Using PHP 7.3. PHP 7.3 get from Remi repository. Enable service with config manager that provided in yum-utils
yum-config-manager --enable remi-php73

cd /tmp/config
unzip config.zip
rm config.zip
cd

echo "=========================================================================="
echo "===========================Install LAM Stack=============================="
echo "=========================================================================="
sleep 2s

# Install LAM Stack
yum -y install httpd mariadb mariadb-server php php-common php-mysql php-gd php-xml php-mbstring php-mcrypt

echo "- add firewall rule for maridb"
firewall-cmd --permanent --add-service=mysql
firewall-cmd --reload
# Start mariaDB 
systemctl start mariadb
# enanble mariaDB start automatically on boot
systemctl enable mariadb

echo "- add firewall rule for HTTP"
firewall-cmd --permanent --add-service=http
firewall-cmd --reload
# Enable and start automatically apache on boot
systemctl start httpd
systemctl enable httpd

echo "=========================================================================="
echo "===========================MySQL Secure Installation=============================="
echo "=========================================================================="
sleep 2s

# Install Secure MariaDB
# Menggunakan spawn, send, expect agar program berjalan secara otomatis
# Spawn=Memanggil atau memulai Script atau Program
# expect=Menunggu output dari program
# send=Memberi balasan untuk program
SECURE_MYSQL=$(expect -c "
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"\r\"
expect \"Change the root password?\"
send \"y\r\"
expect \"New password\"
send \"123\r\"
expect \"Re-enter new password\"
send \"123\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof");
echo "$SECURE_MYSQL"

echo "=========================================================================="
echo "===========================Database=============================="
echo "=========================================================================="
sleep 2s

#Create Database
mysql -u root -p123 mysql -e "\
CREATE DATABASE webdiver;
CREATE USER 'rizal'@'localhost' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON wordpress.* TO 'rizal'@'localhost';
FLUSH PRIVILEGES;\
"
echo "=========================================================================="
echo "===========================Install Wordpress=============================="
echo "=========================================================================="
# Preparing Installation WordPress
mkdir /opt/wordpress
cd /opt/wordpress/ && wget http://wordpress.org/latest.tar.gz
# extract Archieve to web directory
tar -xvzf latest.tar.gz
# Copy wordpress
cp -rf wordpress/* /var/www/html/
#move config from tmp config
cp /tmp/config/wp-config.php /var/www/html/
# Give permission user to apache
chown -R apache /var/www/html/
#change access permissions
chmod -R 755 /var/www/html/
#relationship between selinux
chcon -R --reference /var/www/ /var/www/html/

# go to httpd.conf to edit/add virtualhost
cat <<EOT>> /etc/httpd/conf/httpd.conf
<VirtualHost *:80>
  ServerAdmin rizal@ganteng.com
  DocumentRoot /var/www/html/
  ServerName ganteng.com
  ServerAlias www.ganteng.comID
  ErrorLog /var/log/httpd/ganteng-error-log
  CustomLog /var/log/httpd/ganteng-acces-log common
</VirtualHost>
EOT
systemctl restart httpd