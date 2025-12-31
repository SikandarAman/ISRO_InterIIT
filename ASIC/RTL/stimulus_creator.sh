#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <num_samples>"
    exit 1
fi

N=$1
outfile="stimulus.csv"

> "$outfile"  # clear file

for i in $(seq 0 $((N-1))); do
    echo "$i" >> "$outfile"
done

echo "Created $outfile with $N samples."

