#!/bin/sh
set -x
set -e

if [ -z "$REPO" ];then
	echo "REPO envar not set!"
	exit 1
fi

pacman-key --init
pacman -Syu --noconfirm

# setup pacman and makepkg
if [ -z "$MIRR" ]; then
    reflector --verbose --latest 50 --sort rate --save /etc/pacman.d/mirrorlist
else
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist_old
    echo $MIRR > /etc/pacman.d/mirrorlist
    cat /etc/pacman.d/mirrorlist_old >> /etc/pacman.d/mirrorlist
fi

pacman -Syu --noconfirm base-devel git sudo ccache pigz pbzip2 --needed
sed -i '/MAKEFLAGS=/s/^#//g' /etc/makepkg.conf
sed -i "/MAKEFLAGS/s/-j[0-9]*/-j$(($(nproc)+1))/g" /etc/makepkg.conf

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
mkdir /home/builduser/pkgdest
chown builduser:builduser /home/builduser -R

su -c 'mkdir /home/builduser/.gnupg/ -p' builduser
su -c 'echo keyserver hkps://keys.gnupg.net:80 >> /home/builduser/.gnupg/gpg.conf' builduser

# download and extract build files
pushd /home/builduser > /dev/null
yay --getpkgbuild $REPO
chown builduser $REPO -R

# build package
buildDir=/home/builduser/$REPO/
pushd $buildDir > /dev/null
su -c '. PKGBUILD; yay -S ${makedepends[@]} ${depends[@]} --noconfirm --needed' builduser

if [ ! -z "$(cat PKGBUILD | grep validpgpkeys)" ];then
    su -c '. PKGBUILD; for i in ${validpgpkeys[@]}; do pacman-key --recv-key $i;done'
fi

su -c '. PKGBUILD; echo $pkgname >> /home/builduser/resInfo' builduser
su -c '. PKGBUILD; echo $pkgver >> /home/builduser/resInfo' builduser

# bulid the package
su -c 'GNUPGHOME=/etc/pacman.d/gnupg makepkg -src --noconfirm' builduser

ls /home/builduser/pkgdest
su -c 'ls /home/builduser/pkgdest >> /home/builduser/resInfo' builduser
