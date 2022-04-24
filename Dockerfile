FROM ubuntu:latest

ARG CACHEBUST="1"
RUN echo "$CACHEBUST"
ARG CI=""

RUN apt-get update && \
    [ ! -n "$CI" ] && apt-get dist-upgrade -y || : && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential cron curl dnsutils dumb-init git jq openvpn psmisc python3.10-dev python3-pip

COPY regions /config/regions
COPY resolv.conf /config/resolv.conf
COPY run.sh /run.sh
COPY start.sh /start.sh
COPY crontab /etc/cron.d/ptndown-pia

ARG PIA_USER="**None**"
ARG PIA_PASS="**None**"

ENV PIA_USER=$PIA_USER \
    PIA_PASS=$PIA_PASS

RUN chmod 0644 /etc/cron.d/ptndown-pia && \
    crontab /etc/cron.d/ptndown-pia && \
    touch /var/log/cron.log

RUN echo 3

RUN git clone --branch 'ru-resolvers' --depth 1 https://github.com/FluxState/mhddos_proxy.git /opt/mhddos_proxy
RUN git clone --depth 1 https://github.com/pia-foss/manual-connections.git /opt/pia
RUN git clone --depth 1 https://github.com/FluxState/warlists.git /opt/warlists

RUN pip3 install -r /opt/mhddos_proxy/requirements.txt

RUN apt-get -y remove build-essential git python3.10-dev && \
    apt-get autoremove -y && apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/* /tmp/*

CMD ["dumb-init", "/start.sh"]
