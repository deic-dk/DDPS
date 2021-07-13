#! /usr/bin/env bash
#
# Attempt to re-activate rules which should be announced but is not due to
# software failures (e.g. the BGP was not ready after power on)

# Obsolite now: see ddpsctl retry

echo 'update ddps.flowspecrules set isactivated = false, isexpired = false;' |  sudo -u postgres psql -d flows

# This is a quick fix for the situation, where the database attempts to push
# rules to the BGP service @ juniper before it is ready. Currently I don't know
# how to detect correctly if the BGP service is ready and have not decided
# how to 'hold the horses'. Its a rare condition requiring a power failure


