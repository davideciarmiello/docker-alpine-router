#!/bin/bash

#set -e
set -a # Enable allexport using single letter syntax

[ "$DEBUG" == 'true' ] && set -x

find /app-router -type f ! -executable -iname "*.sh" -exec chmod +x {} \;

/app-router/routes_init.sh 1> >(sed "s/^/[ROUTES] /") 2> >(sed "s/^/[ROUTES] /" >&2)

/app-router/external-entrypoints.sh "/etc/entrypoint.d/"


#https://stackoverflow.com/questions/2005192/how-to-execute-a-bash-command-stored-as-a-string-with-quotes-and-asterisk
#i parametri del cmd arrivano come array, per testare si può fare :  cmd=(sh -c 'echo 1; sleep 5'); "${cmd[@]}"
#echo "P1: $1 - P2: $2 - P3: $3"

#https://superuser.com/questions/1459466/can-i-add-an-additional-docker-entrypoint-script
#echo "CMD SOURCE PARAM: ${CALL_CMD} - Params: $@"
if [ -n "${CALL_ENTRYPOINT}" ] && [ -n "$1" ]; then
    echo "Start with eval ENTRYPOINT: ${CALL_ENTRYPOINT} - Default CMD: ${@}"
	echo ""
	eval "${CALL_ENTRYPOINT}" $@
	#"${CALL_ENTRYPOINT} ${@}"
elif [ -n "${CALL_ENTRYPOINT}" ]; then
    echo "Start with eval ENTRYPOINT: ${CALL_ENTRYPOINT} - CMD: ${CALL_CMD}"
	echo ""
	eval "${CALL_ENTRYPOINT}" "${CALL_CMD}"
elif [[ -n "$1" ]]; then
    echo "Start with exec Default CMD: $@"
	echo ""
	"${@}"
elif [[ -n "${CALL_CMD}" ]]; then
    echo "Start with exec CMD: ${CALL_CMD}"
	echo ""
	exec "${CALL_CMD}"
elif [ "${WAIT_INFINITY}" != "false" ]; then
    echo "starting sleep infinity..."
	echo ""
	trap exit INT TERM; while true; do sleep infinity & wait; done;
fi

