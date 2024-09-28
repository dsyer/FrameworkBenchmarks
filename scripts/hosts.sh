#!/bin/bash

for h in ${@}; do
  role=`echo $h | sed -e 's/-.*//'`
  if ! grep -q "tfb-$role" /etc/hosts; then
    echo `host $h | cut -d ' ' -f 4` tfb-$role | sudo tee -a /etc/hosts
  fi
done

host=$(hostname | sed -e 's/-.*//')
dir=`dirname $0`
if [ -e ${dir}/${host}.sh ]; then
  echo Executing init script for ${host}
  ${dir}/${host}.sh
fi
