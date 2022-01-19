# echo -e "$user_pass" | su $user_name
# cd
git clone https://aur.archlinux.org/pikaur.git
cd pikaur
makepkg -si
########### needs code
pikaur -S isw
############# needs code
isw -w 16Q2EMS1
sensors-detect
############## needs code

# exit
sudo systemctl enable isw@16Q2EMS1.service
# exit

sudo cp /etc/isw.conf /etc/isw.conf.backup
# sudo cp ./archey/isw /mnt/etc/isw.conf
# echo "$(cat ./archey/aliases)" >> /mnt/home/$user_name/.bashrc