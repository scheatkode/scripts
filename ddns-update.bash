#!/usr/bin/env bash

# TODO:
#  - documentation and in-code presentation
#  - better argument handling
#  - add option to provide custom ip address

# -- ENCODING -----------------------------------------------------------------

# TODO: documentation

__ye_olde_lc_collate="${LC_COLLATE}" ; LC_COLLATE='C'
trap 'LC_COLLATE="${__ye_olde_lc_collate}"' EXIT INT TERM

# -- COLORS -------------------------------------------------------------------

readonly     RED='\e[31m'
readonly   GREEN='\e[32m'
readonly  YELLOW='\e[33m'
readonly    BLUE='\e[34m'
readonly MAGENTA='\e[35m'
readonly    CYAN='\e[36m'
readonly  NORMAL='\e[0m'

# -- USER INPUT ---------------------------------------------------------------

# TODO:
#  - documentation
#  - better argument parsing

username="${DDNS_USERNAME:-/run/secrets/ddns_username}"
password="${DDNS_PASSWORD:-/run/secrets/ddns_password}"
hostname="${DDNS_HOSTNAME:-/run/secrets/ddns_hostname}"
protocol="${DDNS_PROTOCOL:-/run/secrets/ddns_protocol}"
provider="${DDNS_PROVIDER:-/run/secrets/ddns_provider}"
endpoint="${DDNS_ENDPOINT:-/run/secrets/ddns_endpoint}"
loglevel="${DDNS_LOGLEVEL:-/run/secrets/ddns_loglevel}"

while [ "$#" -gt 0 ] ; do
    case "${1}" in
                       --username|-u) username="${2}" ; shift ;;
                       --password|-p) password="${2}" ; shift ;;
                       --hostname|-h) hostname="${2}" ; shift ;;
                       --protocol|-t) protocol="${2}" ; shift ;;
                       --provider|-P) provider="${2}" ; shift ;;
              --endpoint|--api|-e|-a) endpoint="${2}" ; shift ;;
        --loglevel|--log-level|-l|-v) loglevel="${2}" ; shift ;;

                           --username=*|-u=*) username="${1#*=}" ;;
                           --password=*|-p=*) password="${1#*=}" ;;
                           --hostname=*|-h=*) hostname="${1#*=}" ;;
                           --protocol=*|-t=*) protocol="${1#*=}" ;;
                           --provider=*|-P=*) provider="${1#*=}" ;;
              --endpoint=*|--api=*|-e=*|-a=*) endpoint="${1#*=}" ;;
        --loglevel=*|--log-level=*|-l=*|-v=*) loglevel="${1#*=}" ;;
        *) printf '%s[FAIL]%s  %s' "${RED}" "${NORMAL}" \
            "'${1}' is not a valid argument"
        ;;
    esac
    shift
done

# -- LOGGING CAPABILITY -------------------------------------------------------

# TODO: documentation

define_logging_functions () {
    local loglevel="${1}"

    if [ x"${loglevel}" = x'info' ] ; then
        good () { printf "%s[ ok ]%s\n"    "${GREEN}"  "${NORMAL}"        ; }
        info () { printf '%s[info]%s %s'   "${CYAN}"   "${NORMAL}" "${@}" ; }
        warn () { printf "%s[warn]%s %s\n" "${YELLOW}" "${NORMAL}" "${@}" ; }
    elif [ x"${loglevel}" = x'warn' ] ; then
        good () { : noop ; }
        info () { : noop ; }
        warn () { printf "%s[warn]%s %s\n" "${YELLOW}" "${NORMAL}" "${@}" ; }
    else # fall back to error log level
        : TODO
    fi
}

fail () { printf '%s[fail]%s %s' "${RED}" "${NORMAL}" "${@}" ; }

# -- DEPENDENCY CHECK ---------------------------------------------------------

# TODO: documentation
# early check for dependencies

check_dependency () {
    if   command -v curl > /dev/null 2>&1 ; then
        cmd='curl'
    elif command -v wget > /dev/null 2>&1 ; then
        cmd='wget'
    else
        fail 'This script requires at least curl or wget'
    fi
}

# -- HELPER FUNCTIONS --------------------------------------------------------

validate_username () { "${@}" =~ '^.{2,}$' ; }
validate_password () { "${@}" =~ '^.{2,}$' ; }
validate_hostname () { "${@}" =~ '^(([:alnum:]|[:alnum:][[:alnum:]-]*[:alnum:])\.)*([:alnum:]|[:alnum:][[:alnum:]-]*[:alnum:])$' ; }
validate_provider () { "${@}" =~ '^(([:alnum:]|[:alnum:][[:alnum:]-]*[:alnum:])\.)*([:alnum:]|[:alnum:][[:alnum:]-]*[:alnum:])$' ; }
validate_protocol () { "${@}" =~ '^(http|https)$' ; }
validate_endpoint () { "${@}" =~ '^(\/\w+)+\.\w+(\?(\w+=[\w\d]+(&\w+=[\w\d]+)+)+)*$' ; }

check_connectivity () { ping -qc 1 -W 1 "${@}" > /dev/null 2>&1 ; }

urlencode () {
    local string="${1}"
    local length=${#1}
    local retval=''
    local character
    local counter

    for (( counter = 0 ; counter < length ; counter ++ )) ; do
        character="${string:$counter:1}"

        case "${character}" in
            [^[:alnum:]~._-]) character="$(printf '%%%02x' "'${character}")" ;;
        esac

        retval+="${character}"
    done

    printf '%s' "${retval}"
}

get_address_provider () {
    local provider=''

    if   connectivity_check 'ifconfig.me'               ; then
        provider='ifconfig.me/ip'
    elif connectivity_check 'ifconfig.co'               ; then
        provider='ifconfig.co/ip'
    elif connectivity_check 'ifconfig.io'               ; then
        provider='ifconfig.io/ip'
    elif connectivity_check 'wtfismyip.com'             ; then
        provider='wtfismyip.com/text'
    elif connectivity_check 'ipecho.net'                ; then
        provider='ipecho.net/plain'
    elif connectivity_check 'wgetip.com'                ; then
        provider='wgetip.com'
    elif connectivity_check 'ifcfg.me'                  ; then
        provider='ifcfg.me'
    elif connectivity_check 'icanhazip.com'             ; then
        provider='icanhazip.com'
    elif connectivity_check 'eth0.me'                   ; then
        provider='eth0.me'
    elif connectivity_check 'bot.whatismyipaddress.com' ; then
        provider='bot.whatismyipaddress.com'
    elif connectivity_check 'domains.google.com'        ; then
        provider='domains.google.com/checkip'
    elif connectivity_check 'whatismyip.akamai.com'     ; then
        provider='whatismyip.akamai.com'
    else
        fail "Couldn't reach any of the IP providers, check your connectivity"
    fi

    printf '%s' "${provider}"
}

get_address_public () {
    local command="${1}"
    local provider="${2}"
    local address=''

    case "${cmd}" in
        curl) address="$(curl -s   "https://${provider}")";;
        wget) address="$(wget -qO- "https://${provider}")";;
    esac

    printf '%s' "${address}"
}


#   Let's not make  this overcomplicated with dependency checking,  it can quickly
#   turn to hell  with weird hacks and  the bells and whistles that  come with it.
#   `ping` resolves domain names automatically  using whatever's configured on the
#   system.  We take  advantage  of that  in  the below  function  to resolve  the
#   hostname.
#
#   We also use a double `cut` to  avoid messing with non greedy regexes on `sed`,
#   `awk` and the  such. We only suggested  those because they come  with the base
#   system.

get_address_registered () {
    local hostname="${1}"
    local address="$(
    ping -qc 1 -t 1 "${hostname}" \
        | grep -m 1 PING          \
        | cut -d'(' -f2           \
        | cut -d')' -f1
    )"

    printf '%s' "${address}"
}

# -- DDNS PROVIDERS ----------------------------------------------------------

# TODO: documentation

update_ddns_google () {
    local      cmd="${1}"
    local  address="${2}"
    local username="${3}"
    local password="${4}"
    local hostname="${5}"
    local provider="${6}"
    local protocol="${7}"
    local endpoint="${8}"

    case "${cmd}" in
        curl) response="$(
            curl --silent                                   \
                 --data-urlencode "hostname=${hostname}"    \
                 --data-urlencode "myip=${address}"         \
                 --header         "Host: ${provider}"       \
                 --user           "${username}:${password}" \
                 "${protocol}://${provider}/${endpoint}"
            )" ;;
        wget) response="$(
            wget --quiet --output -                               \
                --post-data "$(urlencode "hostname=${hostname}")" \
                --post-data "$(urlencode "myip=${address}")"      \
                --header    "Host: ${provider}"                   \
                --user      "${username}"                         \
                --password  "${password}"                         \
                "${protocol}://${provider}/${endpoint}"
            )" ;;
    esac

    case "${response}" in
          *good*) echo 'The update was successful'                                    ;;
         *nochg*) echo 'The IP address is already set for this host'                  ;;
        *nohost*) fail "The hostname doesn't exist or doesn't have DDNS enabled"      ;;
       *badauth*) fail 'The username/password combination is not valid'               ;;
       *notfqdn*) fail 'The hostname is not a valid fully qualified domain name'      ;;
      *badagent*) fail 'The client is making bad requests ?'                          ;;
         *abuse*) fail 'DDNS has been blocked for this host due to previous failures' ;;
           *911*) fail 'Google encountered an internal error'                         ;;
       *conflict) fail 'A custom record conflicts with the update'                    ;;
    esac
}

update_ddns_afraid () {
    : TODO
}

update_ddns_noip () {
    : TODO
}


# TODO: reorder script inputs and function definitions

