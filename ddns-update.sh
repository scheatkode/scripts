#!/bin/sh
#   shellcheck disable=2006

#   Google  Domains provides  a simple  to use  API to  update a  dynamic DNS
#   record, "Synthetic record" in Google  terms. This script updates a record
#   with the machine's public IP address.
#
#   This script  is also specifically  intended towards Google's  dynamic DNS
#   API but most of the groundwork  has been laid for further enhancement and
#   general use.
#
#   Google Dynamic DNS: https://support.google.com/domains/answer/6147083
#   Synthetic Records : https://support.google.com/domains/answer/6067273

# -- COLORS -------------------------------------------------------------------

    RED='\e[31m'
  GREEN='\e[32m'
 YELLOW='\e[33m'
   BLUE='\e[34m'
MAGENTA='\e[35m'
   CYAN='\e[36m'
 NORMAL='\e[0m'

# -- DDNS PROVIDERS -----------------------------------------------------------

google () {
    case "${cmd}" in
        curl) response="$(
            curl --silent
                 --data-urlencode "hostname=${hostname}"
                 --data-urlencode "myip=${address}"
                 --header         "Host: ${provider}"
                 --user           "${username}:${password}"
                 "${protocol}://${provider}/${endpoint}"
            )" ;;

        wget) response="$(
            wget --quiet --output -
                 --user      "${username}"
                 --password  "${password}"
                 --post-data "$(urlencode "hostname=${hostname}")"
                 --post-data "$(urlencode "myip=${address}")"
                 --header    "Host: ${provider}"
                 "${protocol}://${provider}/${endpoint}"
            )" ;;
    esac

    case "${response}" in
          *good*) echo 'The update was successful' ;;
         *nochg*) echo 'The IP address is already set for this host' ;;
        *nohost*) fail "The hostname doesn't exist or doesn't have DDNS enabled" ;;
       *badauth*) fail 'The username/password combination is not valid';;
       *notfqdn*) fail 'The hostname is not a valid fully qualified domain name';;
      *badagent*) fail 'The client is making bad requests ?' ;;
         *abuse*) fail 'DDNS has been blocked for this host due to previous failures' ;;
           *911*) fail 'Google encountered an internal error' ;;
       *conflict) fail 'A custom record conflicts with the update' ;;
    esac
}

afraid () {
    # TODO
}

noip () {
    # TODO
}

# -- DEPENDENCY CHECK ---------------------------------------------------------

info 'Checking dependencies'

    if   command -v curl > /dev/null 2>&1 ; then
        cmd='curl'
    elif command -v wget > /dev/null 2>&1 ; then
        cmd='wget'
    else
        fail 'This script requires at least curl or wget'
    fi

success

# -- USER INPUT ---------------------------------------------------------------

username="${DDNS_USERNAME:-/run/secrets/ddns_username}"
password="${DDNS_PASSWORD:-/run/secrets/ddns_password}"
hostname="${DDNS_HOSTNAME:-/run/secrets/ddns_hostname}"

protocol="${DDNS_PROTOCOL:-/run/secrets/ddns_protocol}"
provider="${DDNS_PROVIDER:-/run/secrets/ddns_provider}"
endpoint="${DDNS_ENDPOINT:-/run/secrets/ddns_endpoint}"

info 'Figuring out secrets'

while [ "$#" -gt 0 ] ; do
    case "${1}" in
        --username|-u)     username="${2}" ; shift ; shift ;;
        --password|-p)     password="${2}" ; shift ; shift ;;
        --hostname|-h)     hostname="${2}" ; shift ; shift ;;
        --protocol|-t)     protocol="${2}" ; shift ; shift ;;
        --provider|-P)     provider="${2}" ; shift ; shift ;;
        --endpoint|-e)     endpoint="${2}" ; shift ; shift ;;
        --verbose|-v)       verbose="true"         ; shift ;;
        --username=*|-u=*) username="${1#*=}" ; shift ;;
        --password=*|-p=*) password="${1#*=}" ; shift ;;
        --hostname=*|-h=*) hostname="${1#*=}" ; shift ;;
        --protocol=*|-t=*) protocol="${1#*=}" ; shift ;;
        --provider=*|-P=*) provider="${1#*=}" ; shift ;;
        --endpoint=*|-e=*) endpoint="${1#*=}" ; shift ;;
        *) fail "'${1}' is not a valid argument" ;;
    esac
done

for var in 'username' \
           'password' \
           'hostname' \
           'protocol' \
           'provider' \
           'endpoint'
do
    if [ -e "$(eval echo "\$\{${var}\}")" ] ; then
        eval "${var}=\"$(cat "${var}")\"" \
        || fail "Cannot read ${var} secret file"
    fi
done

success

# -- HELPER FUNCTIONS ---------------------------------------------------------

if [ x"${verbose}" = x"true" ] ; then
    info     () { echo -en    "${CYAN}[INFO]${NORMAL} " "${@}" ; }
    infoline () { echo -e     "${CYAN}[INFO]${NORMAL} " "${@}" ; }
    warn     () { echo -e   "${YELLOW}[WARN]${NORMAL} " "${@}" ; }
    success  () { echo -e  "\r${GREEN}[ OK ]${NORMAL}"         ; }
else
    info     () { :; }
    infoline () { :; }
    warn     () { :; }
    success  () { :; }
fi

fail () { echo -e "\r${RED}[FAIL]${NORMAL} " "${@}" ; exit 1 ; }

validate_username () { echo "${@}" | grep -q '^.\{2,\}$' ; }
validate_password () { echo "${@}" | grep -q '^.\{2,\}$' ; }
validate_hostname () { echo "${@}" | grep -q '^\(\([a-zA-Z0-9]\|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9]\)\.\)*\([A-Za-z0-9]\|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9]\)$' ; }
validate_provider () { validate_hostname "${@}" ; }
validate_protocol () { echo "${@}" | grep -q '^\(http\|https\)$' ; }
validate_endpoint () { echo "${@}" | grep -q '^\([a-zA-Z0-9/_-]\{1,\}\)' ; }

connectivity_check () { ping -qc 1 -W 1 "${@}" > /dev/null 2>&1 ; }

# TODO: How in the absolute FUCKING HELL did you manage to work this out ? u.u
#       Okay, at least make sure it's functioning and there are no bad
#       surprises.

urlencode () {
    __ye_olde_lc_collate="${LC_COLLATE:-C}"
    LC_COLLATE='C'

    for i in $(seq 1 ${#1}) ; do
        character="$(expr substr "${1}" "${i}" 1)"
        if echo "${character}" | grep --quiet '[a-zA-Z0-9.~_-]' ; then
            printf "%s" "${character}"
        else
            printf '%%%02X' "'${character}"
        fi
    done

    LC_COLLATE="${__ye_olde_lc_collate}"
}

# -- INPUT VALIDATION ---------------------------------------------------------

info 'Validating input'

if ! validate_username "${username}" ; then fail 'Invalid username       ' ; fi
if ! validate_password "${password}" ; then fail 'Invalid password       ' ; fi
if ! validate_hostname "${hostname}" ; then fail 'Invalid hostname       ' ; fi
if ! validate_protocol "${protocol}" ; then fail 'Invalid protocol       ' ; fi
if ! validate_provider "${provider}" ; then fail 'Invalid provider       ' ; fi
if ! validate_endpoint "${endpoint}" ; then fail 'Invalid endpoint       ' ; fi

success

# -- PUBLIC IP RETRIEVAL ------------------------------------------------------

info 'Looking for a working public IP address provider'

if   connectivity_check 'ifconfig.me'               ; then
    address_provider='ifconfig.me/ip'
elif connectivity_check 'ifconfig.co'               ; then
    address_provider='ifconfig.co/ip'
elif connectivity_check 'ifconfig.io'               ; then
    address_provider='ifconfig.io/ip'
elif connectivity_check 'wtfismyip.com'             ; then
    address_provider='wtfismyip.com/text'
elif connectivity_check 'ipecho.net'                ; then
    address_provider='ipecho.net/plain'
elif connectivity_check 'wgetip.com'                ; then
    address_provider='wgetip.com'
elif connectivity_check 'ifcfg.me'                  ; then
    address_provider='ifcfg.me'
elif connectivity_check 'icanhazip.com'             ; then
    address_provider='icanhazip.com'
elif connectivity_check 'eth0.me'                   ; then
    address_provider='eth0.me'
elif connectivity_check 'bot.whatismyipaddress.com' ; then
    address_provider='bot.whatismyipaddress.com'
elif connectivity_check 'domains.google.com'        ; then
    address_provider='domains.google.com/checkip'
elif connectivity_check 'whatismyip.akamai.com'     ; then
    address_provider='whatismyip.akamai.com'
else
    fail "Couldn't reach any of the IP providers, check your connectivity"
fi

echo -n " => ${address_provider}"

success

info 'Getting public IP address'

case "${cmd}" in
    curl) address="$(curl -s   "${protocol}://${address_provider}")" ;;
    wget) address="$(wget -qO- "${protocol}://${address_provider}")" ;;
esac

echo -n " => ${address}"

success

# TODO: check if address is already recorded before trying to update.
#       this is to avoid any unnacessary problems, especially with google.
# UPDATE: too many dependencies, just use ping to resolve using whatever's
#         available on the system, also write something about assuming ddns
#         usually works with a single ip address, hence the use of ping
#         instead of something else like `dig` or `host`

# -- UPDATE DNS RECORD --------------------------------------------------------

info 'Updating dynamic DNS record'

case "${provider}" in
    freedns.afraid.org|sync.afraid.org|afraid) message="$(afraid)" ;;
      domains.google.com|domain.google|google) message="$(google)" ;;
esac

success ; echo "${message}"

# XXX: might turn this into a bash script since it's quickly getting out of
#      hand.
#      also the hacks used throughout here are making the whole process really
#      slow.
#      to make things handier and more swift, it can be useful to accept
#      multiple hostnames to update; this is easily done with space separated
#      strings in posix shell but again, posix shell isn't the most performant
#      of shells and this script is supposed to run multiple times.

