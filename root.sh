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
INITIAL="base grub kernel-modules-hook"

echo "Enable network time syncronization"
echo " --> timedatectl set-ntp true"
timedatectl set-ntp true

echo "Checking boot type"
echo " --> ls /sys/firmware/efi/efivars 2> /dev/null > /dev/null && EFI=true && INITIAL=\"$INITIAL efibootmgr\" || EFI=false"
ls /sys/firmware/efi/efivars 2> /dev/null > /dev/null && EFI=true && INITIAL="$INITIAL efibootmgr" || EFI=false
if [ EFI == true ]; then
	echo "... UEFI detected"
else
	echo "... BIOS detected"
fi

echo "Listing connected devices: "
echo " --> lsblk"
lsblk
echo "Now create your prefered partitionin scheme."
echo "After this step the installer asumes /mnt to be mountpoint for /"
echo "In case of efi this also expects /mnt/boot to be mountpoint for efi part"
echo "Dont forget to swapon /dev/<swap_partition> if you configured one"
echo "Type exit once your done partitioning and mounting"
echo " --> bash"
bash
echo "Update pacman mirrors"
echo " --> reflector"
reflector
kernels=(
	"linux"
	"linux-hardened"
	"linux-zen"
)
select_from_menu "Select kernel:" KERNEL "${kernels[@]}"

editors=(
	"neovim"
	"nano"
)
select_from_menu "Select editors:" EDITORS "${editors[@]}"

codes=(
	""
	"amd-ucode"
	"intel-ucode"
)
select_from_menu "Select microcode: (select empty entry for none)" MUCODE "${codes[@]}"
y_n_promt "Do you want to use NetworkManager instead of systemd-networkd?" "echo added 'networkmanager' to initial packages" && INITIAL="$INITIAL networkmanager" && NETWORKD=false || NETWORKD=true

y_n_promt "Do you want to install linux firmware (not needed in VM)" "echo added 'linux-firmware' to initial packages" && INITIAL="$INITIAL linux-firmware"

echo "Installing essential packages"
echo " --> pacstrap /mnt $INITIAL $KERNEL$EDITORS $MUCODE"
pacstrap /mnt $INITIAL $KERNEL$EDITORS $MUCODE

echo "Generate fstab file"
echo " --> genfstab -U /mnt >> /mnt/etc/fstab"
genfstab -U /mnt >> /mnt/etc/fstab
echo "Generate fstab file"

echo "Download stem.sh and run it in chroot"
echo " --> curl -o /mnt/stem.sh https://raw.githubusercontent.com/devensiv/tree-inst/main/stem.sh"
curl -o /mnt/stem.sh https://raw.githubusercontent.com/devensiv/tree-inst/main/stem.sh
echo " --> chmod +x /mnt/stem.sh"
chmod +x /mnt/stem.sh

echo " --> arch-chroot /mnt ./stem.sh"
arch-chroot /mnt ./stem.sh $EFI $NETWORKD

echo "Delete stem.sh"
echo " --> rm /mnt/stem.sh"
rm /mnt/stem.sh

echo " --> reboot"
reboot
