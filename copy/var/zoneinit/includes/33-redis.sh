gsed -i \
     -e "s/# maxmemory <bytes>/maxmemory 2gb/" \
     -e "s/# maxmemory-policy noeviction/# maxmemory-policy allkeys-lfu/" \
     -e "s/# unixsocket \/tmp\/redis.sock/unixsocket \/var\/tmp\/redis.sock/"
     /opt/local/etc/redis.conf

cat >> /opt/local/etc/redis.conf << EOF
# prevent usage of these commands for security reasons
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command CONFIG ""
rename-command SWAPDB ""
EOF

touch /var/log/redis/redis.log
chown redis:redis /var/log/redis/redis.log

svcadm enable svc:/pkgsrc/redis:default
