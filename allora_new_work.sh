#!/bin/bash

# Перевірка наявності необхідних інструментів
command -v python3 >/dev/null 2>&1 || { echo >&2 "Python3 не встановлено. Встановіть Python3 і спробуйте знову."; exit 1; }
command -v pip3 >/dev/null 2>&1 || { echo >&2 "pip3 не встановлено. Встановіть pip3 і спробуйте знову."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo >&2 "Docker не встановлено. Встановіть Docker і спробуйте знову."; exit 1; }

# Встановлення необхідних бібліотек Python
pip3 install pandas torch transformers

# Створення каталогу для воркера
mkdir -p allora-huggingface-worker
cd allora-huggingface-worker || exit

# Створення файлу моделі на основі часових рядів
cat <<EOL > model.py
import pandas as pd
import torch
from transformers import TimeSeriesTransformerModel

def load_data(file_path):
    return pd.read_csv(file_path)

def preprocess_data(data):
    prices = data['price'].values
    return torch.tensor(prices).float()

def predict(prices_tensor):
    model = TimeSeriesTransformerModel.from_pretrained("huggingface/time-series-transformer")
    with torch.no_grad():
        forecast = model(prices_tensor)
    return forecast[-1].item()

if __name__ == "__main__":
    data = load_data('data.csv')  # замініть на ваш файл з даними
    prices_tensor = preprocess_data(data)
    prediction = predict(prices_tensor)
    print(f"Прогноз ціни на наступні 10 хвилин: {prediction}")
EOL

# Створення Dockerfile для воркера
cat <<EOL > Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY . .

RUN pip install pandas torch transformers

CMD ["python", "model.py"]
EOL

# Створення файлу даних (для тестування)
cat <<EOL > data.csv
date,price
2024-08-21 12:00:00,1800.5
2024-08-21 12:01:00,1801.0
2024-08-21 12:02:00,1802.3
2024-08-21 12:03:00,1802.7
2024-08-21 12:04:00,1803.0
EOL

# Збірка Docker-контейнера
docker build -t allora-worker .

# Запуск Docker-контейнера
docker run --rm allora-worker

echo "Воркера успішно встановлено та запущено."
