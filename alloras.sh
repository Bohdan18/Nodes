#!/bin/bash
docker-compose -f $HOME/basic-coin-prediction-node/docker-compose.yml down
# Запит змінних
read -p "Enter your phase (Kepler account seed): " PHRASE
read -p "Enter NodeRpc URL (choose one from the provided list): " NODE_RPC
read -p "Enter your API Key: " API_KEY

# Клонуємо репозиторій
git clone https://github.com/allora-network/allora-huggingface-walkthrough
cd allora-huggingface-walkthrough || exit

# Налаштування даних для воркера
mkdir -p worker-data
chmod -R 777 worker-data

cp config.example.json config.json

if [[ ! -f config.json ]]; then
    echo "File config.json does not exist."
    exit 1
fi

# Текст для запису у файл
NEW_CONTENT=$(cat <<EOF
{
   "wallet": {
       "addressKeyName": "test",
       "addressRestoreMnemonic": "$PHRASE",
       "alloraHomeDir": "/root/.allorad",
       "gas": "1000000",
       "gasAdjustment": 1.0,
       "nodeRpc": "$NODE_RPC",
       "maxRetries": 1,
       "delay": 1,
       "submitTx": false
   },
   "worker": [
       {
           "topicId": 1,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 1,
           "parameters": {
               "InferenceEndpoint": "http://inference:8010/inference/{Token}",
               "Token": "ETH"
           }
       },
       {
           "topicId": 2,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 3,
           "parameters": {
               "InferenceEndpoint": "http://inference:8010/inference/{Token}",
               "Token": "BNB"
           }
       },
       {
           "topicId": 3,
           "inferenceEntrypointName": "api-worker-reputer",
           "loopSeconds": 5,
           "parameters": {
               "InferenceEndpoint": "http://inference:8010/inference/{Token}",
               "Token": "ARB"
           }
       }
   ]
}
EOF
)

# Запис нового тексту у файл
echo "$NEW_CONTENT" > config.json

echo "File config.json has been updated."

if [[ ! -f app.py ]]; then
    echo "File app.py does not exist."
    exit 1
fi

# Текст для запису у файл
NEW_CONTENT=$(cat <<EOF
from flask import Flask, Response
import requests
import json
import pandas as pd
import torch
from chronos import ChronosPipeline

# create our Flask app
app = Flask(__name__)

# define the Hugging Face model we will use
model_name = "amazon/chronos-t5-tiny"

def get_coingecko_url(token):
    base_url = "https://api.coingecko.com/api/v3/coins/"
    token_map = {
        'ETH': 'ethereum',
        'BNB': 'binancecoin',
        'ARB': 'arbitrum'
    }
    
    token = token.upper()
    if token in token_map:
        url = f"{base_url}{token_map[token]}/market_chart?vs_currency=usd&days=30&interval=daily"
        return url
    else:
        raise ValueError("Unsupported token")

# define our endpoint
@app.route("/inference/<string:token>")
def get_inference(token):
    """Generate inference for given token."""
    try:
        # use a pipeline as a high-level helper
        pipeline = ChronosPipeline.from_pretrained(
            model_name,
            device_map="auto",
            torch_dtype=torch.bfloat16,
        )
    except Exception as e:
        return Response(json.dumps({"pipeline error": str(e)}), status=500, mimetype='application/json')

    try:
        # get the data from Coingecko
        url = get_coingecko_url(token)
    except ValueError as e:
        return Response(json.dumps({"error": str(e)}), status=400, mimetype='application/json')

    headers = {
        "accept": "application/json",
        "x-cg-demo-api-key": "$API_KEY" # replace with your API key
    }

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        data = response.json()
        df = pd.DataFrame(data["prices"])
        df.columns = ["date", "price"]
        df["date"] = pd.to_datetime(df["date"], unit='ms')
        df = df[:-1] # removing today's price
        print(df.tail(5))
    else:
        return Response(json.dumps({"Failed to retrieve data from the API": str(response.text)}), 
                        status=response.status_code, 
                        mimetype='application/json')

    # define the context and the prediction length
    context = torch.tensor(df["price"])
    prediction_length = 1

    try:
        forecast = pipeline.predict(context, prediction_length)  # shape [num_series, num_samples, prediction_length]
        print(forecast[0].mean().item()) # taking the mean of the forecasted prediction
        return Response(str(forecast[0].mean().item()), status=200)
    except Exception as e:
        return Response(json.dumps({"error": str(e)}), status=500, mimetype='application/json')

# run our Flask app
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8010, debug=True)
EOF
)

# Запис нового тексту у файл
echo "$NEW_CONTENT" > app.py

echo "File app.py has been updated."

if [[ ! -f docker-compose.yaml ]]; then
    echo "File docker-compose.yaml does not exist."
    exit 1
fi

# Текст для запису у файл
NEW_CONTENT=$(cat <<EOF
services:
  inference:
    container_name: inference-hf
    build:
      context: .
      dockerfile: Dockerfile
    command: python -u /app/app.py
    ports:
      - "8010:8010"  # Змінено порт  на 8010

  worker:
    container_name: worker
    image: alloranetwork/allora-offchain-node:latest
    volumes:
      - ./worker-data:/data
    depends_on:
      - inference
    env_file:
      - ./worker-data/env_file
  
volumes:
  inference-data:
  worker-data:
EOF
)

# Запис нового тексту у файл
echo "$NEW_CONTENT" > docker-compose.yaml

echo "File docker-compose.yaml has been updated."

# Ініціалізація воркера та запуск
chmod +x init.config
./init.config

docker compose up --build -d

docker compose logs -f
