FROM opensuse/leap:15.0

ENV SUSE_VERSION=15.0
ENV VERSION=3.0
ENV SVERSION=""
ENV PHP_VERSION=7
# dummy version string to force dockerhub to rebuild image
ENV ZABBIX_VERSION=3.0.20


LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.vendor="Boris Manojlovic" \
      org.label-schema.name="zabbix-i-c" \
      org.label-schema.version="$VERSION" \
      org.label-schema.url="https://github.com/bmanojlovic/zabbix-i-c" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/bmanojlovic/zabbix-i-c.git" \
      org.label-schema.vcs-type="Git"


ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV TERM xterm
# This bulshit from my home repository is to fetch supervisor... nothing else
RUN zypper -n --gpg-auto-import-keys ref \
    && zypper ar http://download.opensuse.org/repositories/server:/monitoring:/zabbix/openSUSE_Leap_${SUSE_VERSION}/ zabbix \
    && zypper ar https://download.opensuse.org/repositories/home:/bmanojlovic/openSUSE_Leap_${SUSE_VERSION}/ home:bmanojlovic \
    && zypper -n --gpg-auto-import-keys  ref \
    && sed -ri 's/^(rpm.install.excludedocs.=).*/\1 no/g' /etc/zypp/zypp.conf \
    && zypper -n install --no-recommends zabbix${SVERSION}-server-postgresql zabbix${SVERSION}-agent \
                      python-setuptools python-supervisor sudo php${PHP_VERSION}-gettext \
                      zabbix${SVERSION}-phpfrontend apache2-mod_php${PHP_VERSION} php${PHP_VERSION}-xmlwriter \
                      php${PHP_VERSION}-xmlreader php${PHP_VERSION}-pgsql \
    && zypper clean -a

# Required to be able to access ZABBIX that Allow from all means ALL :)
RUN a2enflag ZABBIX && a2enmod access_compat && a2enmod php${PHP_VERSION} \
    && sed -ri 's@Allow from 10.0.0.0/8@Allow from all@g' /etc/apache2/conf.d/zabbix.conf \
    && sed -ri 's/^(post_max_size.=).*/\1 16M/g' /etc/php${PHP_VERSION}/apache2/php.ini \
    && sed -ri 's/^(max_execution_time.=).*/\1 300/g' /etc/php${PHP_VERSION}/apache2/php.ini \
    && sed -ri 's/^(max_input_time.=).*/\1 300/g' /etc/php${PHP_VERSION}/apache2/php.ini \
    && cp /usr/share/zabbix/conf/zabbix.conf.php{.example,}


# Fix supervisord configuration to work correctly as root (zabbix will use zabbix user as default)
RUN cp /usr/lib/python2.7/site-packages/supervisor/skel/sample.conf /etc/supervisord.conf \
    && ( echo '[include]'; echo 'files = /etc/supervisord.d/*.conf' ) >> /etc/supervisord.conf \
    && sed -ri 's/;user=chrism(\s+;.*root.*)/user=root\1/g' /etc/supervisord.conf \
    && sed -ri 's@^pidfile.*( ; .*)@pidfile=/run/supervisord.pid \1@g' /etc/supervisord.conf \
    && sed -ri 's@(serverurl=unix://).*( ;.*)@\1/run/supervisord.sock\2@g' /etc/supervisord.conf \
    && sed -ri 's@^(file=).*( ;.*)@\1/run/supervisord.sock\2@g' /etc/supervisord.conf

# Supervisord setup
RUN sh -c "mkdir -p /etc/supervisord.d/"
RUN sh -c "(echo '[program:apache2]'; \
        echo 'command=/usr/sbin/start_apache2 -DSYSTEMD -DFOREGROUND -k start'; \
        echo 'stdout_logfile=/dev/stdout'; \
        echo 'stdout_logfile_maxbytes=0'; \
        echo 'redirect_stderr=true'; \
        ) >> /etc/supervisord.d/apache2.conf"
RUN sh -c "(echo '[program:zabbix-server]'; \
        echo 'command=/usr/sbin/zabbix-server -f'; \
        echo 'user=zabbixs'; \
        echo 'stdout_logfile=/dev/stdout'; \
        echo 'stdout_logfile_maxbytes=0'; \
        echo 'redirect_stderr=true'; \
        ) >> /etc/supervisord.d/zabbix-server.conf"
RUN sh -c "(echo '[program:zabbix-agentd]'; \
        echo 'command=/usr/sbin/zabbix-agentd -f'; \
        echo 'user=zabbix'; \
        echo 'stdout_logfile=/dev/stdout'; \
        echo 'stdout_logfile_maxbytes=0'; \
        echo 'redirect_stderr=true'; \
        ) >> /etc/supervisord.d/zabbix-agentd.conf"
RUN echo '<meta http-equiv="refresh" content="0; url=/zabbix" />' > /srv/www/htdocs/index.html

EXPOSE 80 443 10050 10051
VOLUME ["/etc/zabbix", "/usr/share/zabbix/conf"]

# Initial configuration should/can be done on docker run with -e (environment) flags
COPY zabbix-i-c-wrapper.sh /zabbix-init.sh
RUN chmod 755 /zabbix-init.sh

CMD /zabbix-init.sh
