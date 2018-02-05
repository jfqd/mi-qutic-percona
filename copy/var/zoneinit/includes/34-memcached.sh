# Get internal and external ip of vm
IP_EXTERNAL=$(mdata-get sdc:nics | /usr/bin/json -ag ip -c 'this.nic_tag === "external"' 2>/dev/null);
IP_INTERNAL=$(mdata-get sdc:nics | /usr/bin/json -ag ip -c 'this.nic_tag === "admin"' 2>/dev/null);

# Workaround for using DHCP so IP_INTERNAL or IP_EXTERNAL is empty
if [[ -z "${IP_INTERNAL}" ]] || [[ -z "${IP_EXTERNAL}" ]]; then
  IP_INTERNAL="127.0.0.1"
fi

gsed -i \
     -e "s/memcached -d -u/memcached -d -U 0 -u/" \
     -e "s/value='127.0.0.1'/value='${IP_INTERNAL:-${IP_EXTERNAL}}'/" \
     -e "s/value='64'/value='1024'/" \
     /opt/local/lib/svc/manifest/memcached.xml

svccfg import /opt/local/lib/svc/manifest/memcached.xml
