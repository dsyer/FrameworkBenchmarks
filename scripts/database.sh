#!/bin/bash

ssd=
if lsblk | grep -q nvme1n1; then
  if ! mount | grep "on /ssd"; then
    sudo mkfs.ext4 -F /dev/nvme1n1
    sudo mkdir -p /ssd
	sudo mount /dev/nvme1n1 /ssd
  fi
  ssd="-v /ssd:/ssd"
fi

cd `dirname $0`/..
./tfb --mode verify --test spring
docker run -d -p 5432:5432 $ssd techempower/postgres
