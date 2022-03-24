#/bin/sh

set -eu

if ! test "${EUID}" -eq 0
then
   echo "This script alters your networking environment and should be run with root privileges"
   exit 13 # EACCESS
fi

has () { command -v "${1}" > /dev/null 2>&1 ; }

if ! has ip || ! has tc
then
   printf "This script requires the iproute2 package to be installed"
   exit 65 # ENOPKG
fi

# default speed in case it was not given.
DEFAULT_SPEED="500kbps"

# find the default network device using the routing table.
DEFAULT_DEVICE="$(ip route show default | sed -e 's/^.*dev.//' -e 's/.proto.*//')"

enable_traffic_shaping () {
   DEVICE="${1-${DEFAULT_DEVICE}}"
   SPEED="${2-${DEFAULT_SPEED}}"

   # linux does not support shaping on `ingress`, so we have  to
   # redirect ingress traffic to `ifb`  device  then  shape  the
   # traffic of its egress queue.

   if test -z "$(lsmod | grep ifb)" ; then
      modprobe ifb
   fi

   if test -z "$(ip link | grep ifb0)" ; then
      ip link add name ifb0 type ifb
      ip link set dev  ifb0 up
   fi

   tc qdisc  add dev ifb0 root handle 1: htb r2q 1
   tc class  add dev ifb0 parent      1: classid 1:1 htb rate "${SPEED}"
   tc filter add dev ifb0 parent      1: matchall flowid 1:1

   tc qdisc  add dev "${DEVICE}" ingress
   tc filter add dev "${DEVICE}" ingress matchall action mirred egress redirect dev ifb0

   printf 'Limit of %s set on %s\n' "${SPEED}" "${DEVICE}"
}

disable_traffic_shaping () {
   DEVICE="${1-${DEFAULT_DEVICE}}"

   tc qdisc del dev "${DEVICE}" ingress
   tc qdisc del dev ifb0        root

   printf 'Limit removed.\n'
}

usage () {
   cat <<EOF

   Usage: ${0} <command> [options]

   Commands:
      enable               Enable rate limiting
      disable              Disable rate limiting

   Options:
      speed <speed>        Speed at which to limit the bandwhidth
      dev   <interface>    Interface to enable/disable rate limiting on

EOF
}

main () {
   action="usage"
   options=""

   if [ ${#} -eq 0 ]
   then
      usage ; return
   fi

   case "${1}" in
      enable)
         action='enable_traffic_shaping'
         ;;
      disable)
         action="disable_traffic_shaping"
         ;;
      *)
         usage
         return
         ;;
   esac

   shift

   while [ ${#} -gt 0 ]
   do
      case "${1}" in
         speed|bandwidth)
            options="${options} ${2}"
            ;;
         dev)
            options="${options} ${2}"
            ;;
      esac

      shift
      shift
   done

   ${action} ${options}
}

main ${*}
