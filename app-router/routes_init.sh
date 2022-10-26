#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x

if [ "${DEF_IF_NAME}" == "" ]; then
    export DEF_IF_NAME=$(ip -4 route list | grep default | cut -d\  -f5)
fi

export DEF_IF_GATEWAY_ORIGINAL=$(ip route show 0.0.0.0/0 dev "${DEF_IF_NAME}" | cut -d\  -f3)
if [ "${DEF_IF_GATEWAY}" == "" ]; then
    export DEF_IF_GATEWAY="${DEF_IF_GATEWAY_ORIGINAL}"	
elif [ "${DEF_IF_GATEWAY}" != "${DEF_IF_GATEWAY_ORIGINAL}" ]; then	
	echo "Changing default gateway from ${DEF_IF_GATEWAY_ORIGINAL} to ${DEF_IF_GATEWAY}";	
	route delete default gw "${DEF_IF_GATEWAY_ORIGINAL}" "${DEF_IF_NAME}"; 
	route add default gw "${DEF_IF_GATEWAY}" "${DEF_IF_NAME}";
fi

#lo forzo perchè altrimenti mi ritrovo il search del dominio, che dopo la connessione della vpn non va piu internet!
if [ "$USE_GOOGLE_DNS_IF_NEED" != 'false' ] && [ "${DNS_ADDRESS}x" == "x" ] ; then
    if grep -q "search " "/etc/resolv.conf"; then
        export DNS_ADDRESS="8.8.8.8, 8.8.4.4"
    fi
fi

if [ "${DNS_ADDRESS}x" != "x" ]; then
    echo "Setting nameserver ${DNS_ADDRESS} for /etc/resolv.conf"
	cp /etc/resolv.conf /etc/resolv.conf.bak
	
	echo nameserver 127.0.0.11 > /etc/resolv.conf

	ITEMS=$(echo $DNS_ADDRESS | tr "," "\n")
    for U in $ITEMS; do
        _ITEM=$(echo "${U}" | xargs)
		if [ "${_ITEM}x" != "x" ]; then
			echo "nameserver ${_ITEM}" >> /etc/resolv.conf
		fi
    done
	
	echo options ndots:0 >> /etc/resolv.conf
	cat /etc/resolv.conf
fi

#permetto il traffico dalla vpn all'host
if [ "${DEF_IF_ALLOW_ROUTING}" != "false" ]; then
    echo ">> Add iptables rule MASQUERADE for interface ${DEF_IF_NAME} (DEF_IF_ALLOW_ROUTING)" 
	#type iptables >/dev/null 2>&1 || { echo >&2 "I require iptables but it's not installed. Installing it."; apt update && apt install iptables -y && apt clean; }	
    iptables -t nat -A POSTROUTING -o "${DEF_IF_NAME}" -j MASQUERADE
fi

if [ "${DEFAULT_ROUTES}" == "" ]; then
    if [ "${PORT_FORWARD_HOST}" != "" ]; then
        HOST_ROUTES="${PORT_FORWARD_HOST}/32"
    fi
fi

#dopo la connessione alla vpn non c'è la route per il 192.168.99.0, quindi aggiungo le routes al gateway
if [ -n "${DEFAULT_ROUTES}" ]; then
    ROUTES=$(echo $DEFAULT_ROUTES | tr "," "\n")
    for U in $ROUTES; do
        _ROUTE=$(echo "${U}" | xargs)
        echo ">> Add route $_ROUTE on gw ${DEF_IF_GATEWAY}"
        route add -net "${_ROUTE}" gw "${DEF_IF_GATEWAY}"
    done
fi

if [ "${PORT_FORWARD_HOST}" == "" ]; then
    PORT_FORWARD_HOST="${DEF_IF_GATEWAY}"
fi

if [ -n "${PORT_FORWARD_PORTS}" ]; then
	#type iptables >/dev/null 2>&1 || { echo >&2 "I require iptables but it's not installed. Installing it."; apt update && apt install iptables -y && apt clean; }
    PORTS=$(echo $PORT_FORWARD_PORTS | tr "," "\n")
    for U in $PORTS; do
        HOST="${PORT_FORWARD_HOST}"
        PORT=$(echo "${U}" | xargs)
        LOCAL_PORT="${PORT}"
        oIFS="$IFS"; IFS=':'; arrStr=($PORT); IFS="$oIFS"; unset oIFS;
        if  [ "${#arrStr[@]}" == "2" ]; then
            HOST="${arrStr[0]}"
            PORT="${arrStr[1]}"
            LOCAL_PORT="${arrStr[1]}"
			
			if [[ "${arrStr[0]}" =~ ^[0-9]+$ ]] && [[ "${arrStr[1]}" =~ ^[0-9]+$ ]] ; then #if passed 80:81
				LOCAL_PORT="${arrStr[0]}"
				HOST="${PORT_FORWARD_HOST}"
				PORT="${arrStr[1]}"
			elif [[ "${arrStr[1]}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "${arrStr[0]}" =~ ^[0-9]+$ ]]; then #if passed 80:192.168.0.1
				LOCAL_PORT="${arrStr[0]}"
				HOST="${arrStr[1]}"
				PORT="${arrStr[0]}"
			fi				
        fi
        if  [ "${#arrStr[@]}" == "3" ]; then
            LOCAL_PORT="${arrStr[0]}"
            HOST="${arrStr[1]}"
            PORT="${arrStr[2]}"
        fi
		if  [ "${HOST}" == "" ]; then
            HOST="${PORT_FORWARD_HOST}"
        fi
		if  [ "${LOCAL_PORT}" == "" ]; then
            LOCAL_PORT="${PORT}"
        fi
		if  [ "${PORT}" == "" ]; then
            PORT="${LOCAL_PORT}"
        fi        
		if  [ "${PORT}" != "" ]; then
			echo ">> Add port forward from ${LOCAL_PORT} to ${HOST}:${PORT}"
			iptables -A PREROUTING -t nat -p tcp --dport "${LOCAL_PORT}" -j DNAT --to "${HOST}:${PORT}"
			iptables -A PREROUTING -t nat -p udp --dport "${LOCAL_PORT}" -j DNAT --to "${HOST}:${PORT}"
			iptables -A FORWARD -p tcp -d "${HOST}" --dport "${PORT}" -j ACCEPT
			iptables -A FORWARD -p udp -d "${HOST}" --dport "${PORT}" -j ACCEPT            
        fi
    done
fi
