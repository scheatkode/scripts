#!/bin/sh

#   Generate random port number.

od -An -N2 -i /dev/urandom
