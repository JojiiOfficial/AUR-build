#!/bin/sh
set -x
set -e

if [ -z "$REPO" ];then
	echo "REPO envar not set!"
	exit 1
fi

pacman -Syu --noconfirm
pacman -S jq wget --noconfirm --needed

# retrieve AUR build files
URLPATH="https://aur.archlinux.org"$(curl -sq https://aur.archlinux.org/rpc/\?v\=5\&type\=info\&by\=name\&arg\=$REPO  | jq '.results[0].URLPath' -r)

# setup pacman and makepkg
pacman -S reflector --noconfirm --needed
reflector --verbose --latest 50 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm base-devel git sudo --needed
sed -i '/MAKEFLAGS=/s/^#//g' /etc/makepkg.conf
sed -i "/MAKEFLAGS/s/-j[0-9]*/-j$(($(nproc)-1))/g" /etc/makepkg.conf

# create and setup builduser
SUDOERS="builduser ALL=(ALL) NOPASSWD: ALL"
echo $SUDOERS > /etc/sudoers.d/builduser
chown builduser:builduser /home/builduser -R

su -c 'mkdir /home/builduser/.gnupg/ -p' builduser
su -c 'echo keyserver keyserver.ubuntu.com >> /home/builduser/.gnupg/gpg.conf' builduser

# download and extract build files
pushd /home/builduser > /dev/null
wget $URLPATH -O build.tar.gz
chown builduser build.tar.gz
su -c 'tar -xvzf build.tar.gz' builduser

# build package
buildDir=/home/builduser/$(tar -tf build.tar.gz | head -n1) 
pushd $buildDir > /dev/null
su -c 'makepkg -src --noconfirm' builduser
popd > /dev/null
popd > /dev/null

binFile="$buildDir"$(ls -t $buildDir  | grep -E "pkg.tar.xz$"  | head -n1)
echo $binFile

finalFile=/home/builduser/$REPO".pkg.tar.xz"
echo $finalFile

mv $binFile $finalFile
