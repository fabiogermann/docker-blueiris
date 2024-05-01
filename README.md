# BlueIris on Docker

This repo has all you need to run BlueIris in Docker (on any OS).
The Desktop UI of BlueIris is available on port 8080 and WebUI on port 8081.
OTA updates work without issues, BI license required.

## Features
- BI action scripts: Working action scripts for alerts. An example for Telegram notifications can be found here: `templates/telegram-upload.cmd` and `templates/telegram-upload.sh`. Configure BI as you normally would to trigger a scipt when an alert is fired (scirpt location would be: `C:\BlueIris\Telegram-Upload\upload.cmd` if you copy both of the templates there).
- AI object detection: The docker-compose file already has the necessary dependencies. Only BI needs to be configured to use the AI container (BI settings -> AI -> use AI server on IP/Port: put the IP and port of the AI container)

## Add-ons
- Backup clips to S3 via FTP (also supports glacier): use the docker image: [fabiogermann/ftp-proxy-s3](https://github.com/fabiogermann/ftp-proxy-s3) 

## Known Issues
- The Timezone of the UI timeline is always in UTC (the timestamps in the video feed however is in the correct/configured time zone).
- Sometimes the UI freeses for a short time and clicks will not be registered. To "unblock" the UI you can run `docker exec -it dc-blueiris-app-1 bash -c "sudo -u abc wine explorer"` and close the explorer, the UI should be unblocked now.

For any other issue please feel free to open a GitHub issue.
