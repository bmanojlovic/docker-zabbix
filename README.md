zabbix-i-c
======

# What
Zabbix in a container based on openSUSE distribution.

Installation by default will use postgresql as database, so please provide database parameters for postgresql

# Why
I prefer openSUSE as OS so that is "Why" and of course postgresql

# How

```
docker pull bmanojlovic/zabbix-i-c
docker run -d \
    --restart=always \
    --name zabbix-i-c \
    -p 2080:80 \
    -p 20443:443 \
    -p 10050:10050 \
    -p 10051:10051 \
    -e ZABBIX_DB_HOST=localhost \
    -e ZABBIX_DB_USER=zabbix \
    -e ZABBIX_DB_NAME=zabbix \
    -e ZABBIX_DB_PASS=jibberish_goes_here \
    bmanojlovic/zabbix-i-c
```
For purpose of easier access to configuration and to be able to backup them easier two volumes are created on docker run

To get location of them you can use this trick which should output something like bellow
``` 
docker inspect --format='{{range .Mounts}}{{.Destination}}={{.Source}}{{print "\n"}}{{end}}' zabbix-i-c
/etc/zabbix=/var/lib/docker/volumes/314...139/_data
/usr/share/zabbix/conf=/var/lib/docker/volumes/2cf...05c/_data
```

## to check if everything is ok with configuration

```
docker exec -ti zabbix-i-c egrep -rv '(^#|^$)' /etc/zabbix/zabbix-server.conf
docker exec -ti zabbix-i-c cat /usr/share/zabbix/conf/zabbix.conf.php
```
## to see logs of zabbix and apache services (add `logs -f` for continuous monitoring )

```
docker logs zabbix-i-c
```

# Who

repository owner? :)

# Any questions problems?

please use issue reporting and i will answer