systemctl enable dhcpcd.service
systemctl enable iwd.service

# reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
hwclock --systohc

nano /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo FONT=ter-124n > /etc/vconsole.conf

echo BUG > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\t\tlocalhost\n127.0.1.1\tBUG.localdomain BUG" >> /etc/hosts

echo -e "[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf
pacman -Sy

echo -e "Add ( btrfs ) into modules!\nAdd ( consolefont encrypt lvm2 ) into HOOKS!\nMove ( keyboard ) before ( filesystems ) in HOOKS!\nPress Enter to proceed..."
read y
nano /etc/mkinitcpio.conf
mkinitcpio -p linux

bootctl --path=/boot install
echo -e "default\t\tarch\nconsole-mode\tmax\neditor\t\tno\ntimeout\t\t0" >> /boot/loader/loader.conf
partuuid=$(lsblk -o PARTUUID /dev/$drive"2")
partuuid=${partuuid: 9}
echo -e "title\t\tArch Linux\nlinux\t\t/vmlinuz-linux\ninitrd\t\t/intel-ucode.img\ninitrd\t\tinitramfs-linux.img\noptions\t\tcryptdevice=PARTUUID=\"$partuuid\":cryptarch root=/dev/mapper/cryptarch rootflags=subvol=@ rw pcie_aspm=off ec_sys.write_support=1\n#quiet splash" >> /boot/loader/entries/arch.conf

echo -e "blacklist\tnouveau" > /etc/modprobe.d/blacklist.conf

# printf "Type NEW user name: "
# read user_name
# printf "Type NEW user password: "
# read user_pass
# useradd -mg users -G audio,video,games,storage,optical,wheel,power,scanner,lp -s /bin/bash $user_name
# echo -e "$user_pass\n$user_pass" | passswd $user_name
# echo -e "$user_pass\n$user_pass" | passswd
# echo -e "\n## $user_name'\'s' modifications\n$user_name ALL=(ALL) ALL\n%sudo ALL=(ALL) ALL" >> /etc/sudoers

# echo -e "\n[Settings]\nAutoConnect=true" >> /var/lib/iwd/$WiFi".psk"
