#!/bin/sh -x

if [ -n "${ZABBIX_DB_HOST}" ]; then
	sed -ri 's/.*(DBHost=).*/\1'${ZABBIX_DB_HOST}'/g' /etc/zabbix/zabbix-server.conf
fi

if [ -n "${ZABBIX_DB_USER}" ]; then
	sed -ri 's/^(DBUser=).*/\1'${ZABBIX_DB_USER}'/g' /etc/zabbix/zabbix-server.conf
fi
if [ -n "${ZABBIX_DB_NAME}" ]; then
	sed -ri 's/^(DBName=).*/\1'${ZABBIX_DB_NAME}'/g' /etc/zabbix/zabbix-server.conf
fi

if [ -n "${ZABBIX_DB_PASS}" ]; then
	sed -ri 's/^(DBPassword=).*/\1'${ZABBIX_DB_PASS}'/g' /etc/zabbix/zabbix-server.conf
fi
# server part of configuration
sed -ri 's/.*(LogType=).*/\1console/g' /etc/zabbix/zabbix-server.conf
sed -ri 's/^(LogFile=.*)/#\1/g' /etc/zabbix/zabbix-server.conf
# frontend part of configuration
sed -ri "s/(.*TYPE.[]].*=).*/\1 'POSTGRESQL';/g" /usr/share/zabbix/conf/zabbix.conf.php
sed -ri "s/(.*SERVER.[]].*=).*/\1 '${ZABBIX_DB_HOST}';/g" /usr/share/zabbix/conf/zabbix.conf.php
sed -ri "s/(.*PORT.[]].*=).*/\1 '5432';/g" /usr/share/zabbix/conf/zabbix.conf.php
sed -ri "s/(.*DATABASE.[]].*=).*/\1 '${ZABBIX_DB_NAME}';/g" /usr/share/zabbix/conf/zabbix.conf.php
sed -ri "s/(.*USER.[]].*=).*/\1 '${ZABBIX_DB_USER}';/g" /usr/share/zabbix/conf/zabbix.conf.php
sed -ri "s/(.*PASSWORD.[]].*=).*/\1 '${ZABBIX_DB_PASS}';/g" /usr/share/zabbix/conf/zabbix.conf.php
sed -ri "s/(.*ZBX_SERVER_NAME.*=).*/\1 'zabbix-i-c';/g" /usr/share/zabbix/conf/zabbix.conf.php

# exec replaces running script so supervisord will be able to get control signals
exec /usr/bin/supervisord -c /etc/supervisord.conf -n
