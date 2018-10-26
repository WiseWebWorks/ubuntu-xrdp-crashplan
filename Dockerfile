FROM ubuntu:18.04
MAINTAINER Kevin Wise

# Install packages

ENV DEBIAN_FRONTEND noninteractive
ENV TZ America/Phoenix
RUN apt-get -y update && \
    apt-get -yy upgrade && \
    apt-get install -yy vim wget curl ca-certificates xorgxrdp xrdp \
    xfce4 xfce4-terminal xfce4-screenshooter xfce4-taskmanager \
    xfce4-clipman-plugin xfce4-cpugraph-plugin xfce4-netload-plugin \
    xfce4-xkb-plugin xauth supervisor uuid-runtime locales \
    firefox pepperflashplugin-nonfree openssh-server sudo \
    libgconf-2-4 cpio apt-utils
COPY bin /usr/bin
COPY etc /etc

# Configure
RUN mkdir /var/run/dbus && \
    cp /etc/X11/xrdp/xorg.conf /etc/X11 && \
    sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config && \
    sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini && \
    locale-gen en_US.UTF-8 && \
    echo "xfce4-session" > /etc/skel/.Xclients && \
    cp -r /etc/ssh /ssh_orig && \
    rm -rf /etc/ssh/* && \
    rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem

ADD etc/sysctl.d/crashplan-watches.conf /etc/sysctl.d

# Add user

RUN addgroup crashplan && \
    useradd -m -s /bin/bash -g crashplan crashplan && \
    echo "crashplan:${CRASHPLAN_PASSWORD:-crashplan}" | /usr/sbin/chpasswd && \
    echo "crashplan    ALL=(ALL) ALL" >> /etc/sudoers

# Crashplan

WORKDIR /tmp
RUN curl -# -L https://web-bbm-msp.crashplan.com/client/installers/CrashPlanSmb_6.8.3_1525200006683_951_Linux.tgz | tar -xz && \
    ./crashplan-install/install.sh --quiet && \
    rm -rf /tmp/*

# Docker config

VOLUME ["/etc/ssh","/home","/opt","/root","/usr/local/crashplan","/var/lib/crashplan","/var/log","/volume1","/volume2","/volume3","/volume4","/volume5"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]
