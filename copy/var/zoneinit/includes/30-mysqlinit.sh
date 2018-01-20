if [ ! -d /var/mysql/mysql ]; then
	cd /var/mysql && mysql_install_db 1>/dev/null 2>&1 || true
fi
