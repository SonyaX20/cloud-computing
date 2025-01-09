#!/bin/bash

# Check if sysbench is installed, install it if not
if ! command -v sysbench &> /dev/null; then
    echo "Installing sysbench..."
    sudo apt update && sudo apt install -y sysbench
fi

# Record the current Unix timestamp
TIMESTAMP=$(date +%s)

# Run CPU benchmark
CPU=$(sysbench cpu run --time=60 | grep 'events per second' | awk '{print $4}')

# Run memory benchmark
MEMORY=$(sysbench memory run --time=60 --memory-block-size=4K --memory-total-size=100TB | grep 'transferred' | awk '{print $1}')

# Prepare disk benchmark files
sysbench fileio --file-total-size=1G prepare

# Run random disk read benchmark
DISK_RAND=$(sysbench fileio --file-total-size=1G --file-test-mode=rndrd run | grep 'read, MiB/s' | awk '{print $1}')

# Run sequential disk read benchmark
DISK_SEQ=$(sysbench fileio --file-total-size=1G --file-test-mode=seqrd run | grep 'read, MiB/s' | awk '{print $1}')

# Cleanup disk benchmark files
sysbench fileio cleanup

# Print results in CSV format
echo "${TIMESTAMP},${CPU},${MEMORY},${DISK_RAND},${DISK_SEQ}"