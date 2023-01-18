FROM ubuntu:latest as builder

ARG CACHEBUST=""
RUN echo "$CACHEBUST"
ARG CI=""

RUN apt update && \
    [ ! -n "$CI" ] && apt-get dist-upgrade -y || : && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl gcc-12 git make software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3.11 python3.11-dev python3.11-venv

RUN ls /usr/bin/ | grep -oP "([a-z0-9\-_]+)(gcc)(-[a-z]+)?" | xargs bash -c 'for link in ${@:1}; do ln -s -f "/usr/bin/${link}-${0}" "/usr/bin/${link}"; done' 12
RUN python3.11 -m venv /opt/venv/
ENV PATH="/opt/venv/bin:$PATH"

RUN git clone --branch 'local-resolvers' --depth 1 https://github.com/FluxState/mhddos_proxy.git /opt/mhddos_proxy
RUN git clone --depth 1 https://github.com/pia-foss/manual-connections.git /opt/pia
RUN git clone --depth 1 https://github.com/FluxState/warlists.git /opt/warlists

WORKDIR /opt/mhddos_proxy

RUN rm -rf .git

RUN python3.11 -m pip install --no-cache-dir -U pip wheel && \
    pip3.11 install --no-cache-dir -U -r requirements.txt


FROM ubuntu:latest as runner

ARG CACHEBUST=""
RUN echo "$CACHEBUST"
ARG CI=""

RUN apt update && \
    [ ! -n "$CI" ] && \
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y || : && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    cron curl dnsutils dumb-init git jq ncal openvpn psmisc software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3.11 && \
    apt-get remove -y software-properties-common && \
    apt-get autoremove -y && apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/* /tmp/*

COPY resolv.conf /config/resolv.conf
ADD regions /config/regions
ADD run.sh /run.sh
ADD start.sh /start.sh
ADD crontab /etc/cron.d/ptndown-pia

ARG PIA_USER="**None**"
ARG PIA_PASS="**None**"

ENV IS_DOCKER=1 \
    PATH="/opt/venv/bin:$PATH" \
    PIA_USER=$PIA_USER \
    PIA_PASS=$PIA_PASS

RUN chmod 0644 /etc/cron.d/ptndown-pia && \
    crontab /etc/cron.d/ptndown-pia && \
    touch /var/log/cron.log

COPY --from=builder /opt/mhddos_proxy/ opt/mhddos_proxy/
COPY --from=builder /opt/pia/ opt/pia/
COPY --from=builder /opt/venv/ opt/venv/
COPY --from=builder /opt/warlists/ opt/warlists/

ENTRYPOINT ["dumb-init", "--"]
CMD ["/start.sh"]
