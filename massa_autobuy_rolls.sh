#!/bin/bash

# запуск
# tmux new-session -d -s massa_buyrolls_mainnet 'bash <(curl -s https://raw.githubusercontent.com/Bohdan18/nodes/main/massa_autobuy_rolls.sh) massa_password'

# стоп
# tmux kill-session -t massa_buyrolls_mainnet 

# логи 
# tmux attach-session -t massa_buyrolls_mainnet
# Ctrl+B і D - вийти з логів

massa_pass=$1
source $HOME/.profile

cd $HOME/massa/massa-client
massa_wallet_address=$(./massa-client -p $massa_pass wallet_info | grep Address | awk '{ print $2 }')

while true
do
  balance=$(./massa-client -p $massa_pass wallet_info | grep "Balance" | awk '{ print $3 }' | sed 's/candidate=//;s/,//')
  int_balance=${balance%%.*}
  if [ $int_balance -gt "99" ] ; then   
    resp=$(./massa-client -p $massa_pass buy_rolls $massa_wallet_address 1 0.01)
    echo "buy rolls"
  else
    echo "Less than 100"
  fi
  printf "sleep"
  for((sec=0; sec<60; sec++))
  do
    printf "."
    sleep 1
  done
  printf "\n"
done

