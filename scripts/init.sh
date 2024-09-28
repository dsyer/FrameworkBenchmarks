#!/bin/bash

if ! which docker 2>&1 > /dev/null; then
    sudo apt-get update
    sudo apt-get install -yq docker.io
    sudo usermod -aG docker $USER
fi

if ! [ -e ~/.config/nixpkgs/config.nix ]; then
    mkdir -p ~/.config/nixpkgs
    ln -s ~/FrameworkBenchmarks/.config/nixpkgs/config.nix ~/.config/nixpkgs
fi

if ! which nix-env 2>&1 > /dev/null; then
  # Install nix
  curl -L https://nixos.org/nix/install | bash
  # Initialize env vars
  . ~/.nix-profile/etc/profile.d/nix.sh
fi

if ! nix-env -q | grep -q user-packages; then
  # Install user packages from ~/.config/nixpkgs
  nix-env -i user-packages
fi
