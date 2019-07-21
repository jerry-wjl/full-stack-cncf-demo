#!/bin/sh

if [ "$1" = "" ]; then
    echo Please specify vargrant node name
    exit 1
fi

DISK="`vboxmanage list hdds|grep $1|sed 's/Location: *//'`"

if [ "$DISK" ]; then
    echo Removing $DISK
    vboxmanage closemedium "$DISK" --delete
    VBOXPATH=`dirname "$DISK"`
    rmdir "$VBOXPATH"
fi
