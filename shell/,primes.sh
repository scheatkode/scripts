#!/bin/sh

set -u

if [ -n "${NO_COLOR+}" ] ; then
   readonly     RED='\e[31m'
   readonly  NORMAL='\e[0m'
else
   readonly     RED=''
   readonly  NORMAL=''
fi

log_error () { printf '%berror:%b %s\n' "${RED}" "${NORMAL}" "${@}" ; }

is_numeric () {
   case "${1#[+-]}" in
      (*[!0123456789]*) return 1 ;;
      ('')              return 1 ;;
      (*)               return 0 ;;
   esac
}

is_prime () {
   if [ "${1}" -le 1 ] ; then return 1 ; fi
   if [ "${1}" -le 3 ] ; then return 0 ; fi

   n="${1}"

   if [ $(( n % 2)) -eq 0 ] ; then return 1 ; fi
   if [ $(( n % 3)) -eq 0 ] ; then return 1 ; fi

   i=5

   while [ $(( i * i )) -le $n ] ; do
      if [ $(( n %  i ))      -eq 0 ] ; then return 1 ; fi
      if [ $(( n % (i + 2) )) -eq 0 ] ; then return 1 ; fi

      i=$(( i + 6 ))
   done

   return 0
}

generate_primes () {
   for n in $(seq "${1}" "${2}") ; do
      if is_prime $n ; then echo "   ${n}" ; fi
   done
}

main () {
   from=1
   to=100

   if [ -n "${1-}" ] ; then
      if ! is_numeric "${1}" ; then
         log_error "Invalid argument '${1}'"
         exit 1
      fi

      from="${1}"

      if [ -n "${2-}" ] ; then
         if ! is_numeric "${2}" ; then
            log_error "Invalid argument '${2}'"
            exit 1
         fi

         to="${2}"
      fi
   fi

   generate_primes "${from}" "${to}"
}

main "${@}"
