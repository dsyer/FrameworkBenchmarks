#!/bin/bash

set -e

if [ $# -lt 1 ]; then
	target="server database worker"
else
	target=$1
	shift
fi

args=$(terraform output server_name | sed -e 's/"//g')" "$(terraform output database_name | sed -e 's/"//g')" "$(terraform output worker_name | sed -e 's/"//g')

for f in $target; do
	remote=`terraform output $f'_ip' | sed -e 's/"//g'`
	ssh -o StrictHostKeyChecking=no -i ~/.ssh/google_compute_engine $remote ~/FrameworkBenchmarks/scripts/hosts.sh $args
done

remote=`terraform output server_ip | sed -e 's/"//g'`
if ! grep -q "Host gcp" ~/.ssh/config; then
	echo <<EOF > ~/.ssh/config
Host gcp
  HostName $remote
  User $USER
  IdentityFile ~/.ssh/google_compute_engine
EOF
else
	sed -i -e "/Host gcp/{n;s/HostName .*/HostName $remote/}" ~/.ssh/config
fi
