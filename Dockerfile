FROM ubuntu:latest as builder

ARG CACHEBUST="1"
RUN echo "$CACHEBUST"
ARG CI=""

RUN apt update && \
    [ ! -n "$CI" ] && apt-get dist-upgrade -y || : && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl gcc-12 git make software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3.10 python3.10-dev python3.10-venv

RUN ls /usr/bin/ | grep -oP "([a-z0-9\-_]+)(gcc)(-[a-z]+)?" | xargs bash -c 'for link in ${@:1}; do ln -s -f "/usr/bin/${link}-${0}" "/usr/bin/${link}"; done' 12
RUN python3.10 -m venv /opt/venv/
ENV PATH="/opt/venv/bin:$PATH"

RUN git clone --depth 1 https://github.com/porthole-ascend-cinnamon/mhddos_proxy.git /opt/mhddos_proxy
RUN git clone --depth 1 https://github.com/pia-foss/manual-connections.git /opt/pia
RUN git clone --depth 1 https://github.com/FluxState/warlists.git /opt/warlists

WORKDIR /opt/mhddos_proxy

RUN python3.10 -m pip install --no-cache-dir -U pip wheel && \
    pip3.10 install --no-cache-dir -r requirements.txt


FROM ubuntu:latest as runner

ARG CACHEBUST="2"
RUN echo "$CACHEBUST"
ARG CI=""

RUN apt update && \
    [ ! -n "$CI" ] && apt-get dist-upgrade -y || : && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    cron curl dnsutils dumb-init jq ncal openvpn psmisc software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3.10

COPY hosts /config/hosts
COPY regions /config/regions
COPY resolv.conf /config/resolv.conf
COPY run.sh /run.sh
COPY start.sh /start.sh
COPY crontab /etc/cron.d/ptndown-pia

ARG PIA_USER="**None**"
ARG PIA_PASS="**None**"

ENV IS_DOCKER=1 \
    PATH="/opt/venv/bin:$PATH" \
    PIA_USER=$PIA_USER \
    PIA_PASS=$PIA_PASS

RUN chmod 0644 /etc/cron.d/ptndown-pia && \
    crontab /etc/cron.d/ptndown-pia && \
    touch /var/log/cron.log

RUN apt-get remove -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/* /tmp/*

COPY --from=builder /opt/mhddos_proxy/ opt/mhddos_proxy/
COPY --from=builder /opt/pia/ opt/pia/
COPY --from=builder /opt/venv/ opt/venv/
COPY --from=builder /opt/warlists/ opt/warlists/

CMD ["dumb-init", "/start.sh"]
