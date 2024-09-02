#!/bin/bash

# Update and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y

# Download and extract Fractal Bitcoin node
wget https://github.com/fractal-bitcoin/fractald-release/releases/download/v0.1.7/fractald-0.1.7-x86_64-linux-gnu.tar.gz
tar -zxvf fractald-0.1.7-x86_64-linux-gnu.tar.gz

# Move to the extracted directory and create the data directory
cd fractald-0.1.7-x86_64-linux-gnu/
mkdir data

# Copy the bitcoin.conf file to the data directory
cp ./bitcoin.conf ./data

# Create the systemd service file for Fractal node
sudo tee /etc/systemd/system/fractald.service > /dev/null << EOF
[Unit]
Description=Fractal Node
After=network-online.target

[Service]
User=$USER
ExecStart=/root/fractald-0.1.7-x86_64-linux-gnu/bin/bitcoind -datadir=/root/fractald-0.1.7-x86_64-linux-gnu/data/ -maxtipage=504576000
Restart=always
RestartSec=5
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# Create a Bitcoin wallet
cd bin
./bitcoin-wallet -wallet=wallet -legacy create

# Dump the wallet's private key
./bitcoin-wallet -wallet=/root/.bitcoin/wallets/wallet/wallet.dat -dumpfile=/root/.bitcoin/wallets/wallet/MyPK.dat dump
cd && awk -F 'checksum,' '/checksum/ {print "Wallet Private Key:" $2}' .bitcoin/wallets/wallet/MyPK.dat

# Reload systemd, enable and start the Fractal service
sudo systemctl daemon-reload
sudo systemctl enable fractald
sudo systemctl start fractald

# Check the logs
sudo journalctl -u fractald -f --no-hostname -o cat
