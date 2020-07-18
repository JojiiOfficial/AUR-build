#!/bin/sh
set -x
set -e

if [ -z "$REPO" ];then
	echo "REPO envar not set!"
	exit 1
fi

pacman -Syu --noconfirm

# setup pacman and makepkg
reflector --verbose --latest 50 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm base-devel git sudo ccache --needed
sed -i '/MAKEFLAGS=/s/^#//g' /etc/makepkg.conf
sed -i "/MAKEFLAGS/s/-j[0-9]*/-j$(($(nproc)))/g" /etc/makepkg.conf

# setup ccache
if [ "$USE_CCACHE" == "true" ]; then
    echo using ccache!
    chown builduser:builduser /ccache -R
    sed -i "/BUILDENV/s/\!ccache/ccache/g" /etc/makepkg.conf
else
    export CCACHE_DISABLE=1
fi

# create and setup builduser
SUDOERS="builduser ALL=(ALL) NOPASSWD: ALL"
echo $SUDOERS > /etc/sudoers.d/builduser
chown builduser:builduser /home/builduser -R

su -c 'mkdir /home/builduser/.gnupg/ -p' builduser
su -c 'echo keyserver keyserver.ubuntu.com >> /home/builduser/.gnupg/gpg.conf' builduser


# download and extract build files
pushd /home/builduser > /dev/null
yay --getpkgbuild $REPO
chown builduser $REPO -R

# build package
buildDir=/home/builduser/$REPO/
pushd $buildDir > /dev/null
su -c '. PKGBUILD; yay -S ${makedepends[@]} ${depends[@]} --noconfirm --needed' builduser
su -c 'makepkg -src --noconfirm' builduser
popd > /dev/null
popd > /dev/null

binFile="$buildDir"$(ls -t $buildDir  | grep -E "pkg.tar.zst$|pkg.tar.xz$"  | head -n1)
echo Binfile: $binFile

finalFile=/home/builduser/$REPO".pkg.tar.xz"
echo $finalFile

mv $binFile $finalFile
