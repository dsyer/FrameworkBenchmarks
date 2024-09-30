#!/bin/bash

if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then . ~/.nix-profile/etc/profile.d/nix.sh; fi

if ! [ -d ~/.sdkman ]; then
  curl -s "https://get.sdkman.io" | bash
  . ~/.sdkman/bin/sdkman-init.sh
  sdk install java 23-tem < /dev/null
  sdk install java 21-tem < /dev/null
fi

if ! [ -d ~/profiler ]; then
  cd ~
  wget -O profiler.tgz https://github.com/async-profiler/async-profiler/releases/download/v3.0/async-profiler-3.0-linux-x64.tar.gz
  tar -xzf profiler.tgz
  rm profiler.tgz
  mv async-profiler-* profiler
fi
