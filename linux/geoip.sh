#!/bin/sh
# shellcheck disable=2005
# shellcheck disable=2006

echo "`curl --silent \"ipinfo.io/${1?Required argument}\"`"
