#!/bin/sh
set -x
set -e

if [ -z "$REPO" ];then
	echo "REPO envar not set!"
fi

# useDmanager is true if the bulilt binary should be uploaded to a datamanager server
useDmanager=false

set +x
if [ ! -z "$DM_URL" ] && [ ! -z "$DM_TOKEN" ] && [ ! -z "$DM_USER" ]; then
	useDmanager=true
fi
set -x

pacman -Sy jq wget --noconfirm --needed

# download and setup dataManager client
if [ $useDmanager ];then
	wget https://github.com/DataManager-Go/DataManagerCLI/releases/download/v1.4.1/manager_linux -O /usr/bin/manager
	chmod u+x /usr/bin/manager
	set +x
	manager setup $DM_URL -y --token "$DM_TOKEN" --user "$DM_USER"
	set -x
fi

# retrieve AUR build files
URLPATH="https://aur.archlinux.org"$(curl -sq https://aur.archlinux.org/rpc/\?v\=5\&type\=info\&by\=name\&arg\=$REPO  | jq '.results[0].URLPath' -r)

# setup pacman and makepkg
pacman -S reflector --noconfirm --needed
reflector --verbose --latest 50 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm base-devel git sudo --needed
sed -i '/MAKEFLAGS=/s/^#//g' /etc/makepkg.conf
sed -i "/MAKEFLAGS/s/-j[0-9]*/-j$(($(nproc)-1))/g" /etc/makepkg.conf

# create and setup builduser
useradd -m builduser
SUDOERS="builduser ALL=(ALL) NOPASSWD: ALL"
echo $SUDOERS > /etc/sudoers.d/builduser

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

# upload built package to dmanager if desired
if [ $useDmanager ];then
	manager upload $binFile --public
fi
