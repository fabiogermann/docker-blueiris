# BlueIris on Docker

This repo has all you need to run BlueIris in Docker (on any OS).
The Desktop UI of BlueIris is available on port 8080 and WebUI on port 8081.
OTA updates work without issues, BI license required.

## Features
- BI action scripts: Working action scripts for alerts. An example for Telegram notifications can be found here: `templates/telegram-upload.cmd` and `templates/telegram-upload.sh`. Configure BI as you normally would to trigger a scipt when an alert is fired (scirpt location would be: `C:\BlueIris\Telegram-Upload\upload.cmd` if you copy both of the templates there).
- AI object detection: The docker-compose file already has the necessary dependencies. Only BI needs to be configured to use the AI container (BI settings -> AI -> use AI server on IP/Port: put the IP and port of the AI container)

## Add-ons
- Backup clips to S3 via FTP (also supports glacier): use the docker image: [fabiogermann/ftp-proxy-s3](https://github.com/fabiogermann/ftp-proxy-s3) 

## Recent Updates

### Ubuntu Noble Migration (2025-06)
This project has been updated to use the latest `ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble` base image. Key improvements include:

- **Enhanced Service Startup**: Improved Blue Iris Windows service startup with retry logic
- **Better Graphics Support**: Added Vulkan and OpenGL libraries for improved compatibility
- **Comprehensive Logging**: Detailed startup logs available at `/config/blueiris-startup.log`
- **Debug Tools**: New debugging script for troubleshooting issues

See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for detailed migration information and troubleshooting.

## Troubleshooting

### "Console could not connect to service process" Error
If you encounter this error after installation:

1. **Check startup logs**: `docker exec -it <container> cat /config/blueiris-startup.log`
2. **Run debug script**: `./debug-blueiris.sh <container_name>`
3. **Manual service start**: `docker exec -it <container> wine net start blueiris`
4. **Restart container**: `docker-compose restart app`

### Debug Tools

#### Quick Service Check
For a quick status check of Blue Iris:
```bash
./check-service.sh dc-blueiris-app-1
```

This provides a quick overview of:
- Container status
- Blue Iris process status
- Network ports
- Service status
- Installation verification

#### Comprehensive Diagnostics
Use the included debug script for detailed diagnostics:
```bash
./debug-blueiris.sh dc-blueiris-app-1
```

This will generate a detailed report including:
- System and Wine information
- Graphics capabilities
- Service status
- Process information
- Network configuration
- Blue Iris installation status

## Known Issues
- The Timezone of the UI timeline is always in UTC (the timestamps in the video feed however is in the correct/configured time zone).
- Sometimes the UI freeses for a short time and clicks will not be registered. To "unblock" the UI you can run `docker exec -it dc-blueiris-app-1 bash -c "sudo -u abc wine explorer"` and close the explorer, the UI should be unblocked now.

For any other issue please feel free to open a GitHub issue with:
- Output from the debug script
- Container logs (`docker-compose logs app`)
- System information (OS, Docker version, hardware)
