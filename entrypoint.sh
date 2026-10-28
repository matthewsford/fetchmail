#!/bin/sh
set -eu

# fetchmail refuses a run-control file that isn't owned by the running user with mode 0600, and
# a mounted Secret is owned by root, so copy it into $HOME first.
RC_SRC="${FETCHMAIL_RC:-/etc/fetchmail/fetchmailrc}"
RC_DST="${HOME}/.fetchmailrc"

if [ ! -r "$RC_SRC" ]; then
  echo "fetchmailrc not found at $RC_SRC" >&2
  exit 1
fi

install -m 0600 "$RC_SRC" "$RC_DST"

# --nodetach keeps it in the foreground; --nosyslog logs to stderr for `kubectl logs`.
exec fetchmail --nodetach --nosyslog -f "$RC_DST" "$@"
