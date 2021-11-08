#!/usr/bin/env bash
DATE=$(date '+%Y-%m-%d-%H%M')
PP=$(pgrep -ofa host | awk '{print $1}')
PID=$(ps --ppid $PP -o pid --no-headers| awk '{print $1}')
gdb -x gdb.commands /usr/lib/ckan/venv/bin/python3 $PID  > /var/lib/ckan/${DATE}_gdb_ckan.txt
