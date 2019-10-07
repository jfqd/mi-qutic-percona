# Changelog

## 20181018.0

* use trunk base
* move file-format to barracuda
* increase redis maxmemory
* prevent usage of risky commands for security reasons
* only preserve the last 30 backups
* use certificate if provided

## 17.4.4

* add logadm config
* ruby24 with redis gem

## 17.4.3

* add spiped services
* only allow spiped access for memcached and redis

## 17.4.2

* build on latest qutic base image
* add missing nrpe-config
* fix gsed call
* add more munin plugins
* resort mysqlmunin.sh

## 17.4.1

* include redis and memcached

## 17.4.0

* qutify image
* based on the excellent work of skylime, original repo: https://github.com/skylime/mi-core-percona
