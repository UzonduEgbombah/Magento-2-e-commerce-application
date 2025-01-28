FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmagickwand-dev \
    libpng-dev \
    libwebp-dev \
    libxslt1-dev \
    libzip-dev \
    nginx \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        intl \
        opcache \
        pdo_mysql \
        soap \
        xsl \
        zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Configure PHP
COPY docker/php.ini /usr/local/etc/php/conf.d/magento.ini

# Configure Nginx
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Set working directory
WORKDIR /var/www/html

# Install Magento
RUN composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .

# Set permissions
RUN chown -R www-data:www-data /var/www/html

# Start services
CMD ["sh", "-c", "php-fpm & nginx -g 'daemon off;'"]

EXPOSE 80