FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

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

# Update to latest
RUN \
 apt-get update && apt-get -y upgrade

# Install dependencies
RUN \
 apt-get -y install unzip wget cabextract tzdata python3-xdg
# apt-get -y install unzip wget cabextract tzdata python3-xdg \
# libvulkan1 mesa-vulkan-drivers libegl1 libgl1 libglu1-mesa \
# libgl1-mesa-dri mesa-utils vulkan-tools net-tools procps \
# winbind samba-common-bin libnss-winbind

# Install wine-8.0.2
RUN \
 wget -qO - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /usr/share/keyrings/winehq-archive-keyring.gpg && \
 dpkg --add-architecture i386 && \
 echo "deb [signed-by=/usr/share/keyrings/winehq-archive-keyring.gpg] https://dl.winehq.org/wine-builds/ubuntu/ jammy main" > /etc/apt/sources.list.d/winehq.list && \
 add-apt-repository ppa:cybermax-dexter/sdl2-backport -y && \
 apt-get update && \
 apt-get -y install --allow-unauthenticated --install-recommends winehq-stable

# Install winetricks
RUN \
 wget -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
 chmod +x /usr/bin/winetricks 

RUN ln -fs /usr/share/zoneinfo/America/Montreal /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

COPY /root /

RUN mkdir /data
# another VOLUME from parent image is /config
VOLUME /data
