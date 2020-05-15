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

if [ ! -d $FWUPD_UPDATES_DIR ]; then
    echo "fwupd updates dir does not exist: $FWUPD_UPDATES_DIR" >&2
    exit 1
fi

if [ "$CHECK_ONLY" == "1" ]; then
    echo "Check only mode"
fi

if [ "$CLEAN" == "1" ]; then
    echo "Cleaning downloaded files"
    rm -f $FWUPD_UPDATES_DIR/*
fi

if [ -f $FWUPD_UPDATES_DIR/sample-image.jpg ]; then
    echo "File already exists."
else
    wget -O $FWUPD_UPDATES_DIR/sample-image.jpg \
        https://cloud.3mdeb.com/index.php/s/29QbbAqWMw8cSP4/preview
fi

cmd="/usr/lib/qubes/qrexec-client-vm dom0 qubes.ReceiveUpdates /usr/lib/qubes/qfile-agent"
qrexec_exit_code=0
$cmd "$FWUPD_UPDATES_DIR"/*.jpg || { qrexec_exit_code=$? ; true; };
if [ ! "$qrexec_exit_code" = "0" ]; then
    echo "'$cmd $FWUPD_UPDATES_DIR/*.jpg' failed with exit code ${qrexec_exit_code}!" >&2
    exit "$qrexec_exit_code"
fi
