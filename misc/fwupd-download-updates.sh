#!/bin/bash

FWUPD_UPDATES_DIR=/var/lib/fwupd/fwupd-updates

echo "Running fwupd download script..."

CLEAN=
CHECK_ONLY=
FW_HARDWARE=
OPTS=
EXARGS=

while [ -n "$1" ]; do
    case $1 in
        --CHECK_ONLY)
            CHECK_ONLY=1
            ;;
        --clean)
            CLEAN=1
            ;;
        --hardware=*)
            FW_HARDWARE=${1#--hardware}
            ;;
        -*)
            OPTS="$OPTS $1"
            ;;
        *)
            EXARGS="$EXARGS $1"
            ;;
    esac
    shift
done

if [ -d "$FWUPD_UPDATES_DIR" ];
    echo "fwupd updates dir does not exists: "

if [ $CHECK_ONLY -eq 1 ]; then
    echo "Check only mode"
fi

if [ $CLEAN -eq 1 ]; then
    echo "Cleaning downloaded files"
fi
