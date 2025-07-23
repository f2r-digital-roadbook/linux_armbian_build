#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (c) 2013-2023 Igor Pecovnik, igor@armbian.com
#
# This file is a part of the Armbian Build Framework
# https://github.com/armbian/build/

run_host_command_logged() {
	local cmd="$@"
	echo "Running command: $cmd"
	if ! eval "$cmd"; then
		echo "Command failed: $cmd"
		exit 1
	fi
}

exit_with_error() {
	local message="${1:-Unknown error}"
	echo "Error: ${message}" >&2
	exit 1
}


done_with_temp_dir() {
	cd "${SRC}" || exit_with_error "can't change directory"
	rm -rf "${tmp_dir}"
}


compile_anube-plymouth-theme() {
	: "${artifact_version:?artifact_version is not set}"

	declare cleanup_id="" tmp_dir="$PWD/tmp"
	#prepare_temp_dir_in_workdir_and_schedule_cleanup "deb-anube-plymouth-theme" cleanup_id tmp_dir # namerefs

	declare plymouth_theme_anube_dir="anube-plymouth-theme"
	mkdir -p "${tmp_dir}/${plymouth_theme_anube_dir}"

	run_host_command_logged mkdir -p "${tmp_dir}/${plymouth_theme_anube_dir}"/{DEBIAN,usr/share/plymouth/themes/anube}

	cd "${tmp_dir}/${plymouth_theme_anube_dir}" || exit_with_error "can't change directory"

	# set up control file
	cat <<- END > DEBIAN/control
		Package: anube-plymouth-theme
		Version: ${artifact_version}
		Architecture: all
		Maintainer: $MAINTAINER <$MAINTAINERMAIL>
		Depends: plymouth, plymouth-themes
		Section: universe/x11
		Priority: optional
		Description: boot animation, logger and I/O multiplexer - Armbian theme
	END

	run_host_command_logged cp "${SRC}"/packages/plymouth-theme-anube/debian/{postinst,prerm,postrm} \
		"${tmp_dir}/${plymouth_theme_anube_dir}"/DEBIAN/
	chmod 755 "${tmp_dir}/${plymouth_theme_anube_dir}"/DEBIAN/{postinst,prerm,postrm}

	# this requires `imagemagick`

	run_host_command_logged convert  \
		"${SRC}"/packages/plymouth-theme-anube/anube-logo.png \
		"${tmp_dir}/${plymouth_theme_anube_dir}"/usr/share/plymouth/themes/anube/bgrt-fallback.png

	run_host_command_logged convert -resize 96x96 \
		"${SRC}"/packages/plymouth-theme-anube/spinner.gif \
		"${tmp_dir}/${plymouth_theme_anube_dir}"/usr/share/plymouth/themes/anube/throbber-%04d.png

	run_host_command_logged convert -rotate 270 -resize 0x0 "${SRC}"/packages/plymouth-theme-anube/watermark.png \
		"${tmp_dir}/${plymouth_theme_anube_dir}"/usr/share/plymouth/themes/anube/watermark.png

	run_host_command_logged cp "${SRC}"/packages/plymouth-theme-anube/{bullet,capslock,entry,keyboard,keymap-render,lock}.png \
		"${tmp_dir}/${plymouth_theme_anube_dir}"/usr/share/plymouth/themes/anube/

	run_host_command_logged cp "${SRC}"/packages/plymouth-theme-anube/anube.plymouth \
		"${tmp_dir}/${plymouth_theme_anube_dir}"/usr/share/plymouth/themes/anube/

	dpkg-deb -b "${tmp_dir}/${plymouth_theme_anube_dir}" "${SRC}overlay/packages/anube-plymouth-theme.deb"
	done_with_temp_dir "${cleanup_id}" # changes cwd to "${SRC}" and fires the cleanup function early
}

SRC="$PWD/userpatches/"
artifact_version="1.0.0"
artifact_version="${artifact_version:-$(date +%Y%m%d)}"
MAINTAINER="${MAINTAINER:-Armbian Build Framework <build@f2r.pt>}"

compile_anube-plymouth-theme
