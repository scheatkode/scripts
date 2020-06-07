#!/bin/sh
# shellcheck disable=2005
# shellcheck disable=2006

#   Provide GeoIP info.
#
#   Prints GeoIP information of the given  ip address or domain name. If
#   none are provided, returns information about the source ip address.
#
#   Dependencies :
#       - curl | wget
#
#   Usage :
#       - geoip.sh [ip-address|domain-name]

__cmd=''
__ip_address=''

if   command -v curl > /dev/null 2>&1 ; then
    __cmd='curl --silent '
elif command -v wget > /dev/null 2>&1 ; then
    __cmd='wget -qO- '
else
    __RED='\033[0;31m'
    __NOF='\033[0m'

    echo "${__RED}Neither \`curl\` nor \`wget\` are installed.${__NOF}"

    unset __cmd
    unset __RED
    unset __NOF

    exit 1
fi

if [ ! -z "${1+x}" ] ; then
    __ip_address="`
        ping -c 1 ${1} |
        head -1                          |
        tail -1                          |
        cut -d' ' -f 3                   |
        sed 's/[(:)]//g'
    `"
fi

echo "`${__cmd} \"ipinfo.io/${__ip_address+ }\"`"

unset __cmd
unset __ip_address

