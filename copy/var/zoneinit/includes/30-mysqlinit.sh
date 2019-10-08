mv /opt/local/etc/my.cnf{,.bak}
mv /var/zoneinit/tmp/my.cnf /opt/local/etc/my.cnf
rm -rf /var/zoneinit/tmp

if [ ! -d /var/mysql/mysql ]; then
  cd /var/mysql && mysql_install_db 1>/dev/null 2>&1 || true
fi

SSL_HOME='/var/mysql/certs'

# create folder for certs
mkdir "${SSL_HOME}"

# Use user certificate if provided
if mdata-get mysql_tls_pem 1>/dev/null 2>&1; then
  (
  umask 0077
  mdata-get mysql_tls_pem > "${SSL_HOME}/mysql.pem"
  # Split files for mysql usage
  openssl pkey -in "${SSL_HOME}/mysql.pem" -out "${SSL_HOME}/mysql.key"
  openssl crl2pkcs7 -nocrl -certfile "${SSL_HOME}/mysql.pem" | \
    openssl pkcs7 -print_certs -out "${SSL_HOME}/mysql.crt"
  )
else
  /opt/qutic/bin/ssl-selfsigned.sh -d ${SSL_HOME} -f mysql
fi

# setup folder and file rights
chmod 0700 "${SSL_HOME}"
chmod 0440 "${SSL_HOME}"/mysql.* || true
chmod 0400 "${SSL_HOME}"/mysql.key || true
chown -R mysql:mysql "${SSL_HOME}/.."
