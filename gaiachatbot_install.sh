#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/Bohdan18/nodes/main/gaiachatbot_install.sh)

# Запит адреси гаманця у користувача
read -p "Введіть адресу Node ID: " WALLET_ADDRESS

echo "-----------------------------------------------------------------------------"
echo "Встановлення необхідних пакетів"
echo "-----------------------------------------------------------------------------"

# Оновлення системи та встановлення необхідних пакетів
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip nano -y

# Встановлення бібліотек Python
pip install requests faker

echo "-----------------------------------------------------------------------------"
echo "Встановлення чатбота"
echo "-----------------------------------------------------------------------------"

# Створення скрипта з використанням введеної адреси гаманця
cat <<EOL > ~/random_chat_with_faker.py
import requests
import random
import logging
import time
from faker import Faker
from datetime import datetime

node_url = "https://$WALLET_ADDRESS.gaia.domains"

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
        print(f"Failed to get response from API: {e}")
        return None

def extract_reply(response):
    if response and 'choices' in response:
        return response['choices'][0]['message']['content']
    return ""

while True:
    random_question = faker.sentence(nb_words=10)
    message = {
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": random_question}
        ]
    }

    question_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    response = send_message(node_url, message)
    reply = extract_reply(response)

    reply_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    log_message("Node replied", f"Q ({question_time}): {random_question} A ({reply_time}): {reply}")

    print(f"Q ({question_time}): {random_question}\nA ({reply_time}): {reply}")

    delay = random.randint(60, 180)
    time.sleep(delay)
EOL

echo "-----------------------------------------------------------------------------"
echo "Встановлення pm2"
echo "-----------------------------------------------------------------------------"

# Встановлення pm2
sudo npm install -g pm2

echo "-----------------------------------------------------------------------------"
echo "Запуск скрипта через pm2"
echo "-----------------------------------------------------------------------------"

# Запуск скрипта через pm2
pm2 start ~/random_chat_with_faker.py --name gaiachat

echo "-----------------------------------------------------------------------------"
echo "Збереження налаштувань pm2 для автоматичного старту після перезавантаження"
echo "-----------------------------------------------------------------------------"

# Збереження налаштувань pm2 для автоматичного старту після перезавантаження
pm2 startup
pm2 save

echo "Скрипт завершив виконання. Ваш скрипт запущено через pm2 і працює у фоновому режимі."

