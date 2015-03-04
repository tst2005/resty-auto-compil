#!/bin/sh

# ----------------------------------------------------------------------------
#       -- openresty auto compil - My current script to get/compile/install Openresty --
#       -- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
# ----------------------------------------------------------------------------


#target=ngx_openresty-1.7.7.2
#name=openresty
#version="${target#*-}"
#installdir="/usr/local/tools/64bits/$name/$version"

show_usage() {
	echo "Usage: $0 <profile-directory>"
	echo "profile-directory must containts env and options file"
}

# stop <message> [<exit code(default:1)>]
stop() { echo >&2 "Aborted $1"; exit ${2:-1}; }

if [ $# -ne 1 ]; then
	show_usage
	exit 1
fi

profiledir="$1";shift

if [ -z "$profiledir" ]; then
	show_usage
	stop "because profile-directory is empty"
fi
[ -d "$profiledir" ] || stop "No such profile-directory $profiledir"


if [ ! -f "$profiledir/env" ]; then
	stop "Missing mandatory env file in directory $profiledir"
fi

. "$profiledir/env"

#if [ -n "$pathsfile" ]; then
#	[ -f "$profiledir/$pathsfile" ] || stop "No such paths file '$profiledir/$pathsfile'"
#fi
#if [ -n "$modulesfile" ]; then
#	[ -f "$profiledir/$modulesfile" ] || stop "No such modules file '$profiledir/$modulesfile'"
#fi

## convert modules and paths to absolute path
modules="$profiledir/modules"
paths="$profiledir/paths"
case "$profiledir" in
	/*) ;;	# absolute path: do nothing
	*)	# relative path: prefix with the current directory
		modules="$(pwd)/$modules"
		paths="$(pwd)/$paths"
esac

download_steps() {

	# download the source code archive
	[ -f "$target.tar.gz"     ] || wget 'http://openresty.org/download/'"$target"'.tar.gz'     || stop "Fail to download $target.tar.gz"
	[ -f "$target.tar.gz.asc" ] || wget 'http://openresty.org/download/'"$target"'.tar.gz.asc' || stop "Fail to download $target.tar.gz.asc"

	# check and trust the source code archive
	LANG=C LANGUAGE=C gpg --verify "$target.tar.gz.asc" 2>&1 | grep -q -F 'gpg: Good signature from "Yichun Zhang (agentzh) <agentzh@gmail.com>' || stop "[SECURITY] fail to verify the archive ! TAKE CARE !"

	# extract the archive
	[ -d "$target" ] || tar -xvzf "$target.tar.gz" || stop "at archive extraction"

	# enter into the directory
	cd -- "$target" || stop "at change directory $target"

	# simple check before configure
	[ -f ./configure ] || stop "at pre-configure step : missing configure file"
}

download_steps


################################
### debian dependencies part ###

deps_steps() {
	#dpkg -l libluajit-5.1-dev:amd64 >/dev/null 2>&1
	apt-get install -s libluajit-5.1-dev:amd64 >/dev/null || stop "debian package libluajit-5.1-dev:amd64 seems not available"

	apt-get install -s libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make || stop "at simulation of debian packages"
}

################################

paths_func() {
		with() { printf %s\\n "$*"; }
		while read -r w1 line; do
			case "$w1" in
				""|'#'*) continue ;;
				with) ;;
				*) stop "invalid line format '$w1 $line'"
			esac
			eval "$w1 $line"
		done < "$paths"
}

modules_func() {
		off() { printf %s\\n "--without-${1#--without-}"; }
                on()  { printf %s\\n "--with-${1#--with-}"; }

		while read -r w1 w2 w3_; do
			if [ "$w1" = "#" ] || [ -z "$w1" ]; then continue; fi;
			case "$w1" in
				off|on) "$w1" "$w2" ;;
			esac
		done < "$modules"
}

compile_steps() {

	# must have ldconfig in path
	PATH="$PATH:/sbin"; export PATH
	type ldconfig || stop "at ldconfig not found (even with /sbin in PATH)"

	# clean
	[ ! -f "Makefile" ] || make clean

	echo ./configure --with-luajit --prefix "$installdir"
	echo "  $(paths_func)"
	echo "  $(modules_func)"

	# configure
	{
	./configure \
	--with-luajit \
	--prefix="$installdir" \
	$(
		with() { echo "$@"; }
		while read -r w1 line; do
			case "$w1" in
				""|'#'*) continue ;;
				with) ;;
				*) stop "invalid line format '$w1 $line'"
			esac
			eval "$w1 $line"
		done < "$paths"
	) \
	$(
		off() { echo "--without-${1#--without-}"; }
                on()  { echo "--with-${1#--with-}"; }

		while read -r w1 w2 w3_; do
			if [ "$w1" = "#" ] || [ -z "$w1" ]; then continue; fi;
			case "$w1" in
				off|on) "$w1" "$w2" ;;
			esac
		done < "$modules"
	)
	} || stop "at configure step"

	# make
	make || stop "at make step"
}

install_steps() {

	umask 022 ;# FIXME: find a better way to fix permission

	# install
	make install || stop "at install step"

	echo "# Installed in $installdir"
}

post_install_check() {
	local pathtonginx="$installdir/nginx/sbin/nginx"
	[ -f "$pathtonginx" ] || stop "at post_install_check: resty binary not found (install fail?)"
	[ -x "$pathtonginx" ] || stop "at post_install_check: resty binary is not executable (really ?!)"

	# show the version ... TODO: do some check with this string.
	"$pathtonginx" -V 2>&1 | grep ^nginx
}

# check if already installed ?
if [ ! -d "$installdir" ]; then
	download_steps
	deps_steps
	compile_steps
	install_steps
#else
	#stop "because $name seems already installed in $installdir"
fi
post_install_check

echo "OK installed in $installdir"
