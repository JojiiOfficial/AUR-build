FROM archlinux

#add base-devel
run pacman -Syu reflector git wget curl sudo pigz pbzip2 --noconfirm
run mkdir /root/yay; cd /root/yay; wget https://github.com/JojiiOfficial/yayim/releases/download/v10.0.3_3/yay; chmod +x yay; mv yay /usr/bin
copy makepkg.conf /etc
run useradd -m builduser
run rm -rf /var/cache
run echo "keyserver hkp://keys.gnupg.net:80" >> /etc/pacman.d/gnupg/gpg.conf
