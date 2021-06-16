FROM php:7.4-fpm

LABEL Jhousyfran Costa <jhousyfrancosta@gmail.com>

# install necessary packages
RUN set -x \
    && apt-get update \
    && apt-get install libaio-dev mc unzip zlib1g-dev libmemcached-dev --no-install-recommends --no-install-suggests -y


# Install Postgre PDO
RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install oracle instant client
ENV ORA_CLIENT=instantclient-basic-linux.x64-21.1.0.0.0.zip
ENV ORA_CLIENT_SDK=instantclient-sdk-linux.x64-21.1.0.0.0.zip
ENV ORA_URL_PART=https://download.oracle.com/otn_software/linux/instantclient/211000


WORKDIR /opt

RUN curl -O ${ORA_URL_PART}/${ORA_CLIENT} \
    && curl -O ${ORA_URL_PART}/${ORA_CLIENT_SDK} \
    && unzip /opt/${ORA_CLIENT} \
    && unzip /opt/${ORA_CLIENT_SDK} \
    && rm /opt/${ORA_CLIENT} && rm ${ORA_CLIENT_SDK}



# install & enable xdebug
RUN pecl install xdebug-3.0.2 && docker-php-ext-enable xdebug
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# install & enable oci8
RUN pecl install --onlyreqdeps --nobuild oci8-2.2.0 \
    && cd "$(pecl config-get temp_dir)/oci8" \
    && phpize \
    && ./configure --with-oci8=instantclient,/opt/instantclient_21_1 \
    && make && make install \
    && docker-php-ext-enable oci8


# install & enable pdo-oci
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/instantclient_21_1,21.1 \
    && docker-php-ext-install pdo_oci



RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin \
    --filename=composer

WORKDIR /var/www

EXPOSE 9000

CMD ["php-fpm"]