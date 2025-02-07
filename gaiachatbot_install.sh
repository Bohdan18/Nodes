#!/bin/bash

# Використання:
# bash <(curl -s https://raw.githubusercontent.com/Bohdan18/nodes/main/gaiachatbot_install.sh)

echo "-----------------------------------------------------------------------------"
echo "Введіть адресу Node ID (без https:// та .gaia.domains):"
echo "-----------------------------------------------------------------------------"
read -p "Node ID: " NODE_ID

# Перевірка введених даних
if [[ -z "$NODE_ID" ]]; then
    echo "Помилка: Ви не ввели Node ID. Спробуйте ще раз."
    exit 1
fi

NODE_URL="https://${NODE_ID}.gaia.domains/v1/chat/completions"

echo "-----------------------------------------------------------------------------"
echo "Встановлення необхідних пакетів"
echo "-----------------------------------------------------------------------------"

# Оновлення системи та встановлення необхідних пакетів
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip nano -y

# Встановлення бібліотек Python
python3 -m pip install --upgrade pip
python3 -m pip install requests faker

echo "-----------------------------------------------------------------------------"
echo "Встановлення чатбота"
echo "-----------------------------------------------------------------------------"

# Створення Python-скрипта
cat <<EOL > ~/random_chat_with_faker.py
import requests
import random
import logging
import time
from faker import Faker
from datetime import datetime

NODE_URL = "${NODE_URL}"
faker = Faker()

headers = {
    "accept": "application/json",
    "Content-Type": "application/json"
}

logging.basicConfig(filename='chat_log.txt', level=logging.INFO, format='%(asctime)s - %(message)s')

def log_message(node, message):
    logging.info(f"{node}: {message}")

def send_message(node_url, message):
    try:
        response = requests.post(node_url, json=message, headers=headers, timeout=600)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Помилка отримання відповіді від API: {e}")
        return None

def extract_reply(response):
    if response and 'choices' in response and len(response['choices']) > 0:
        return response['choices'][0].get('message', {}).get('content', "")
    return "Помилка отримання відповіді"

while True:
    random_question = faker.sentence(nb_words=10)
    message = {
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": random_question}
        ]
    }

    question_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    response = send_message(NODE_URL, message)
    reply = extract_reply(response)

    reply_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    log_message("Node", f"Q ({question_time}): {random_question} | A ({reply_time}): {reply}")

    print(f"Q ({question_time}): {random_question}\nA ({reply_time}): {reply}")

    delay = random.randint(60, 180)
    time.sleep(delay)
EOL

echo "-----------------------------------------------------------------------------"
echo "Перевірка та встановлення pm2"
echo "-----------------------------------------------------------------------------"

# Перевіряємо, чи встановлений npm, перш ніж встановлювати pm2
if ! command -v npm &> /dev/null; then
    echo "npm не знайдено, встановлюємо Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

sudo npm install -g pm2

echo "-----------------------------------------------------------------------------"
echo "Запуск скрипта через pm2"
echo "-----------------------------------------------------------------------------"

# Запуск скрипта через pm2
pm2 start ~/random_chat_with_faker.py --name gaiachat

echo "-----------------------------------------------------------------------------"
echo "Налаштування автоматичного запуску pm2"
echo "-----------------------------------------------------------------------------"

pm2 startup
pm2 save

echo "Скрипт завершив виконання. Ваш чатбот запущений через pm2 і працює у фоновому режимі."
