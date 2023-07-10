#!/usr/bin/env sh

# checkout write tag
git clone $1 --depth=1 &
pid=$!

while [ -d "/proc/$pid" ]; do
    echo "Waiting for git clone to finish..."
    sleep 1
done