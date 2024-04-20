#!/bin/bash

massa_pass=$1
source $HOME/.profile

cd $HOME/massa/massa-client
massa_wallet_address=$(./massa-client -p $massa_pass wallet_info | grep Address | awk '{ print $2 }')

