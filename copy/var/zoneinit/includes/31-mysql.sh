# Get internal and external ip of vm
IP_INTERNAL=$(mdata-get sdc:nics | /usr/bin/json -ag ip -c 'this.nic_tag === "admin"' 2>/dev/null);

log "getting mysql_password"
if [[ $(mdata-get mysql_pass &>/dev/null)$? -eq "0" ]]; then
  MYSQL_PW=$(mdata-get mysql_pass 2>/dev/null);
else
  MYSQL_PW=$(od -An -N8 -x /dev/random | head -1 | tr -d ' ');
fi

# Get mysql_server_id from metadata if exists
log "getting mysql_server_id"
if [[ $(mdata-get mysql_server_id &>/dev/null)$? -eq "0" ]]; then
  MYSQL_SERVER_ID=$(mdata-get mysql_server_id 2>/dev/null);
  gsed -i "s/server-id = 1/server-id = ${MYSQL_SERVER_ID}/" /opt/local/etc/my.cnf
fi

# Generate svccfg happy password for quickbackup-percona
# (one without special characters)
log "getting qb_pw"
QB_PW=${QB_PW:-$(mdata-get mysql_qb_pass 2>/dev/null)} || \
QB_PW=$(od -An -N8 -x /dev/random | head -1 | sed 's/^[ \t]*//' | tr -d ' ');
QB_US=qb-$(zonename | awk -F\- '{ print $1 }');

# Workaround for using DHCP so IP_INTERNAL or IP_EXTERNAL is empty
if [[ -z "${IP_INTERNAL}" ]]; then
  IP_INTERNAL="127.0.0.1"
fi

# Default query to lock down access and clean up
MYSQL_INIT="GRANT ALL on *.* to 'root'@'localhost' with grant option;
CREATE USER IF NOT EXISTS '${QB_US}'@'localhost' IDENTIFIED BY '${QB_PW}';
GRANT LOCK TABLES,SELECT,RELOAD,SUPER,PROCESS,REPLICATION CLIENT on *.* to '${QB_US}'@'localhost';
FLUSH PRIVILEGES;
FLUSH TABLES;"

# MySQL my.cnf tuning
# copied from: https://github.com/joyent/mi-percona/blob/master/copy/var/zoneinit/includes/31-mysql.sh
MEMCAP=$(kstat -c zone_memory_cap -s physcap -p | cut -f2 | awk '{ printf "%d", $1/1024/1024 }');

# innodb_buffer_pool_size
INNODB_BUFFER_POOL_SIZE=$(echo -e "scale=0; ${MEMCAP}/2"|bc)M

# back_log
BACK_LOG=64
[[ ${MEMCAP} -gt 8000 ]] && BACK_LOG=128

# max_connections
[[ ${MEMCAP} -lt 1000 ]] && MAX_CONNECTIONS=200
[[ ${MEMCAP} -gt 1000 ]] && MAX_CONNECTIONS=500
[[ ${MEMCAP} -gt 2000 ]] && MAX_CONNECTIONS=1000
#[[ ${MEMCAP} -gt 3000 ]] && MAX_CONNECTIONS=2000
#[[ ${MEMCAP} -gt 5000 ]] && MAX_CONNECTIONS=5000

# thread_cache_size
THREAD_CACHE_SIZE=$((${MAX_CONNECTIONS}/2))
[[ ${THREAD_CACHE_SIZE} -gt 1000 ]] && THREAD_CACHE_SIZE=1000

log "tuning MySQL configuration"
gsed -i \
        -e "s/bind-address = 127.0.0.1/bind-address = ${IP_INTERNAL}/" \
        -e "s/back_log = 64/back_log = ${BACK_LOG}/" \
        -e "s/thread_cache_size = 1000/thread_cache_size = ${THREAD_CACHE_SIZE}/" \
        -e "s/max_connections = 1000/max_connections = ${MAX_CONNECTIONS}/" \
        -e "s/net_buffer_length = 2K/net_buffer_length = 16384/" \
        -e "s/innodb_buffer_pool_size = [0-9]*M/innodb_buffer_pool_size = ${INNODB_BUFFER_POOL_SIZE}/" \
        /opt/local/etc/my.cnf

log "configuring Quickbackup"
svccfg -s quickbackup-percona setprop quickbackup/username = astring: ${QB_US}
svccfg -s quickbackup-percona setprop quickbackup/password = astring: ${QB_PW}
svcadm refresh quickbackup-percona
touch /var/log/mysql/quickbackup-percona.log

log "shutting down an existing instance of MySQL"
if [[ "$(svcs -Ho state svc:/pkgsrc/percona:default)" == "online" ]]; then
  svcadm disable -t svc:/pkgsrc/percona:default
  sleep 2
fi

# log "setup MySQL instance"
mv /var/mysql/certs/ /var/mysql-certs/
chmod 0750 /var/mysql/
( cd /var/mysql && rm -rf $(ls -Ab) )
/opt/local/sbin/mysqld --initialize-insecure --user=mysql --basedir=/opt/local --datadir=/var/mysql --skip-name-resolve
rm /var/mysql/*.pem
mv /var/mysql-certs/ /var/mysql/certs/

log "starting the new MySQL instance"
svcadm enable -t svc:/pkgsrc/percona:default

log "waiting for the socket to show up"
COUNT="0";
while [[ ! -e /tmp/mysql.sock ]]; do
  sleep 1
  ((COUNT=COUNT+1))
  if [[ $COUNT -eq 60 ]]; then
    log "ERROR Could not talk to MySQL after 60 seconds"
    ERROR=yes
    break 1
  fi
done
[[ -n "${ERROR}" ]] && exit 31
log "(it took ${COUNT} seconds to start properly)"

sleep 1

[[ "$(svcs -Ho state svc:/pkgsrc/percona:default)" == "online" ]] || \
  ( log "ERROR MySQL SMF not reporting as 'online'" && exit 31 )

log "import zoneinfo to mysql db"
mysql_tzinfo_to_sql /usr/share/lib/zoneinfo | mysql mysql || true

log "running the access lockdown SQL query"
if [[ $(mysql -uroot --skip-password -e "select version()" &>/dev/null)$? -eq "0" ]]; then
  mysql -u root --skip-password -e "${MYSQL_INIT}" >/dev/null || ( log "ERROR MySQL query failed to execute." && exit 31; )
else
  log "Can't login with no password set, continuing.";
fi

# Create username and password file for root user
log "create my.cnf for root user"
cat > /root/.my.cnf <<EOF
[client]
host = localhost
user = root
password = ${MYSQL_PW}
EOF
chmod 0400 /root/.my.cnf

# fix munin-plugin config
sed -i -e "s/env.mysqlpassword/env.mysqlpassword ${MYSQL_PW}/" /opt/local/etc/munin/plugin-conf.d/mysql
chmod 0400 /opt/local/etc/munin/plugin-conf.d/mysql
