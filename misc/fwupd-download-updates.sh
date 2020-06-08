#!/bin/bash

FWUPD_UPDATES_DIR=/home/user/.cache/fwupd

echo "Running fwupd download script..."

CLEAN=
CHECK_ONLY=
METADATA=
SHASUM=
UPDATE=
URL=
FW_NAME=

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
            FW_NAME=${1#https://fwupd.org/downloads/}
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
    rm -f $FWUPD_UPDATES_DIR/metadata/*
    rm -f $FWUPD_UPDATES_DIR/updates/*
fi

if [ "$METADATA" == "1" ]; then
    echo "Downloading metadata."
    wget -P $FWUPD_UPDATES_DIR/metadata \
        https://cdn.fwupd.org/downloads/firmware.xml.gz
    wget -P $FWUPD_UPDATES_DIR/metadata \
        https://cdn.fwupd.org/downloads/firmware.xml.gz.asc
    gpg --verify $FWUPD_UPDATES_DIR/metadata/firmware.xml.gz.asc \
        $FWUPD_UPDATES_DIR/metadata/firmware.xml.gz
    if [ ! $? -eq 0 ]; then
        echo "Signature did NOT match. Exiting..."
        exit 1
    fi
fi

if [ "$UPDATE" == "1" ]; then
    echo "$FILE_NAME"
    echo "$FILE_NAME"
    echo "$FILE_NAME"
    echo "$SHASUM  $NAME" > $FWUPD_UPDATES_DIR/updates/sha1-$FILE_NAME
    echo "Downloading firmware update $NAME"
    wget -P $FWUPD_UPDATES_DIR/updates $URL
    sha1sum -c $FWUPD_UPDATES_DIR/updates/sha1-$FILE_NAME
    if [ ! $? -eq 0 ]; then
        rm -f $FWUPD_UPDATES_DIR/updates/*
        echo "Computed checksum did NOT match. Exiting..."
        exit 1
    fi
    FLAG="user:'echo "$SHASUM  $NAME" > \
        $FWUPD_UPDATES_DIR/updates/updateflag-$FILE_NAME'"
fi

CMD="/usr/lib/qubes/qrexec-client-vm dom0 fwupd.ReceiveUpdates"
qrexec_exit_code=0

$CMD || { qrexec_exit_code=$? ; true; };
if [ ! "$qrexec_exit_code" = "0" ]; then
    echo "'$CMD $FWUPD_UPDATES_DIR' failed with exit code \
        ${qrexec_exit_code}!" >&2
    exit "$qrexec_exit_code"
fi
