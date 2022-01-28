# Set console font
setfont ter-124n

# Set internet connection
iwctl station wlan0 scan
while :
do
  iwctl station wlan0 get-networks
  read -p "Type your WiFi network name: " wifi_name
  iwctl station wlan0 connect $wifi_name
  if ping -q -c 1 -W 1 google.com >/dev/null; then
    break
  else
    echo -e "Internet can not be reached! Try another WiFi network.\n"
  fi
done
pacman -Sy --noconfirm archlinux-keyring

# Wipe drive and initialize partitions
lsblk
printf "Type carefully drive's name: "
read drive
echo -e "g\nw" | fdisk /dev/$drive
echo -e "n\n\n\n500M\nEF00\nn\n\n\n\n\nw" | gdisk /dev/$drive

# Format and mount partitions
mkfs.fat -F32 -n BOOT /dev/$drive"1"
modprobe dm-crypt
cryptsetup luksFormat /dev/$drive"2"
cryptsetup luksOpen /dev/$drive"2" cryptarch
# To change the passkey for root partition
# cryptsetup luksChangeKey /dev/$drive"2"
mkfs.btrfs -L ARCH /dev/mapper/cryptarch
mount /dev/mapper/cryptarch /mnt
btrfs subvolume create /mnt/@
umount /mnt
btrfs check --clear-space-cache v2 /dev/mapper/cryptarch
mount -o noatime,compress=zstd,space_cache=v2,subvol=@ /dev/mapper/cryptarch /mnt
mkdir /mnt/boot
mount /dev/$drive"1" /mnt/boot

# Install essential packages
pacstrap /mnt base base-devel linux linux-firmware efibootmgr intel-ucode btrfs-progs ntfsprogs lvm2 terminus-font mtools dosfstools iwd nano gvim dhcpcd wpa_supplicant git reflector bash-completion lm_sensors axel archlinux-keyring ttf-dejavu ttf-fira-code ttf-fira-sans ttf-fira-mono 

# Transit to the new OS
cp /etc/fstab /mnt/etc/fstab
mkdir /mnt/var/lib/iwd && cp /var/lib/iwd/*.psk /mnt/var/lib/iwd/
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

# Setup primary settings
ln -sf /usr/share/zoneinfo/Asia/Riyadh /etc/localtime
timedatectl set-ntp true
timedatectl set-timezone Asia/Riyadh
hwclock --systohc
echo BUG > /etc/hostname
echo -e "\
#
127.0.0.1	localhost
::1		localhost
127.0.1.1	BUG.localdomain BUG" >> /etc/hosts
echo -e "\
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf
pacman -Sy
nano /etc/mkinitcpio.conf
mkinitcpio -p linux
bootctl --path=/boot install
echo -e "\
default		arch
console-mode	max
editor		no
timeout		0" > /boot/loader/loader.conf
partuuid=$(lsblk -o PARTUUID /dev/sda2) && partuuid=${partuuid: 9}
echo -e "\
title		arch linux
linux		/vmlinuz-linux
initrd		/intel-ucode.img
initrd		/initramfs-linux.img
options		cryptdevice=PARTUUID=$partuuid:cryptarch root=/dev/mapper/cryptarch rootflags=subvol=@ rw pcie_aspm=off ec_sys.write_support=1 video=1920x1080" > /boot/loader/entries/arch.conf
echo -e "blacklist	nouveau" > /etc/modprobe.d/blacklist.conf

printf "Type new username: "
read user_name


while :
do
  read -p "Type new password: " pass_word
  read -p "Retype new password: " check_pass
  if $pass_word == $check_pass; then
    break
  else
    echo -e "Sorry, passwords do not match! Try again.\n"
  fi
done

useradd -mg users -G audio,video,games,storage,optical,wheel,power,scanner,lp -s /bin/bash $user_name
echo -e "$pass_word\n$pass_word" | passwd && echo -e "$pass_word\n$pass_word" | passwd $user_name
echo -e "\
# $user_name prevliges
$user_name ALL=(ALL) ALL
%sudo ALL=(ALL) ALL" >> /etc/sudoers
echo -e "\
[Settings]
AutoConnect=true" >> /var/lib/iwd/EXT_5G.psk
systemctl enable iwd.service 
systemctl enable dhcpcd.service 
systemctl enable bluetooth
# Install GUI Server
pacman -Sy --noconfirm xorg xorg-xinit xf86-video-intel 

# To check GPU drivers
# lspci | grep VGA

# Graphic Settings
echo -e "/
Section \"Device\"
  Identifier	\"Intel Graphics\"
  Driver	\"intel\"
  Option	\"DRI\" \"3\"
EndSection" > /etc/X11/xorg.conf.d/20-intel.conf

echo -e "\
## Set Screen Render ##
# xrandr --output VIRTUAL1 --dpi 141 --scale 1.25x1.25 --mode 1920x1080 --brightness 0.65
xrandr --output eDP1 --dpi 120 --mode 1920x1080
xrandr --auto
# xrdb -merge ~/.Xresources
# exec gnome
# exec i3" >> /etc/X11/xinit/xinitrc
# echo "Xft.dpi: 120" >> /home/$user_name/.Xresources


# Later on
pacman -Sy i3 lightdm lightdm-slick-greeter dmenu lxappearance nitrogen archlinux-wallpaper xfce4-terminal picom firefox bluez bluez-utils pulseaudio xdg-utils xdg-user-dirs imagemagick imv

echo -e "\
# Switch the default greeter to SLICK.
  [Seat:*]
  greeter-session=lightdm-slick-greeter
# Set display dpi and brightness
  display-setup-script = xrandr --output eDP1 --dpi 120 --mode 1920x1080 --brightness 0.65
" >> /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
# To configure LightDM
# sudo lightdm-settings

# Install AUR package manager
su $user_name
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin/
makepkg -si --noconfirm
paru -S --noconfirm j4-dmenu-desktop stremio isw ttf-ms-win10-auto
sudo sensors-detect --auto
sudo modprobe -r ec_sys
sudo modprobe ec_sys write_support=1
echo -e "\
# Custome Fans Mode
[GS65]
address_profile = MSI_ADDRESS_DEFAULT
fan_mode = 140
# CPU
cpu_temp_0 = 55
cpu_temp_1 = 64
cpu_temp_2 = 70
cpu_temp_3 = 76
cpu_temp_4 = 82
cpu_temp_5 = 88
cpu_fan_speed_0 = 30
cpu_fan_speed_1 = 50
cpu_fan_speed_2 = 60
cpu_fan_speed_3 = 75
cpu_fan_speed_4 = 75
cpu_fan_speed_5 = 75
cpu_fan_speed_6 = 75
# GPU
gpu_temp_0 = 55
gpu_temp_1 = 61
gpu_temp_2 = 65
gpu_temp_3 = 71
gpu_temp_4 = 77
gpu_temp_5 = 87
gpu_fan_speed_0 = 30
gpu_fan_speed_1 = 50
gpu_fan_speed_2 = 55
gpu_fan_speed_3 = 60
gpu_fan_speed_4 = 65
gpu_fan_speed_5 = 68
gpu_fan_speed_6 = 78" >> /etc/isw.conf
# sudo isw -w 16Q2EMS1
# sudo systemctl enable isw@16Q2EMS1.service
sudo isw -w GS65
sudo systemctl enable isw@GS65.service

echo -e "\
bar {
	status_command i3status -c ~/.config/i3/i3status.conf
	tray_output none
	font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
	font pango:Source Code Pro Regular 11
}
# Brightness
exec xrandr --output eDP1 --brightness 0.65
# Wallpaper
exec nitrogen --restore
# Lockscreen
bindsym $mod+x exec i3lock -c 000000
# Gaps
gaps inner 10
# Borders
for_window [class=".*"] border pixel 0
# Picom
exec picom --no-fading-openclose
# Touchpad => Tap to Click
exec xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Tapping Enabled" 1
exec xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Natural Scrolling Enabled" 1
# Screen Brightness Controller => a fix for keyboard function key
bindsym XF86MonBrightnessUp exec --no-startup-id xbacklight -inc 5
bindsym XF86MonBrightnessDown exec --no-startup-id xbacklight -dec 5
# Screenshot
bindsym --release $mod+Print exec import -window root ~/Pictures/$(date +'%Y%m%d%H%M%S').png" >> .config/i3/config
echo -e "\
general {
        colors = true
        interval = 5
}
order += \"volume master\"
order += \"wireless _first_\"
# order += \"ethernet _first_\"
order += \"battery all\"
order += \"cpu_temperature 0\"
order += \"cpu_usage\"
order += \"memory\"
order += \"tztime local\"
order += \"time\"
volume master {
	format = \"♪: %volume\"
	device = \"default\"
	mixer = \"Master\"
	mixer_idx = 0
}
wireless _first_ {
        format_up = \"WiFi:%quality\"
        format_down = \"WiFi: down\"
}
ethernet _first_ {
        format_up = \"E: %ip (%speed)\"
        format_down = \"E: down\"
}
battery all {
        format = \"BAT: %percentage\"
	format_percentage = \"%.00f%s\"
	last_full_capacity = true
}
cpu_temperature 0 {
	format = \"TEMP: %degrees°\"
	path = \"/sys/class/thermal/thermal_zone0/temp\"
	max_threshold = 42
}
cpu_usage {
	format = \"CPU: %usage\"
}
memory {
        format = \"RAM: %used\"
        threshold_degraded = \"1G\"
        format_degraded = \"MEMORY < %available\"
}
tztime local {
#	format = \"%b %d, %Y\"
	format = \"%b %d\"
}
time {
	format = \"%I:%M%p \"
}
" > .config/i3/i3status.conf
echo -e "\
VteTerminal, vte-terminal {
  padding: 10px;
}
" > .config/gtk-3.0/gtk.css
cp /etc/xdg/picom.conf .config/
sudo picom
echo -e "\
# ----------- System Status ---------- #
alias brightness='xrandr --output eDP1 --brightness'
alias battery='echo \"Battery Charge: $(cat /sys/class/power_supply/BAT1/capacity)%.\"'
alias temperature='sudo isw -r 16Q2EMS1'
alias show-net='iwctl station wlan0 show'
alias scan-net='iwctl station wlan0 get-networks'
alias connect='iwctl station wlan0 connect'
# ------------------------------------ #" >> .bashrc

