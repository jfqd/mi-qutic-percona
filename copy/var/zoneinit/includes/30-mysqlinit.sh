mv /opt/local/etc/my.cnf{,.bak}
mv /var/zoneinit/tmp/my.cnf /opt/local/etc/my.cnf
rm -rf /var/zoneinit/tmp

if [ ! -d /var/mysql/mysql ]; then
  cd /var/mysql && mysql_install_db 1>/dev/null 2>&1 || true
fi

# create folder for certs
mkdir /var/mysql/certs
chown mysql:mysql /var/mysql/certs
chmod 0700 /var/mysql/certs
