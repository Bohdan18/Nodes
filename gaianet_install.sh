#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/Bohdan18/nodes/main/gaianet_install.sh)

# Оновлення та встановлення необхідних пакетів
sudo apt update -y
sudo apt-get update -y

# Завантаження та виконання останньої версії скрипта установки GaiaNet Node
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash

# Вибір конфігурації Bash
source ~/.bashrc

# Ініціалізація GaiaNet з конфігурацією
gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json

# Запуск ноди
gaianet start

# Отримання інформації про ноду (Node ID і Device ID)
gaianet info
