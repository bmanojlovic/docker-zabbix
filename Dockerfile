FROM opensuse:42.1

MAINTAINER Boris Manojlovic "boris@steki.net"


ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV TERM xterm
RUN zypper -n --gpg-auto-import-keys ref \
    && zypper ar http://download.opensuse.org/repositories/server:/monitoring:/zabbix/openSUSE_Leap_42.1/ zabbix \
    && zypper ar http://download.opensuse.org/repositories/devel:/languages:/python/openSUSE_Leap_42.1/ d_l_p \
    && zypper -n --gpg-auto-import-keys  ref \
    && sed -ri 's/^(rpm.install.excludedocs.=).*/\1 no/g' /etc/zypp/zypp.conf \
    && zypper -n install --no-recommends zabbix30-server-postgresql zabbix30-agent supervisor sudo php5-gettext \
                      zabbix30-phpfrontend apache2-mod_php5 php5-xmlwriter php5-xmlreader php5-pgsql \
    && zypper clean -a

# Required to be able to access ZABBIX that Allow from all means ALL :)
RUN a2enflag ZABBIX && a2enmod access_compat && a2enmod php5 \
    && sed -ri 's@Allow from 10.0.0.0/8@Allow from all@g' /etc/apache2/conf.d/zabbix.conf \
    && sed -ri 's/^(post_max_size.=).*/\1 16M/g' /etc/php5/apache2/php.ini \
    && sed -ri 's/^(max_execution_time.=).*/\1 300/g' /etc/php5/apache2/php.ini \
    && sed -ri 's/^(max_input_time.=).*/\1 300/g' /etc/php5/apache2/php.ini


# Fix supervisord configuration to work correctly as root (zabbix will use zabbix user as default)
RUN sed -ri 's/;user=chrism(\s+;.*root.*)/user=root\1/g' /etc/supervisord.conf \
    && sed -ri 's@^pidfile.*( ; .*)@pidfile=/run/supervisord.pid \1@g' /etc/supervisord.conf \
    && sed -ri 's@(serverurl=unix://).*( ;.*)@\1/run/supervisord.sock\2@g' /etc/supervisord.conf \
    && sed -ri 's@^(file=).*( ;.*)@\1/run/supervisord.sock\2@g' /etc/supervisord.conf

# Supervisord setup
RUN sh -c "(echo '[program:apache2]'; echo 'command=/usr/sbin/start_apache2 -DSYSTEMD -DFOREGROUND -k start';echo 'redirect_stderr=true') >> /etc/supervisord.d/apache2.conf"
RUN sh -c "(echo '[program:zabbix-server]'; echo 'command=/usr/sbin/zabbix-server -f';echo 'user=zabbixs') >> /etc/supervisord.d/zabbix-server.conf"
RUN sh -c "(echo '[program:zabbix-agentd]'; echo 'command=/usr/sbin/zabbix-agentd -f';echo 'user=zabbix') >> /etc/supervisord.d/zabbix-agentd.conf"

EXPOSE 80 10050:10051
VOLUME ["/etc/zabbix", "/usr/share/zabbix/conf"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf", "-n"]
