#!/bin/bash

# Usage: ./make_stimulus_random01.sh <num_samples>
# Example: ./make_stimulus_random01.sh 10000

if [ -z "$1" ]; then
    echo "Usage: $0 <num_samples>"
    exit 1
fi

N=$1
outfile="stimulus.csv"

> "$outfile"   # clear file

# Generate random 0/1 values
for i in $(seq 1 "$N"); do
    echo $(( RANDOM % 2 )) >> "$outfile"
done

echo "Created $outfile with $N random binary samples (0 or 1)."

