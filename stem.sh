#!/bin/bash

# Define functions
function select_from_menu() {
	local prompt="$1" outvar="$2"
	shift
	shift
	local options=("$@") cur=0 count=${#options[@]} index=0
	local esc=$(echo -en "\e") # cache ESC as test doesn't allow esc codes
	printf "$prompt\n"
	while true
	do
		# list all options (option list is zero-based)
		index=0
		for o in "${options[@]}"
		do
			if [ "$index" == "$cur" ]
			then echo -e " >\e[7m$o\e[0m" # mark & highlight the current option
			else echo "  $o"
			fi
			index=$(( $index + 1 ))
		done
		read -s -n3 key # wait for user to key in arrows or ENTER
		if [[ $key == $esc[A ]] # up arrow
		then cur=$(( $cur - 1 ))
			[ "$cur" -lt 0 ] && cur=0
		elif [[ $key == $esc[B ]] # down arrow
		then cur=$(( $cur + 1 ))
			[ "$cur" -ge $count ] && cur=$(( $count - 1 ))
		elif [[ $key == "" ]] # nothing, i.e the read delimiter - ENTER
		then break
		fi
		echo -en "\e[${count}A" # go up to the beginning to re-render
	done
	# export the selection to the requested output variable
	printf -v $outvar "${options[$cur]}"
}

function select_from_menu_flags() {
	local prompt="$1" outvar="$2"
	shift
	shift
	local options=("$@") cur=0 count=${#options[@]} index=0
	local selected=""
	local OPTIONS=""

	while [[ ! "$selected" == "DONE" ]]
	do
		clear
		OPTIONS="$OPTIONS $selected"
		select_from_menu "$prompt\nselected:$OPTIONS" selected "${options[@]}" "CLEAR SELECTION" "DONE"

		if [[ "$selected" == "CLEAR SELECTION" ]]
		then
			OPTIONS=""
			selected=""
		fi
	done
	printf -v $outvar "$OPTIONS"

}

function y_n_promt() {
		local promt=$1 cmd=$2
	read -p "$promt [y/N]" -n 1 -r
	echo    # (optional) move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		$cmd
		return 0
	fi
	return 1
}

echo "enable network time syncronization"
echo " --> timedatectl set-ntp true"
timedatectl set-ntp true

zones=(
	"Europe/Berlin"
)
select_from_menu "Select Timezone:" TIMEZONE "${zones[@]}"
echo "set timezone"
echo " --> ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

echo "set hardwareclock"
echo " --> hwclock --systohc"

locales=(
	"en_US.UTF-8"
	"de_DE.UTF-8"
	"nl_NL.UTF-8"
)
select_from_menu "Select locale:" LOCALE "${locales[@]}"

echo "set locale.gen"
echo " --> echo \"$LOCALE UTF-8\" >> /etc/locale.gen"
echo "$LOCALE UTF-8" >> /etc/locale.gen

echo "generate locale"
echo " --> locale-gen"
locale-gen

echo "set locale"
echo " --> echo \"LANG=$LOCALE\" > /etc/locale.conf"
echo "LANG=$LOCALE" > /etc/locale.conf

layouts=(
	"de-latin1"
	"us"
)
select_from_menu "Select keyboard layout:" LAYOUT "${layouts[@]}"

echo "set console keyboard layout"
echo " --> echo \"KEYMAP=$LAYOUT\" > /etc/vconsole.conf"
echo "KEYMAP=$LAYOUT" > /etc/vconsole.conf

read -p "Enter hostname: " HOSTNAME
echo "set hostname"
echo " --> echo $HOSTNAME > /etc/hostname"
echo $HOSTNAME > /etc/hostname

echo "Add a root password"
echo " --> passwd"
passwd

echo "[¡!] TODO microcodes"
echo "[¡!] TODO microcodes"
echo "[¡!] TODO microcodes"
echo "[¡!] TODO microcodes"
echo "[¡!] TODO microcodes"
echo "[¡!] TODO microcodes"

EFI=$1

if [ $EFI == true ]; then
	echo "installing grub for uefi boot"

	targets=("x86_64-efi")
	select_from_menu "Select target:" TARGET "${targets[@]}"
	echo " --> grub-install --target=$TARGET --efi-directory=/boot --bootloader-id=GRUB"
	grub-install --target=$TARGET --efi-directory=/boot --bootloader-id=GRUB
else
	echo "installing grub for bios boot"

	targets=("i386-pc")
	select_from_menu "Select target:" TARGET "${targets[@]}"
	echo "listing disks"
	echo " --> fdisk -l"
	fdisk -l
	read -p "please enter the name of the device where grub should be installed (/dev/sda not /dev/sdaX): " DEVICE
	
	echo " --> grub-install --target=TARGET $DEVICE"
	grub-install --target=TARGET $DEVICE

fi

echo "[¡!] TODO user + group setup"
echo "[¡!] TODO user + group setup"
echo "[¡!] TODO user + group setup"
echo "[¡!] TODO user + group setup"
echo "[¡!] TODO user + group setup"
echo "[¡!] TODO user + group setup"
echo "[¡!] TODO user + group setup"

