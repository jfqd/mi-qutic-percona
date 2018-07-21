gsed -i \
     -e "s/memcached -d -u/memcached -d -U 0 -u/" \
     -e "s/value='64'/value='1024'/" \
     /opt/local/lib/svc/manifest/memcached.xml

svccfg import /opt/local/lib/svc/manifest/memcached.xml
svcadm enable svc:/pkgsrc/memcached:default
