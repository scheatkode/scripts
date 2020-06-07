#!/bin/sh
# shellcheck disable=2006
# shellcheck disable=2016
# shellcheck disable=2002

if  ! command -v gpg    > /dev/null 2>&1 || \
    ! command -v base64 > /dev/null 2>&1    \
; then
    echo 'You need the `gpg` and `base64` binaries for this script to work.' >&2
    exit 1
fi

if [ x"$#" != x"1" ] ; then
    echo "Usage : ${0} <input-file>"
    exit 1
fi

if [ x"${GPG_TTY}" = x"" ] ; then
    GPG_TTY="`tty`"
fi

export GPG_TTY

crypted="`cat \"${1}\" | gpg --quiet --symmetric --cipher-algo AES256 | base64`"
content="`cat << END
#!/bin/sh
# shellcheck disable=2006
# shellcheck disable=2016

if  ! command -v gpg    > /dev/null 2>&1 || \
    ! command -v base64 > /dev/null 2>&1    \
; then
    echo 'You need the gpg and base64 binaries for this script to work.' >&2
    exit 1
fi

if [ x\"\${GPG_TTY}" = x\"\" ] ; then
    GPG_TTY=\"\`tty\`\"
fi

export GPG_TTY

content=\"\\\`cat << 'EOF'
${crypted}
EOF
\\\`\"

echo \"\\\${content}\" | base64 --decode | gpg --quiet --decrypt
END
`"

echo "${content}"

