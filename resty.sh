#!/bin/sh

# ----------------------------------------------------------------------------
#       -- openresty auto compil - My current script to get/compile/install Openresty --
#       -- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
# ----------------------------------------------------------------------------


target=ngx_openresty-1.7.7.2
name=openresty
version="${target#*-}"
installdir="/usr/local/tools/64bits/$name/$version"

# stop <message> [<exit code(default:1)>]
stop() { echo >&2 "Aborted $1"; exit ${2:-1}; }

# check if already installed ?
[ ! -d "$installdir" ] || stop "because $name seems already installed in $installdir"

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

################################
### debian dependencies part ###

#dpkg -l libluajit-5.1-dev:amd64 >/dev/null 2>&1
apt-get install -s libluajit-5.1-dev:amd64 >/dev/null || stop "debian package libluajit-5.1-dev:amd64 seems not available"

apt-get install -s libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make || stop "at simulation of debian packages"

################################

# must have ldconfig in path
PATH="$PATH:/sbin"; export PATH
type ldconfig || stop "at ldconfig not found (even with /sbin in PATH)"

# clean
make clean ;# or make distclean ?

# configure
{
./configure \
--with-luajit \
--prefix="$installdir" \
$(
echo	--without-http_echo_module
echo	--without-http_xss_module
echo	--without-http_coolkit_module
echo	--without-http_set_misc_module
echo	--without-http_form_input_module
echo	--without-http_encrypted_session_module
echo	--without-http_srcache_module
#	--without-http_lua_module
echo	--without-http_lua_upstream_module
#	--without-http_headers_more_module
echo	--without-http_array_var_module
echo	--without-http_memc_module
echo	--without-http_redis2_module
echo	--without-http_redis_module
echo	--without-http_rds_json_module
echo	--without-http_rds_csv_module
#	--without-ngx_devel_kit_module
echo	--without-http_ssl_module
#	--without-lua_cjson
echo	--without-lua_redis_parser
echo	--without-lua_rds_parser
#	--without-lua_resty_dns
echo	--without-lua_resty_memcached
echo	--without-lua_resty_redis
echo	--without-lua_resty_mysql
#	--without-lua_resty_upload
echo	--without-lua_resty_upstream_healthcheck
#	--without-lua_resty_string	# seems string+crypto : https://github.com/openresty/lua-resty-string/tree/master/lib/resty
echo	--without-lua_resty_websocket
#	--without-lua_resty_lock
#	--without-lua_resty_lrucache	# seems interesting : https://github.com/openresty/lua-resty-lrucache
#	--without-lua_resty_core
#	--without-lua51
#	--without-select_module
#	--without-poll_module
#	--without-http_charset_module
#	--without-http_gzip_module
#	--without-http_ssi_module
#	--without-http_userid_module
#	--without-http_access_module
#	--without-http_auth_basic_module
#	--without-http_autoindex_module
echo	--without-http_geo_module
echo	--without-http_map_module
echo	--without-http_split_clients_module
#	--without-http_referer_module
#	--without-http_rewrite_module
echo	--without-http_proxy_module
echo	--without-http_fastcgi_module
echo	--without-http_uwsgi_module
echo	--without-http_scgi_module
echo	--without-http_memcached_module
#	--without-http_limit_zone_module
#	--without-http_limit_req_module
#	--without-http_empty_gif_module
echo	--without-http_browser_module
echo	--without-http_upstream_ip_hash_module
#	--without-http
echo	--without-http-cache
echo	--without-mail_pop3_module
echo	--without-mail_imap_module
echo	--without-mail_smtp_module
#	--without-pcre
)
} || stop "at configure step"

# make
make || stop "at make step"


# install
make install || stop "at install step"

echo "# Installed in $installdir"
echo "# Status: OK"
