#!/bin/bash

# Перейти до директорії з бінарними файлами
cd /root/fractald-0.1.7-x86_64-linux-gnu/bin

# Отримати приватний ключ із файлу та вивести його на екран
awk -F 'checksum,' '/checksum/ {print "Wallet Private Key: " $2}' /root/.bitcoin/wallets/wallet/MyPK.dat

cd

