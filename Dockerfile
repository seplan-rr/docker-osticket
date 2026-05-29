ARG DISTRO=debian
ARG DISTRO_VARIANT=bookworm
ARG PHP_VERSION=8.2

FROM docker.io/nfrastack/nginx-php-fpm:${PHP_VERSION}-${DISTRO}_${DISTRO_VARIANT}
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ARG OSTICKET_VERSION
ARG OSTICKET_PLUGINS_VERSION

ENV OSTICKET_VERSION=${OSTICKET_VERSION:-"v1.18"} \
    OSTICKET_PLUGINS_VERSION=${OSTICKET_PLUGINS_VERSION:-"develop"} \
    OSTICKET_REPO_URL=${OSTICKET_REPO_URL:-"https://github.com/osticket/osticket"} \
    OSTICKET_PLUGINS_REPO_URL=${OSTICKET_REPO_URL:-"https://github.com/osTicket/osTicket-plugins"} \
    DB_PREFIX=ost_ \
    DB_PORT=3306 \
    CRON_INTERVAL=10 \
    MEMCACHE_PORT=11211 \
    PHP_ENABLE_CURL=TRUE \
    PHP_ENABLE_FILEINFO=TRUE \
    PHP_ENABLE_IMAP=TRUE \
    PHP_ENABLE_LDAP=TRUE \
    PHP_ENABLE_MYSQLI=TRUE \
    PHP_ENABLE_OPENSSL=FALSE \
    PHP_ENABLE_CREATE_SAMPLE_PHP=FALSE \
    PHP_ENABLE_ZIP=TRUE \
    NGINX_SITE_ENABLED=osticket \
    NGINX_WEBROOT=/www/osticket \
    ZABBIX_AGENT_TYPE=classic \
    IMAGE_NAME="tiredofit/osticket" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-osticket/"

### Dependency Installation
RUN set -x && \
    apt-get update && \
    apt-get upgrade && \
    apt-get install  \
                    git \
                    libldap-common \
                    openssl \
                    php${PHP_VERSION}-memcached \
                    tar \
                    wget \
                    zlib1g \
                    && \
    \
### Download & Prepare OSTicket for Install
    git clone --branch "${OSTICKET_VERSION}" --depth 1 --recursive "${OSTICKET_REPO_URL}" /assets/install && \
    chown -R "${NGINX_USER}":"${NGINX_GROUP}" /assets/install && \
    chmod -R a+rX /assets/install/ && \
    chmod -R u+rw /assets/install/ && \
    mv /assets/install/setup /assets/install/setup_hidden && \
    chown -R root:root /assets/install/setup_hidden && \
    chmod 700 /assets/install/setup_hidden && \
    \
# Setup Official Plugins
    git clone --branch "${OSTICKET_PLUGINS_VERSION}" --depth 1 --recursive "${OSTICKET_PLUGINS_REPO_URL}" /usr/src/plugins && \
    php make.php hydrate && \
    for plugin in $(find * -maxdepth 0 -type d ! -path doc ! -path lib); do cp -r ${plugin} /assets/install/include/plugins; done; \
    cp -R /usr/src/plugins/*.phar /assets/install/include/plugins/ && \
    cd / && \
    \
# Add Community Plugins
    ## Archiver
    git clone --branch master --depth 1 --recursive https://github.com/clonemeagain/osticket-plugin-archiver /assets/install/include/plugins/archiver && \
    ## Attachment Preview
    git clone --branch master --depth 1 --recursive https://github.com/clonemeagain/attachment_preview /assets/install/include/plugins/attachment-preview && \
    ## Auto Closer
    git clone --branch master --depth 1 --recursive https://github.com/clonemeagain/plugin-autocloser /assets/install/include/plugins/auto-closer && \
    ## Fetch Note
    git clone --branch master --depth 1 --recursive https://github.com/bkonetzny/osticket-fetch-note /assets/install/include/plugins/fetch-note && \
    ## Field Radio Buttons
    git clone --branch master --depth 1 --recursive https://github.com/Micke1101/OSTicket-plugin-field-radiobuttons /assets/install/include/plugins/field-radiobuttons && \
    ## Mentioner
    git clone --branch master --depth 1 --recursive https://github.com/clonemeagain/osticket-plugin-mentioner /assets/install/include/plugins/mentioner && \
    ## Multi LDAP Auth
    git clone --branch master --depth 1 --recursive https://github.com/philbertphotos/osticket-multildap-auth /assets/install/include/plugins/multi-ldap && \
    mv /assets/install/include/plugins/multi-ldap/multi-ldap/* /assets/install/include/plugins/multi-ldap/ && \
    rm -rf /assets/install/include/plugins/multi-ldap/multi-ldap && \
    ## Prevent Autoscroll
    git clone --branch master --depth 1 --recursive https://github.com/clonemeagain/osticket-plugin-preventautoscroll /assets/install/include/plugins/prevent-autoscroll && \
    ## Rewriter
    git clone --branch master --depth 1 --recursive https://github.com/clonemeagain/plugin-fwd-rewriter /assets/install/include/plugins/rewriter && \
    ## Slack
    git clone --branch master --depth 1 --recursive https://github.com/clonemeagain/osticket-slack /assets/install/include/plugins/slack && \
    ## Teams (Microsoft)
    git clone --branch master --depth 1 --recursive https://github.com/ipavlovi/osTicket-Microsoft-Teams-plugin /assets/install/include/plugins/teams && \
    \
    ### Log Miscellany Installation
    touch /var/log/msmtp.log && \
    chown "${NGINX_USER}":"${NGINX_GROUP}" /var/log/msmtp.log && \
   \
## Cleanup
    apt-get cleanup && \
    rm -rf \
            /root/.composer \
            /tmp/* \
            /usr/src/*

COPY install /
