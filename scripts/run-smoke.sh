#!/bin/bash
cd /home/yuyyuy/Projects/yuyyuy-projects/server
bun run start >/tmp/yuyyuy-server.log 2>&1 &
PID=$!
sleep 3
bun run smoke
R=$?
kill $PID
exit $R
