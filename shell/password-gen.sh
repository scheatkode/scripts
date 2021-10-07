#!/bin/sh

#   Generate a random string using different techniques.

LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 | head -c 65 && echo
date +%s | sha256sum | base64 | head -c 65 ; echo
openssl rand -base64 65
strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 30 | tr -d '\n'; echo
dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev
# left handed
</dev/urandom tr -dc '12345!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB' | head -c8; echo ""
date | md5sum

