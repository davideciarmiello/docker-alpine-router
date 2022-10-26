#!/bin/bash

[ "$DEBUG" == 'true' ] && set -x

mkdir -p /etc/entrypoint.d
find /etc/entrypoint.d -type f ! -executable -iname "*.sh" -exec chmod +x {} \;

# Run scripts in /etc/entrypoint.d

find /etc/entrypoint.d/ -name "*.sh" -print0 | while read -d $'\0' f
do
    if [[ -x ${f} ]]; then
        echo ">> Running: ${f}"
        filename=$(basename -- "$f")
        filename="${filename%.*}"
        CMD_PFX="[$filename]"
        ${f} # > >(sed "s/^/$prefix: /") 2> >(sed "s/^/$prefix (err): /" >&2)
        #${f} 1> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g") 2> >(sed "/^\[.*\]/! s/^/$CMD_PFX /g" >&2)
    fi
done

