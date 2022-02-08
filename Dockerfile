# Jackett, OpenVPN and WireGuard, JackettVPN
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND noninteractive
ENV XDG_DATA_HOME="/config" \
XDG_CONFIG_HOME="/config"

WORKDIR /opt

RUN usermod -u 99 nobody

# Make directories
RUN mkdir -p /blackhole /config/Jackett /etc/jackett

# Download Jackett
RUN apt update \
    && apt upgrade -y \
    && apt install -y  --no-install-recommends \
    ca-certificates \
    curl \
    && JACKETT_VERSION=$(curl -sX GET "https://api.github.com/repos/Jackett/Jackett/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
    && curl -o /opt/Jackett.Binaries.LinuxAMDx64.tar.gz -L "https://github.com/Jackett/Jackett/releases/download/${JACKETT_VERSION}/Jackett.Binaries.LinuxAMDx64.tar.gz" \
    && tar -xzf /opt/Jackett.Binaries.LinuxAMDx64.tar.gz -C /opt \
    && rm -f /opt/Jackett.Binaries.LinuxAMDx64.tar.gz \ 
    && apt purge -y \
    ca-certificates \
    curl \
    && apt-get clean \
    && apt autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Install WireGuard and other dependencies some of the scripts in the container rely on.
RUN echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable-wireguard.list \
    && printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' > /etc/apt/preferences.d/limit-unstable \
    && apt update \
    && apt install -y --no-install-recommends \
    ca-certificates \
    dos2unix \
    inetutils-ping \
    ipcalc \
    iptables \
    jq \
    kmod \
    libicu67 \
    moreutils \
    net-tools \
    openresolv \
    openvpn \
    procps \
    wireguard-tools \
    && apt-get clean \
    && apt autoremove -y \
    && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

VOLUME /blackhole /config

ADD openvpn/ /etc/openvpn/
ADD jackett/ /etc/jackett/

RUN chmod +x /etc/jackett/*.sh /etc/jackett/*.init /etc/openvpn/*.sh /opt/Jackett/jackett

EXPOSE 9117
CMD ["/bin/bash", "/etc/openvpn/start.sh"]
