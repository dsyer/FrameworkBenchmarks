#!/bin/bash

for h in ${@}; do
  role=`echo $h | sed -e 's/-.*//'`
  echo `host $h | cut -d ' ' -f 4` tfb-$role | sudo tee -a /etc/hosts
done
