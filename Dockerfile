FROM php:7.4-fpm-alpine

MAINTAINER docker-container@cbrandel.de

# docker-entrypoint.sh dependencies
RUN apk add --no-cache \
    bash \
    tzdata

# Install dependencies
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        bzip2-dev \
        curl-dev \
        freetype-dev \
        icu-dev \
        imagemagick-dev \
        imap-dev \
        libevent-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        net-snmp-dev \
        openldap-dev \
        pcre-dev \
    ; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-configure ldap; \
    docker-php-ext-install -j "$(nproc)" \
       bz2 \
       curl \
       exif \
       gd \
       imap \
       intl \
       ldap \
       mysqli \
       opcache \
       snmp \
       soap \
       xmlrpc \
       zip \
    ; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .glpi-phpexts-rundeps $runDeps; \
    apk del --no-network .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
ENV MAX_EXECUTION_TIME 600
ENV MEMORY_LIMIT 512M
ENV UPLOAD_LIMIT 2048K
# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN set -ex; \
    \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > $PHP_INI_DIR/conf.d/opcache-recommended.ini; \
    \
    { \
        echo 'session.cookie_httponly=1'; \
        echo 'session.use_strict_mode=1'; \
    } > $PHP_INI_DIR/conf.d/session-strict.ini; \
    \
    { \
        echo 'allow_url_fopen=Off'; \
        echo 'max_execution_time=${MAX_EXECUTION_TIME}'; \
        echo 'max_input_vars=10000'; \
        echo 'memory_limit=${MEMORY_LIMIT}'; \
        echo 'post_max_size=${UPLOAD_LIMIT}'; \
        echo 'upload_max_filesize=${UPLOAD_LIMIT}'; \
    } > $PHP_INI_DIR/conf.d/glpi-misc.ini

LABEL \
  org.opencontainers.image.title="GLPI" \
  org.opencontainers.image.description="GLPI with separate nginx and mariadb container" \
  org.opencontainers.image.url="https://github.com/cbrandel/docker-glpi" \
  org.opencontainers.image.source="git@github.com:cbrandel/docker-glpi.git"

# GLPI settings
ENV GLPI_ROOT /var/www/glpi
ENV GLPI_CONFIG_DIR /etc/glpi
ENV GLPI_VAR_DIR /var/lib/glpi
ENV GLPI_LOG_DIR /var/log/glpi
# Prepare directories
RUN set -ex; \
    mkdir -p "${GLPI_VAR_DIR}" "${GLPI_LOG_DIR}" "${GLPI_CONFIG_DIR}" "${GLPI_ROOT}" ; \
    chown www-data:www-data "${GLPI_VAR_DIR}" "${GLPI_LOG_DIR}" "${GLPI_CONFIG_DIR}" "${GLPI_ROOT}"

# GLPI Version and URL
ARG GLPI_VERSION
ENV VERSION $GLPI_VERSION
ENV URL https://github.com/glpi-project/glpi/releases/download/${VERSION}/glpi-${VERSION}.tgz
# Download tarball and extract
RUN set -ex; \
    curl -fsSL -o glpi.tar.gz $URL; \
    tar -xf glpi.tar.gz -C "${GLPI_ROOT}" --strip-components=1; \
    chown -R www-data:www-data "${GLPI_ROOT}"; \
    rm -r glpi.tar.gz; \
    # forward request and error logs to docker log collector
    ln -sf /dev/stderr /var/log/glpi/php-errors.log

VOLUME [ "${GLPI_VAR_DIR}" "${GLPI_CONFIG_DIR}" ]

# Copy configuration
COPY glpi/downstream.php ${GLPI_ROOT}/downstream.php
COPY glpi/local_define.php ${GLPI_CONFIG_DIR}/local_define.php

# Copy main script
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["php-fpm"]