mv /opt/local/etc/my.cnf{,.bak}
mv /var/zoneinit/tmp/my.cnf /opt/local/etc/my.cnf
rm -rf /var/zoneinit/tmp

if [ ! -d /var/mysql/mysql ]; then
  cd /var/mysql && mysql_install_db 1>/dev/null 2>&1 || true
fi
