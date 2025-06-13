FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV WINEARCH=win32
ENV WINEDLLOVERRIDES="mscoree="
ENV \
	CUSTOM_PORT="8080" \
	GUIAUTOSTART="true" \
 	CUSTOM_USER="biuser" \
  	DISABLE_IPV6="true" \
	HOME="/config"

# Install wine and graphics dependencies
RUN \
 apt-get update && apt-get -y upgrade && \
 apt-get -y install unzip wget cabextract tzdata python3-xdg \
 libvulkan1 mesa-vulkan-drivers libegl1 libgl1 libglu1-mesa \
 libegl1-mesa libegl1-mesa-dev libgl1-mesa-dri \
 mesa-utils vulkan-tools net-tools procps && \
 wget -qO - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /usr/share/keyrings/winehq-archive-keyring.gpg && \
 dpkg --add-architecture i386 && \
 echo "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ noble main" > /etc/apt/sources.list.d/winehq.list && \
 apt-get update && \
 apt-get -y install --install-recommends winehq-devel

# Install winetricks
RUN \
 wget -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
 chmod +x /usr/bin/winetricks 

RUN ln -fs /usr/share/zoneinfo/America/Montreal /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

COPY /root /

RUN \
 wget -O /tmp/blueiris.exe https://blueirissoftware.com/blueiris.exe

RUN mkdir /data
# another VOLUME from parent image is /config
VOLUME /data
