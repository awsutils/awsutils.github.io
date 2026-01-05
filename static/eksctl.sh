#!/bin/sh
uname_out=$(uname -m)
case "${uname_out}" in
  x86_64*)    archsm="amd64"; archlg="x86_64";;
  aarch64*)   archsm="arm64"; archlg="aarch64";;
  *)          echo "Unknown architecture: ${uname_out}"; exit 1;;
esac

mkdir ~/.tmp

wget https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_linux_${archsm}.tar.gz -O ~/.tmp/eksctl.tar.gz
tar -xzf ~/.tmp/eksctl.tar.gz -C ~/.tmp 
install -o root -g root -m 0755 ~/.tmp/eksctl /usr/local/bin/eksctl