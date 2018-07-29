#!/usr/bin/env bash

containerNames="docker ps -qa
                              -f name=360f_mariadb_1
                              -f name=360f_suitecrm_1
"
sh="docker rm -f \$($containerNames)"
echo "$sh"
eval "$sh"

# docker rm -f \$(docker ps -qa) #remove all when needed
