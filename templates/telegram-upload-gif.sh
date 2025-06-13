#!/usr/bin/env bash

# inspired by https://smarthomepursuits.com/how-to-send-blue-iris-deepstack-images-alerts-to-telegram/

sleep 10

CLIP_FOLDER=${HOME}/.wine/drive_e/bi-alert-clip
LATEST_IMAGE=$(find ${CLIP_FOLDER} -type f -exec stat -c '%X %n' {} \; | sort -nr | awk 'NR==1,NR==3 {print $2}' | head -n1)

CHAT_ID="TELEGRAM_CHAT_ID_STARTS_WITH_MINUS"
TOKEN="TELEGRAM_TOKEN"


: >> lock
{
flock $fd #lock file by filedescriptor

echo $$ locking: /tmp/output.gif
ffmpeg -i ${LATEST_IMAGE} -vf "fps=5,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 /tmp/output.gif
curl -X POST -H "Content-Type:multipart/form-data" -F chat_id=$CHAT_ID -F photo=@/tmp/output.gif "https://api.telegram.org/bot$TOKEN/sendPhoto"
rm /tmp/output.gif
echo $$ releasing lock: /tmp/output.gif

} {fd}<lock
