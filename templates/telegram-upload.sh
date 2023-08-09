#!/usr/bin/env bash

# inspired by https://smarthomepursuits.com/how-to-send-blue-iris-deepstack-images-alerts-to-telegram/

sleep 10

PIC_FOLDER=${HOME}/.wine/drive_c/BlueIris/Alert-JPEG-Export
LATEST_IMAGE=$(find ${PIC_FOLDER} -type f -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR==1,NR==3 {print $2}' | head -n1)

CHAT_ID="TELEGRAM_CHAT_ID_STARTS_WITH_MINUS"
TOKEN="TELEGRAM_TOKEN"

curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=$CHAT_ID -F photo=@${LATEST_IMAGE} "https://api.telegram.org/bot$TOKEN/sendPhoto"
