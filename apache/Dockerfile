FROM httpd:2.4-bullseye

COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
RUN mkdir -p /etc/apache2/ssl
RUN mkdir -p /etc/apache2/sites-available

EXPOSE 80
EXPOSE 443