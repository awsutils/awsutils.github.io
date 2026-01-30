#!/bin/sh
uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    archsm="amd64"; archlg="x86_64";;
  aarch64*)   archsm="arm64"; archlg="aarch64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

mkdir ~/.tmp

wget https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${archsm}/kubectl -O ~/.tmp/kubectl
install -o root -g root -m 0755 ~/.tmp/kubectl /usr/local/bin/kubectl