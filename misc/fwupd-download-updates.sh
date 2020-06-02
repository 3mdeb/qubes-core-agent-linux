#!/bin/bash

FWUPD_UPDATES_DIR=/home/user/.cache/fwupd/fwupd-updates

echo "Running fwupd download script..."

CLEAN=
CHECK_ONLY=
METADATA=
SHASUM=
UPDATE=
URL=



while [ -n "$1" ]; do
    case $1 in
        --CHECK_ONLY)
            CHECK_ONLY=1
            ;;
        --clean)
            CLEAN=1
            ;;
        --metadata)
            METADATA=1
            ;;
        --url=*)
            UPDATE=1
            URL=${1#--url=}
            ;;
        --sha=*)
            SHASUM=${1#--sha=}
            ;;
        -*)
            echo "Command $1 unknown. exiting..."
            exit 1
            ;;
        *)
            echo "Command $1 unknown. exiting..."
            exit 1
            ;;
    esac
    shift
done

if [ ! -d $FWUPD_UPDATES_DIR ]; then
    echo "fwupd updates dir does not exist: $FWUPD_UPDATES_DIR" >&2
    exit 1
fi

if [ "$CHECK_ONLY" == "1" ]; then
    echo "Check only mode."
fi

if [ "$CLEAN" == "1" ]; then
    echo "Cleaning cache."
    rm -f $FWUPD_UPDATES_DIR/metadata
    rm -f $FWUPD_UPDATES_DIR/updates
fi

if [ "$METADATA" == "1" ]; then
    echo "Downloading metadata."
    wget -P $FWUPD_UPDATES_DIR/metadata \
        https://cdn.fwupd.org/downloads/firmware.xml.gz
    wget -P $FWUPD_UPDATES_DIR/metadata \
        https://cdn.fwupd.org/downloads/firmware.xml.gz.asc
    gpg --verify firmware.xml.gz.asc firmware.xml.gz.asc
    if [ ! $? -eq 0 ]; then
        rm -f $FWUPD_UPDATES_DIR/metadata/*
        echo "Wrong signature. Exiting..."
        exit 1
    fi
fi

if [ "$UPDATE" == "1" ]; then
    echo "Downloading firmware update $URL"
    wget -P $FWUPD_UPDATES_DIR/updates $URL
    wget -P $FWUPD_UPDATES_DIR/updates $URL
    if [ ! $? -eq 0 ]; then
        rm -f $FWUPD_UPDATES_DIR/metadata/*
        echo "Wrong signature. Exiting..."
        exit 1
    fi
fi

cmd="/usr/lib/qubes/qrexec-client-vm dom0 fwupd.ReceiveUpdates"
qrexec_exit_code=0
$cmd || { qrexec_exit_code=$? ; true; };
if [ ! "$qrexec_exit_code" = "0" ]; then
    echo "'$cmd $FWUPD_UPDATES_DIR/*.jpg' failed with exit code ${qrexec_exit_code}!" >&2
    exit "$qrexec_exit_code"
fi
