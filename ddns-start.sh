#!/bin/sh
#-------------------
# DreamHost DNS updater, partly based on the "dreamhost-dynamic-dns"
# script by Paul Clement (github.com/clempaul/dreamhost-dynamic-dns)
#-------------------

# From https://github.com/RMerl/asuswrt-merlin.ng/wiki/DDNS-Sample-Scripts#dreamhost

## Create a file called `.ddns.env` with the following fields:
# KEY="ABC123"
# RECORD="example.com"
source .ddns.env

IP=${1}

echo "New IP = ${IP}"

fail() {
  /sbin/ddns_custom_updated 0
  exit 1
}

APIRequest() {
  local CMD=$1
  local ARGS=$2
  local UUID="`curl -sL 'https://uuid-serve.herokuapp.com/bulk/1'`"
  local DATA="key=${KEY}&unique_id=${UUID}&cmd=${CMD}&${ARGS}"
  local RESPONSE="`curl -s --data "${DATA}" 'https://api.dreamhost.com/'`"
printf "${RESPONSE}"
  if [ $? -ne 0 ]; then fail; fi

  # If "success" is not in the response, then the request failed
  printf "${RESPONSE}" | grep "^success$" > /dev/null 2>&1
  if [ $? -ne 0 ]; then fail; fi

  printf "${RESPONSE}"
}

# Get current record value
# OLD_VALUE="`APIRequest dns-list_records 'type=A&editable=1' \
#                       | grep "\s${RECORD}\sA" | awk '{print $5}'`"
OLD_VALUE="`dig +short @8.8.8.8 ${RECORD}`"

if [ $? -ne 0 ]; then fail; fi

if [ "${OLD_VALUE}" != "${IP}" ]; then
  if [ -n "${OLD_VALUE}" ]; then
    # Remove the existing record
    APIRequest dns-remove_record "record=${RECORD}&type=A&value=${OLD_VALUE}"
  fi
  # Add the new record
  APIRequest dns-add_record "record=${RECORD}&type=A&value=${IP}"
fi

/sbin/ddns_custom_updated 1

