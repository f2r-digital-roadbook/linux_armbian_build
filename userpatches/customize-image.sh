#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	case $RELEASE in
		bookworm)
			InstallF2R_Extras
			;;
		stretch)
			# your code here
			# InstallOpenMediaVault # uncomment to get an OMV 4 image
			;;
		buster)
			# your code here
			;;
		bullseye)
			# your code here
			;;
		bionic)
			# your code here
			;;
		focal)
			# your code here
			;;
	esac
}

InstallF2R_Extras() {
	apt-get update
	echo "Installing custom .deb packages..."
	apt-get install -yy python3-pygame libinih1 xinput xterm
	dpkg -i /tmp/overlay/packages/gamma1000d_*_arm64.deb || apt-get install -f -y
	dpkg -i /tmp/overlay/packages/anube-plymouth-theme.deb || apt-get install -f -y

	# Enable passwordless sudo (comment out if not wanted)
	EXTRA_USERNAME="anube"
	echo "$EXTRA_USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_$EXTRA_USERNAME
	chmod 440 /etc/sudoers.d/99_$EXTRA_USERNAME

	apt-get clean
	rm -rf /var/lib/apt/lists/*
	rm -rf /var/cache/apt/*	

	# Copy WiFi configuration files
	if [[ -d /tmp/overlay/wifi ]]; then
		echo "Copying WiFi configuration files..."
		mkdir -p /etc/NetworkManager/system-connections
		cp -r /tmp/overlay/wifi/* /etc/NetworkManager/system-connections/
		chmod 600 /etc/NetworkManager/system-connections/*
	fi

	# Copy power manager configuration
	if [[ -d /tmp/overlay/power-manager ]]; then
		echo "Copying power manager configuration..."
		mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/
		cp /tmp/overlay/xfce4/xfce4-power-manager.xml /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/
		chmod 644 /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml
	fi

	# Copy prebuilt device tree because doesn't hang the SOC
	if [[ -d /tmp/overlay/dtb ]]; then
		echo "Copying prebuilt device tree..."
		cp -r /tmp/overlay/dtb/* /boot/dtb/amlogic/
	fi
	echo "Custom F2R extras installed successfully."
}

Main "$@"