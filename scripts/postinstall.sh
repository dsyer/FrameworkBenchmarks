#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage $0 <hostname-or-ip>"
    exit 1
fi

remote=$1
shift

args=$(terraform output server_name | sed -e 's/"//g')" "$(terraform output database_name | sed -e 's/"//g')" "$(terraform output worker_name | sed -e 's/"//g')

ssh -o StrictHostKeyChecking=no -i ~/.ssh/google_compute_engine $remote ~/FrameworkBenchmarks/scripts/hosts.sh $args
