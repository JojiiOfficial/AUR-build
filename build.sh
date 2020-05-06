#!/bin/sh
set -x
set -e

if [ -z "$REPO" ];then
	echo "REPO envar not set!"
fi

pacman -Sy jq --noconfirm --needed

SUDOERS="builduser ALL=(ALL) NOPASSWD: ALL"
URLPATH="https://aur.archlinux.org"$(curl -sq https://aur.archlinux.org/rpc/\?v\=5\&type\=info\&by\=name\&arg\=$REPO  | jq '.results[0].URLPath' -r)

pacman -S reflector wget --noconfirm --needed
reflector --verbose --latest 50 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm base-devel git sudo --needed
sed -i '/MAKEFLAGS=/s/^#//g' /etc/makepkg.conf
sed -i "/MAKEFLAGS/s/-j[0-9]/-j$(($(nproc)-1))/g" /etc/makepkg.conf
useradd -m builduser
echo $SUDOERS > /etc/sudoers.d/builduser
pushd /home/builduser > /dev/null
wget $URLPATH -O build.tar.gz
chown builduser build.tar.gz
su -c 'tar -xvzf build.tar.gz' builduser
pushd /home/builduser/$(tar -tf build.tar.gz | head -n1) > /dev/null
su -c 'makepkg -sric --noconfirm' builduser
popd > /dev/null
popd > /dev/null

ls -lath ./
