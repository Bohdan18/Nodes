#!/bin/bash

cd /
gaianet stop

bash <(curl -s https://raw.githubusercontent.com/DOUBLE-TOP/guides/main/nesa/install.sh)

sed -i 's/8080:8080/8088:8080/' ~/.nesa/docker/compose.ipfs.yml

cd ~/.nesa/docker && docker compose -f compose.community.yml down ipfs && docker volume rm docker_ipfs-data docker_ipfs-staging && docker compose -f compose.community.yml up -d ipfs

gaianet start

pm2 restart gaiachat

echo "-----------------------------------------------------------------------------"
echo "DONE"
echo "-----------------------------------------------------------------------------"
