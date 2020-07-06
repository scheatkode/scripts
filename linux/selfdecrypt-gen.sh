#!/bin/sh
# shellcheck disable=2006
# shellcheck disable=2016
# shellcheck disable=2002

#   Generate a self decrypting file.
#
#   For when you  don't want to write  long ass commands just  to copy a
#   sensitive file over some (probably)  insecure network or store it on
#   the cloud.
#   This generates a runnable shell script used to restore your file.
#
#   Dependencies :
#       - gpg
#       - base64
#
#   Usage :
#       selfdecrypt-gen.sh <input-file> > <output-file>
#       cat <input-file> | selfdecrypt-gen.sh > <output-file>

if  ! command -v gpg    > /dev/null 2>&1 || \
    ! command -v base64 > /dev/null 2>&1    \
; then
    echo 'You need the gpg and base64 binaries for this script to work.' >&2
    exit 1
fi

if [ x"${GPG_TTY}" = x"" ] ; then
    GPG_TTY="`tty`"
fi

export GPG_TTY

if [ -t 0 ] ; then
    if [ x"$#" != x"1" ] ; then
        echo "Usage : ${0} <input-file>"
        echo "        cat <input-file> | ${0}"
        exit 1
    else
        crypted="`
            cat \"${1}\"             \
            | gpg                    \
                --quiet              \
                --symmetric          \
                --cipher-algo AES256 \
            | base64
        `"
    fi
else
    crypted="`
        while read -r line ; do
            echo \"${line}\"
        done < /dev/stdin        \
        | gpg                    \
            --quiet              \
            --symmetric          \
            --cipher-algo AES256 \
        | base64
    `"
    :
fi

content="`cat << END
#!/bin/sh
# shellcheck disable=2006
# shellcheck disable=2016

if  ! command -v gpg    > /dev/null 2>&1 || \\\\
    ! command -v base64 > /dev/null 2>&1    \\\\
; then
    echo 'You need the gpg and base64 binaries for this script to work.' >&2
    exit 1
fi

if [ x\"\${GPG_TTY}\" = x\"\" ] ; then
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

