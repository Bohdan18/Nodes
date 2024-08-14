#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/Bohdan18/nodes/main/gaianet_install.sh)

echo "-----------------------------------------------------------------------------"
echo "Оновлення та встановлення необхідних пакетів"
echo "-----------------------------------------------------------------------------"

# Оновлення та встановлення необхідних пакетів
sudo apt update -y
sudo apt-get update -y

echo "-----------------------------------------------------------------------------"
echo "Завантаження та виконання останньої версії скрипта установки GaiaNet Node"
echo "-----------------------------------------------------------------------------"

# Завантаження та виконання останньої версії скрипта установки GaiaNet Node
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash

echo "-----------------------------------------------------------------------------"
echo "Перезавантаження середовища для доступності gaianet CLI"
echo "-----------------------------------------------------------------------------"

# Перезавантаження середовища для доступності gaianet CLI
echo "Зачекайте 5 секунд, поки .bashrc оновлюється..."
sleep 5
source /root/.bashrc
echo "Зачекайте 5 секунд, поки .bashrc оновлюється..."
sleep 5
source /root/.bashrc

# Перевірка наявності команди gaianet
if command -v gaianet &> /dev/null
then
    echo "GaiaNet встановлено та доступно."
else
    echo "GaiaNet не знайдено. Перевірка можливих шляхів установки."

    # Перевірка стандартних шляхів
    if [ -f /root/.gaianet/bin/gaianet ]; then
        echo "Знаходження gaianet у /root/.gaianet/bin/"
        export PATH=$PATH:/root/.gaianet/bin
    else
        echo "GaiaNet не знайдено. Перевірте шлях до установки або повторіть установку."
        exit 1
    fi
fi


echo "-----------------------------------------------------------------------------"
echo "Ініціалізація GaiaNet з конфігурацією"
echo "-----------------------------------------------------------------------------"

# Ініціалізація GaiaNet з конфігурацією
gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json

echo "-----------------------------------------------------------------------------"
echo "Запуск ноди"
echo "-----------------------------------------------------------------------------"

# Запуск ноди
gaianet start

echo "-----------------------------------------------------------------------------"
echo "Отримання інформації про ноду (Node ID і Device ID)"
echo "-----------------------------------------------------------------------------"

# Отримання інформації про ноду (Node ID і Device ID)
gaianet info

