gsed -i \
     -e "s/# maxmemory <bytes>/maxmemory 1gb/" \
     -e "s/# maxmemory-policy noeviction/# maxmemory-policy allkeys-lfu/" \
     -e "s/# unixsocket \/tmp\/redis.sock/unixsocket \/var\/tmp\/redis.sock/"
     /opt/local/etc/redis.conf

touch /var/log/redis/redis.log
chown redis:redis /var/log/redis/redis.log

svcadm enable svc:/pkgsrc/redis:default
