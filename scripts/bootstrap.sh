#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage $0 <hostname-or-ip>"
    exit 1
fi

remote=$1
shift

ssh-keygen -f ~/.ssh/known_hosts -R $remote
while ! ssh -o StrictHostKeyChecking=no -i ~/.ssh/google_compute_engine $remote mkdir -m 700 -p .ssh
do
    echo "Waiting for ssh..."
    ((c++)) && ((c==100)) && break
    sleep 1
done
ssh -o StrictHostKeyChecking=no -i ~/.ssh/google_compute_engine $remote test -e ~/.ssh/id_rsa || scp -i ~/.ssh/google_compute_engine -o StrictHostKeyChecking=no ~/.ssh/id_rsa ~/.ssh/id_rsa.pub $remote:~/.ssh

rsync -e 'ssh -o StrictHostKeyChecking=no -i ~/.ssh/google_compute_engine' --filter=':- .gitignore' -a -P . $remote:~/FrameworkBenchmarks

ssh -o StrictHostKeyChecking=no -i ~/.ssh/google_compute_engine $remote ~/FrameworkBenchmarks/scripts/init.sh
