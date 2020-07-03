#!/bin/sh

# -- CONSTANTS ----------------------------------------------------------------

    RED='\e[31m'
  GREEN='\e[32m'
 YELLOW='\e[33m'
   BLUE='\e[34m'
MAGENTA='\e[35m'
   CYAN='\e[36m'
 NORMAL='\e[0m'

IMAGENAME='kylemanna/openvpn'

# -- HELPER FUNCTIONS ---------------------------------------------------------

fail () { echo -e "${RED}${2}${NORMAL}"     ; exit ${1} ; }
warn () { echo -e "${MAGENTA}${1}${NORMAL}" ;             }
log  () { echo -e "${BLUE}${1}${NORMAL}"    ;             }

# -- DEPENDENCY CHECK ---------------------------------------------------------

if   command -v docker > /dev/null 2>&1 ; then runtime='docker'
elif command -v podman > /dev/null 2>&1 ; then runtime='podman'
else fail 65 'This script requires either docker or podman'
fi

# -- HELPER FUNCTIONS ---------------------------------------------------------

validate_servername () {
    echo ${1}    | \
        egrep -q '^(([[:alpha:]](-?[[:alnum:]])*)\.)+[[:alpha:]]{2,}$' \
    || echo ${1} | \
        egrep -q '^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$'
}

# -- USER INPUT ---------------------------------------------------------------

read -p 'Server name or IP    : ' servername
read -p 'Client name          : ' clientname
read -p 'Volume name [create] : ' volumename

if [ "x${volumename}" = 'x' ] ; then
    volumename="`${runtime} volume create`"
fi


log 'Pulling required container image'

${runtime} pull "${IMAGENAME}"


log 'Generating configuration'

${runtime} run --rm -it             \
    -v "${volumename}:/etc/openvpn" \
    --net=none                      \
    "${IMAGENAME}" ovpn_genconfig   \
    -u "udp://${servername}"        \
    -C 'AES-256-CBC'                \
    -a 'SHA384'                     \
    -b -d -D -N -z


log 'Generating certificates'

${runtime} run --rm -it             \
    -e EASYRSA_KEY_SIZE=4096        \
    -v "${volumename}:/etc/openvpn" \
    --net=none                      \
    "${IMAGENAME}" ovpn_initpki


log 'Generating client certificates'

${runtime} run --rm -it             \
    -e EASYRSA_KEY_SIZE=4096        \
    -v "${volumename}:/etc/openvpn" \
    --net=none                      \
    "${IMAGENAME}" easyrsa build-client-full "${clientname}"


log 'Retrieving client certificates'

${runtime} run --rm -it             \
    -e EASYRSA_KEY_SIZE=4096        \
    -v "${volumename}:/etc/openvpn" \
    --net=none                      \
    --log-driver=none               \
    "${IMAGENAME}" ovpn_getclient "${clientname}" > "${clientname}.ovpn"


log 'Launching server'

${runtime} run --rm -d              \
    -p 1194:1194/udp                \
    -v "${volumename}:/etc/openvpn" \
    --restart=always                \
    --cap-add=NET_ADMIN             \
    "${IMAGENAME}"

