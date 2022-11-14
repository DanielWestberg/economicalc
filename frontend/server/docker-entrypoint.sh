#!/bin/sh
set -e

# NGINX SERVER
echo "Nginx Server"
echo "-------------------"
echo "Backend REST API: ${BACKEND_API}"

if [ "$NAMESERVER" == "" ]
then
    export NAMESERVER=$(awk '/^nameserver/{print $2}' /etc/resolv.conf)
fi

# Replace environment variables
envsubst '$NAMESERVER ${BACKEND_API}' < /etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.new.conf
mv /etc/nginx/conf.d/default.new.conf /etc/nginx/conf.d/default.conf

exec "$@"
