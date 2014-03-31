#!/bin/bash
if [[ -z "${WOW_DIR}" ]]
then
  WOW_DIR="/Applications/World of Warcraft"
fi

/usr/bin/rsync --force --recursive --delete --update --verbose \
  --exclude=.git . \
  "${WOW_DIR}/Interface/AddOns/PetHealth-Broker"
