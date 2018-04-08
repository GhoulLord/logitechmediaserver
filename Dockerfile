FROM buildpack-deps:jessie-curl

MAINTAINER https://github.com/GhoulLord/logitechmediaserver

ENV DEBIAN_FRONTEND noninteractive

ENV USER=logitech \
    GROUP=everybody \
    PUID=1008 \
    PGID=100

ARG http_proxy

RUN echo "deb http://www.deb-multimedia.org jessie main non-free" | tee -a /etc/apt/sources.list && \
    apt-get update && apt-get install -y --force-yes deb-multimedia-keyring && \
    apt-get upgrade -y --force-yes && \
    apt-get install -y --force-yes \
    perl \
    libcrypt-openssl-rsa-perl libio-socket-inet6-perl libwww-perl libio-socket-ssl-perl \
    locales \
    faad \
    faac \
    flac \
    lame \
    sox \
    ffmpeg \
    wavpack \
    --no-install-recommends && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Use a nightly release, can be updated in place without rebuilding image
# ARG LMSDEB=http://downloads.slimdevices.com/nightly/7.9/sc/52be1b6/logitechmediaserver_7.9.0~1485445004_all.deb
# 7.9.0 final release, 8th Mar 2017.
ARG LMSDEB=http://downloads.slimdevices.com/LogitechMediaServer_v7.9.0/logitechmediaserver_7.9.0_all.deb
RUN curl -o /tmp/lms.deb $LMSDEB && \
    dpkg -i /tmp/lms.deb && \
    rm -f  /tmp/lms.deb

ENV LANG=de_DE.UTF-8
RUN echo "de_DE.UTF-8 UTF-8" > /etc/locale.gen && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && \
    echo LANG=\"de_DE.UTF-8\" > /etc/default/locale

# Move config dir to allow editing convert.conf, use a fixed UID to share externally
RUN adduser --uid $PUID --gid $GROUP --shell /bin/sh --home $USER && \
    mkdir -p /mnt/state/etc && \
    mv /etc/squeezeboxserver /etc/squeezeboxserver.orig && \
    cp -pr /etc/squeezeboxserver.orig/* /mnt/state/etc && \
    ln -s /mnt/state/etc /etc/squeezeboxserver && \
    chown -R $USER.$GROUP /mnt/state

COPY lms-setup.sh startup.sh /

VOLUME ["/mnt/state","/mnt/music","/mnt/playlists"]

EXPOSE 3483 3483/udp 9000 9005 9010 9090 5353 5353/udp CMD ["/startup.sh"]
