#!/bin/bash

LOCKFILE="/var/lock/doing_server_backup"
LOCKFD=99

_lock()             { flock -$1 $LOCKFD; }
_no_more_locking()  { _lock u; _lock xn && rm -f $LOCKFILE; }
_prepare_locking()  { eval "exec $LOCKFD>\"$LOCKFILE\""; trap _no_more_locking EXIT; }

_prepare_locking

exlock_now()        { _lock xn; }  # obtain an exclusive lock immediately or fail

exlock_now || exit 1