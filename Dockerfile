FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

ENV WINEARCH=win32
ENV WINEDLLOVERRIDES="mscoree="
ENV \
	CUSTOM_PORT="8080" \
	GUIAUTOSTART="true" \
	HOME="/config"


# Install wine
RUN \
 apt-get update && apt-get -y install wget cabextract && \
 wget -qO - https://dl.winehq.org/wine-builds/winehq.key | apt-key add - && \
 dpkg --add-architecture i386 && \
 apt-add-repository https://dl.winehq.org/wine-builds/ubuntu/ && \
 add-apt-repository ppa:cybermax-dexter/sdl2-backport -y && \
 apt-get -y install --allow-unauthenticated --install-recommends winehq-stable

RUN \
 wget -O /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
 chmod +x /usr/bin/winetricks 

RUN \
 wget -O /tmp/blueiris.exe https://blueirissoftware.com/blueiris.exe

COPY /root /
