# setfont ter-124n

# systemctl start iwd.service
# iwctl station wlan0 get-networks
# printf "Type your Network's name: "
# read $WiFi
# iwctl station wlan0 connect $WiFi

# ping 8.8.8.8 -c 2
# timedatectl set-ntp true
# pacman -Sy reflector --noconfirm
# reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

lsblk
printf "Type Carefully Your Drive's Name Initials: "
read drive
# echo -e "n\n\n\n500M\nEF00\nn\n\n\n\n\nw\n" | gdisk /dev/$drive
gdisk /dev/$drive
mkfs.fat -F32 /dev/$drive"2"

modprobe dm-crypt
cryptsetup luksFormat /dev/$drive"1"
cryptsetup luksOpen /dev/$drive"1" cryptarch

mkfs.btrfs /dev/mapper/cryptarch
mount /dev/mapper/cryptarch /mnt
btrfs subvolume create /mnt/@
umount /mnt

btrfs check —clear-space-cache v2 /dev/mapper/cryptarch
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/mapper/cryptarch /mnt
mkdir /mnt/boot

mount /dev/$drive"2" /mnt/boot

pacstrap /mnt base base-devel linux linux-firmware efibootmgr intel-ucode lvm2 mtools gptfdisk ntfs-3g ntfsprogs btrfs-progs arch-install-scripts iwd nano dhcpcd wpa_supplicant git reflector bash-completion terminus-font lm_sensors axel cronie rsync git vim

cp /var/lib/iwd/$WiFi".psk" /mnt/var/lib/iwd/

cp /etc/fstab /mnt/etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt