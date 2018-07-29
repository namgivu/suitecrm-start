#!/usr/bin/env bash
s=$BASH_SOURCE; s=$(dirname "$s") ; s=$(cd "$s" && pwd) ; SCRIPT_HOME="$s"

docker-compose -f "$SCRIPT_HOME/docker-compose.yml" \
               -p '360f'  up \
               -d \
               --force-recreate --remove-orphans
