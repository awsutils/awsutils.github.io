#!/bin/sh
uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    archsm="amd64"; archlg="x86_64";;
  aarch64*)   archsm="arm64"; archlg="aarch64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

mkdir ~/.tmp

wget https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${archsm}.tar.gz -O ~/.tmp/k9s.tar.gz
tar -xzf ~/.tmp/k9s.tar.gz -C ~/.tmp 
install -o root -g root -m 0755 ~/.tmp/k9s /usr/local/bin/k9s