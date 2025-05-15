FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive

# Install the packages we need. Avahi will be included
RUN apt-get update && apt-get install -y \
	cups \
 	cups-bsd \
 	cups-common \
	cups-pdf \
	cups-client \
	cups-filters \
	ghostscript \
 	avahi-daemon \
	wget \
	&& rm -rf /var/cache/apk/*

 # 启用 i386 架构并安装基础 32 位库
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libc6:i386 \
        libstdc++6:i386 \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 Brother 打印驱动
ARG BROTHER_PRINTER_DRIVER_URL="https://download.brother.com/pub/com/linux/linux/packages/dcpt426wpdrv-3.5.0-2.i386.deb"
ARG BROTHER_PRINTER_DRIVER_FILENAME="dcpt426wpdrv-3.5.0-2.i386.deb"

RUN wget -O /tmp/${BROTHER_PRINTER_DRIVER_FILENAME} ${BROTHER_PRINTER_DRIVER_URL}
RUN dpkg -i --force-all /tmp/${BROTHER_PRINTER_DRIVER_FILENAME} || apt-get install -fy --no-install-recommends
RUN rm /tmp/${BROTHER_PRINTER_DRIVER_FILENAME}

# This will use port 631
EXPOSE 631

# We want a mount for these
VOLUME /config
VOLUME /services

# Add scripts
ADD root /
RUN chmod +x /root/*

#Run Script
CMD ["/root/run_cups.sh"]

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
 	sed -i 's/IdleExitTimeout/#IdleExitTimeout/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf && \
	echo "ReadyPaperSizes A4,TA4,4X6FULL,T4X6FULL,2L,T2L,A6,A5,B5,L,TL,INDEX5,8x10,T8x10,4X7,T4X7,Postcard,TPostcard,ENV10,EnvDL,ENVC6,Letter,Legal" >> /etc/cups/cupsd.conf && \
	echo "DefaultPaperSize A4" >> /etc/cups/cupsd.conf && \
	echo "pdftops-renderer ghostscript" >> /etc/cups/cupsd.conf
