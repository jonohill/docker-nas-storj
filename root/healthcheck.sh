#!/usr/bin/env bash

set -e

for dir in blobs garbage temp trash; do
    mount_dir="$STORAGE_DIR/$dir"
    if ! mount | grep "$mount_dir" >/dev/null; then
        exit 1
    fi
done
