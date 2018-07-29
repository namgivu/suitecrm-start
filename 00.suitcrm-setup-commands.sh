#!/usr/bin/env bash

#ref. https://www.vultr.com/docs/how-to-install-suitecrm-on-ubuntu-16-04
#os: ubuntu-16-04

#set locale (droplet missed the below two fields)
sudo echo "
export LANGUAGE='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'
" >> ~/.bashrc && source ~/.bashrc

#update os
sudo apt update -y && sudo apt install -y && sudo apt autoremove

#install LAMP
sudo apt install -y apache2 mariadb-server php7.0 php7.0-mysql php7.0-gd php7.0-curl php7.0-imap libapache2-mod-php7.0 php7.0-mcrypt php7.0-xml php7.0-json php7.0-zip

#tweak apache
sudo echo "
; BEGIN suitecrm setting
post_max_size = 64M
upload_max_filesize = 64M
max_input_time = 120
memory_limit = 256M
; END suitecrm setting
" | sudo tee --append /etc/php/7.0/apache2/php.ini #TODO why tee instead of echo >>

#enable the IMAP module with the following command
sudo phpenmod imap

#setup mysql
sudo mysql_secure_installation
  #root/root as login user/pass
  #yes for the rest
alias msql='mysql -u root -proot -e'
s='suitecrm'; db_name=$s; db_user=$s; db_pass=$s
msql "
DROP DATABASE IF EXISTS $db_name;
CREATE DATABASE         $db_name;
CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';
--DROP USER IF EXISTS '$db_user'@'localhost'; --TODO why this is not working?
GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
"

#download & extract suitecrm package
sudo apt install -y unzip
d='/tmp/suitecrm'         ; mkdir -p $d && cd $d && wget -q https://suitecrm.com/files/160/SuiteCRM-7.10.5/284/SuiteCRM-7.10.5.zip
suitecrm='SuiteCRM-7.10.5'; cd $d && unzip "$suitecrm.zip" && sudo mv "$suitecrm" /var/www/html/suitecrm

#configure Apache for suitecrm
site_name='suitecrm'
  host_ip='159.65.2.33'
 app_home="/var/www/html/$site_name"

sudo chown -R www-data:www-data "$app_home"
sudo chmod -R 755               "$app_home"

sudo echo "
<VirtualHost *:80>
    ServerAdmin  nam.vu@unicorn.vn
    DocumentRoot /var/www/html/suitecrm/
    ServerName  $host_ip
    ServerAlias $host_ip

    <Directory /var/www/html/suitecrm/>
        Options FollowSymLinks
        AllowOverride All
    </Directory>

    ErrorLog  /var/log/apache2/suitecrm-error_log
    CustomLog /var/log/apache2/suitecrm-access_log common
</VirtualHost>
" > "/etc/apache2/sites-available/$site_name.conf"

sudo a2ensite "$site_name"
sudo systemctl restart apache2

#utils
sudo echo "
alias reload_apache='sudo systemctl restart apache2'
" >> ~/.bashrc && source ~/.bashrc

#proceed web-install
note="
follow guide on <your-host>/install.php and fix all the error you may encounter
admin login to be admin/admin for user/pass
"

#setup crontab
note="
ref. guide from suitecrm's web-install@after-apache-deployed
In order to run SuiteCRM Schedulers, edit your web server user's crontab file with this command:
sudo crontab -e -u www-data

and add the following line to the crontab file:
*    *    *    *    *     cd /var/www/html/suitecrm; php -f cron.php > /dev/null 2>&1

You should do this only AFTER the installation is concluded.
"
crontab -l > cron_file #write out current crontab to file
echo "*    *    *    *    *     cd /var/www/html/suitecrm; php -f cron.php > /dev/null 2>&1" >> cron_file #echo new cron into cron file
crontab cron_file #install new cron file
rm cron_file #clean up