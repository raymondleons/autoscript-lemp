#!/bin/bash

# Update sistem
sudo apt update

# Install Nginx
sudo apt install -y nginx

# Install MySQL
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_root_password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password your_root_password'
sudo apt install -y mysql-server

# Install PHP dan ekstensi yang diperlukan
sudo apt install -y php-fpm php-mysql php-mbstring

# Install phpMyAdmin
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password your_phpmyadmin_password'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password your_root_password'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password your_phpmyadmin_password'
sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect none'
sudo apt install -y phpmyadmin

# Konfigurasi Nginx
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

# Mengaktifkan cache di Nginx
sudo sed -i '/^http {/a \
    fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=LEMP_CACHE:10m inactive=60m;\
    fastcgi_cache_key "$scheme$request_method$host$request_uri";\
    fastcgi_cache_use_stale error timeout invalid_header http_500;\
    fastcgi_ignore_headers Cache-Control Expires Set-Cookie;\
' /etc/nginx/nginx.conf

# Mengaktifkan cache di konfigurasi situs default
sudo sed -i '/location ~ \\\.php$ {/,/}/ s/fastcgi_pass unix:.*;/fastcgi_pass unix:\/run\/php\/php7.4-fpm.sock;\n\
        fastcgi_cache LEMP_CACHE;\
        fastcgi_cache_valid 200 301 302 10m;\
        fastcgi_cache_bypass $no_cache;\
        fastcgi_no_cache $no_cache;\
        fastcgi_cache_use_stale error timeout invalid_header http_500;\
        fastcgi_cache_lock on;\
        fastcgi_cache_lock_timeout 5s;\
/g' /etc/nginx/sites-available/default

# Membuat konfigurasi untuk phpMyAdmin
sudo tee /etc/nginx/sites-available/phpmyadmin <<EOF
server {
    listen 80;
    server_name phpmyadmin.example.com;
    root /usr/share/phpmyadmin;
    index index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \\\.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
        fastcgi_cache LEMP_CACHE;
        fastcgi_cache_valid 200 301 302 10m;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
        fastcgi_cache_use_stale error timeout invalid_header http_500;
        fastcgi_cache_lock on;
        fastcgi_cache_lock_timeout 5s;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Menambahkan symlink konfigurasi phpMyAdmin
sudo ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/

# Restart Nginx
sudo service nginx restart

echo "Instalasi selesai. Anda dapat mengakses phpMyAdmin melalui http://phpmyadmin.example.com"
