#!/bin/bash
mkdir -p www/ssl

openssl dhparam -out ./www/ssl/dhparam.pem 2048

# On initial cert obtainment, use a standalone server since this is a 'first time' setup.
docker-compose run --publish 80:80 certbot certonly --standalone --agree-tos --no-eff-email -d imjac.in,admin.imjac.in,auth.imjac.in,dev.imjac.in,www.imjac.in
docker-compose run certbot certificates
