#!/bin/bash
#  ______ _____ _    _   _____
# |___  // ____| |  | | |  __ \
#    / /| (___ | |__| | | |__| ) __ _____  ___   _
#   / /  \___ \|  __  | |  ___/ '__/ _ \ \/ | | | |
#  / /__ ____) | |  | | | |   | | | (_) >  <| |_| |
# /_____|_____/|_|  |_| |_|   |_|  \___/_/\_\\__, |
#                                             __/ |
#                                            |___/
# -------------------------------------------------
# A proxy plugin for zsh
# Sukka (https://skk.moe)

COMMON_ENV=(http https ftp rsync all)
SPEC_ENV=(apt git npm)

# zsh not support `${key,,}` or `${key^^}`
# usage: `echo aBa | lower` or `lower 'Qwe'`
lower() { echo "${*:-$(</dev/stdin)}" | tr '[:upper:]' '[:lower:]'; }
# usage: `echo aBa | upper` or `upper 'Qwe'`
upper() { echo "${*:-$(</dev/stdin)}" | tr '[:lower:]' '[:upper:]'; }

# try get wsl2 host ip
__wsl2_host_ip() {
  if [[ "$( uname -r | upper )" =~ "WSL" ]]; then
    grep nameserver /etc/resolv.conf | awk '{print $2}'
  fi
}

__local_ip() { hostname -I | awk '{print $1}' ; }

__read_proxy_config() {
  __ZSHPROXY_STATUS=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/status")
  __ZSHPROXY_SOCKS5=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5")
  __ZSHPROXY_HTTP=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/http")
  __ZSHPROXY_NO_PROXY=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy")
  __ZSHPROXY_NO_PROXY_APP=$(sed 's/^[ \t]*//;s/[ \t]*$//' "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy_app" | lower)
  __ZSHPROXY_GIT_PROXY_TYPE=$(cat "${ZDOTDIR:-${HOME}}/.zsh-proxy/git_proxy_type")
}

__check_whether_init() {
  if [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/status" ] || [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/http" ] || [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5" ] || [ ! -f "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy" ]; then
    echo "----------------------------------------"
    echo "You should run following command first:"
    echo "$ init_proxy"
    echo "----------------------------------------"
  else
    __read_proxy_config
  fi
}

__check_ip() {
  echo "========================================"
  echo "Check what your IP is"
  echo "----------------------------------------"
  ipv4=$(curl -s -k https://api-ipv4.ip.sb/ip -H 'user-agent: zsh-proxy')
  if [[ "$ipv4" != "" ]]; then
    echo "IPv4: $ipv4"
  else
    echo "IPv4: -"
  fi
  echo "----------------------------------------"
  ipv6=$(curl -s -k -m10 https://api-ipv6.ip.sb/ip -H 'user-agent: zsh-proxy')
  if [[ "$ipv6" != "" ]]; then
    echo "IPv6: $ipv6"
  else
    echo "IPv6: -"
  fi
  if command -v python >/dev/null; then
    geoip=$(curl -s -k https://api.ip.sb/geoip -H 'user-agent: zsh-proxy')
    if [[ "$geoip" != "" ]]; then
      echo "----------------------------------------"
      echo "Info: "
      echo "$geoip" | python -m json.tool
    fi
  fi
  echo "========================================"
}

__config_proxy() {
  echo "========================================"
  echo "ZSH Proxy Plugin Config"
  echo "----------------------------------------"
  wsl2_host_ip=$(__wsl2_host_ip) && wsl2_host_ip=${wsl2_host_ip:-'127.0.0.1'}

  __read_socks5_default="$wsl2_host_ip:1080"
  echo -n "[socks5 proxy] {Default as $__read_socks5_default}
(address:port): "
  read -r __read_socks5
  __read_socks5=${__read_socks5:-$__read_socks5_default}

  __read_socks5_type_default=1
  echo -n "[socks5 type] Select the proxy type you want to use {Default as socks5}:
1. socks5
2. socks5h (resolve DNS through the proxy server)
(1 or 2): "
  read -r __read_socks5_type
  __read_socks5_type=${__read_socks5_type:-$__read_socks5_type_default}

  __read_http_default="$wsl2_host_ip:8080"
  echo -n "[http proxy]   {Default as $__read_http_default}
(address:port): "
  read -r __read_http
  __read_http=${__read_http:-$__read_http_default}

  __read_no_proxy_default="localhost,127.0.0.1,$wsl2_host_ip,localaddress,.localdomain.com"
  echo -n "[no proxy domain] {Default as '$__read_no_proxy_default'}
(comma separate domains): "
  read -r __read_no_proxy
  __read_no_proxy=${__read_no_proxy:-$__read_no_proxy_default}

  echo -n "[no proxy app] Skip proxy config for those app, part of apt,rsync,ftp,git,npm
(comma separate app): "
  read -r __read_no_proxy_app

  __read_git_proxy_type_default=socks5
  echo -n "[git proxy type] {Default as $__read_git_proxy_type_default}
(socks5 or http): "
  read -r __read_git_proxy_type
  __read_git_proxy_type=${__read_git_proxy_type:-$__read_git_proxy_type_default}
  echo "========================================"

  echo "http://${__read_http}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/http"
  if [ "${__read_socks5_type}" = "2" ]; then
    echo "socks5h://${__read_socks5}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5"
  else
    echo "socks5://${__read_socks5}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5"
  fi
  echo "${__read_no_proxy}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy"
  echo "${__read_no_proxy_app}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy_app"
  echo "${__read_git_proxy_type}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/git_proxy_type"

  __read_proxy_config
}

# ==================================================

# Proxy for APT

__enable_proxy_apt() {
  if [ -d "/etc/apt/apt.conf.d" ]; then
    sudo touch /etc/apt/apt.conf.d/proxy.conf
    echo -e "Acquire::http::Proxy \"${__ZSHPROXY_HTTP}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf >/dev/null
    echo -e "Acquire::https::Proxy \"${__ZSHPROXY_HTTP}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf >/dev/null
    echo "- apt done"
  fi
}

__disable_proxy_apt() {
  if [ -d "/etc/apt/apt.conf.d" ]; then
    sudo rm -rf /etc/apt/apt.conf.d/proxy.conf
  fi
}

# Proxy for pip
# pip can read -r http_proxy & https_proxy

# Proxy for terminal

__enable_proxy_all() {
  for key in "${COMMON_ENV[@]}"; do
    if [[ ",$__ZSHPROXY_NO_PROXY_APP," =~ ",$key," ]]; then
      continue
    fi
    pk="${key}_proxy"
    #echo "setup $pk"
    export "$(echo "$pk" | lower)"="$__ZSHPROXY_HTTP"
    export "$(echo "$pk" | upper)"="$__ZSHPROXY_HTTP"
  done

  export no_proxy="${__ZSHPROXY_NO_PROXY}"
}

__disable_proxy_all() {
  for key in "${COMMON_ENV[@]}"; do
    if [[ ",$__ZSHPROXY_NO_PROXY_APP," =~ ",$key," ]]; then
      continue
    fi
    pk="${key}_proxy"
    echo "unset $pk"
    unset "$(echo "$pk" | lower)"
    unset "$(echo "$pk" | upper)"
  done
  unset no_proxy
}

# Proxy for Git

__enable_proxy_git() {
  if [ "${__ZSHPROXY_GIT_PROXY_TYPE}" = "http" ]; then
    git config --global http.proxy "${__ZSHPROXY_HTTP}"
    git config --global https.proxy "${__ZSHPROXY_HTTP}"
  else
    git config --global http.proxy "${__ZSHPROXY_SOCKS5}"
    git config --global https.proxy "${__ZSHPROXY_SOCKS5}"
  fi
}

__disable_proxy_git() {
  git config --global --unset http.proxy
  git config --global --unset https.proxy
}

# Clone with SSH can be sfind at https://github.com/comwrg/FUCK-GFW#git

# NPM

__enable_proxy_npm() {
  if command -v npm >/dev/null; then
    npm config set proxy "${__ZSHPROXY_HTTP}"
    npm config set https-proxy "${__ZSHPROXY_HTTP}"
    echo "- npm"
  fi
  if command -v yarn >/dev/null; then
    yarn config set proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
    yarn config set https-proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
    echo "- yarn"
  fi
  if command -v pnpm >/dev/null; then
    pnpm config set proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
    pnpm config set https-proxy "${__ZSHPROXY_HTTP}" >/dev/null 2>&1
    echo "- pnpm"
  fi
}

__disable_proxy_npm() {
  if command -v npm >/dev/null; then
    npm config delete proxy
    npm config delete https-proxy
  fi
  if command -v yarn >/dev/null; then
    yarn config delete proxy >/dev/null 2>&1
    yarn config delete https-proxy >/dev/null 2>&1
  fi
  if command -v pnpm >/dev/null; then
    pnpm config delete proxy >/dev/null 2>&1
    pnpm config delete https-proxy >/dev/null 2>&1
  fi
}

# ==================================================

__enable_proxy() {
  if [ -z "${__ZSHPROXY_STATUS}" ] || [ -z "${__ZSHPROXY_SOCKS5}" ] || [ -z "${__ZSHPROXY_HTTP}" ]; then
    echo "========================================"
    echo "zsh-proxy can not read -r configuration."
    echo "You may have to reinitialize and reconfigure the plugin."
    echo "Use following commands would help:"
    echo "$ init_proxy"
    echo "$ config_proxy"
    echo "$ proxy"
    echo "========================================"
  else
    echo "========================================"
    echo -n "Resetting proxy... "
    __disable_proxy
    echo "Done!"
    echo "----------------------------------------"
    echo "Enable proxy..."
    __enable_proxy_all
    for key in "${SPEC_ENV[@]}"; do
      if [[ ",$__ZSHPROXY_NO_PROXY_APP," =~ ",$key," ]]; then
        continue
      fi
      echo "setup $key proxy"
      eval "__enable_proxy_${key}"
    done
    echo "Done!"
  fi
}

__disable_proxy() {
  __disable_proxy_all
  for key in "${SPEC_ENV[@]}"; do
    if [[ ",$__ZSHPROXY_NO_PROXY_APP," =~ ",$key," ]]; then
      continue
    fi
    echo "clear $key proxy"
    eval "__disable_proxy_${key}"
  done
}

__auto_proxy() {
  if [ "${__ZSHPROXY_STATUS}" = "1" ]; then
    __enable_proxy_all
  fi
}

__zsh_proxy_update() {
  __NOW_PATH=$(
    cd "$(dirname "$0")" || exit
    pwd
  )
  cd "$HOME/.oh-my-zsh/custom/plugins/zsh-proxy" || exit
  git fetch --all
  git reset --hard origin/master
  source "${ZDOTDIR:-${HOME}}/.zshrc"
  cd "${__NOW_PATH}" || exit
}

# ==================================================

init_proxy() {
  mkdir -p "${ZDOTDIR:-${HOME}}/.zsh-proxy"
  touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
  echo "0" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
  touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/http"
  touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5"
  touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy"
  touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/no_proxy_app"
  touch "${ZDOTDIR:-${HOME}}/.zsh-proxy/git_proxy_type"
  echo "----------------------------------------"
  echo "Great! The zsh-proxy is initialized"
  echo ""
  echo -E '  ______ _____ _    _   _____  '
  echo -E ' |___  // ____| |  | | |  __ \ '
  echo -E '    / /| (___ | |__| | | |__| ) __ _____  ___   _ '
  echo -E "   / /  \___ \|  __  | |  ___/ '__/ _ \ \/ | | | |"
  echo -E '  / /__ ____) | |  | | | |   | | | (_) >  <| |_| |'
  echo -E ' /_____|_____/|_|  |_| |_|   |_|  \___/_/\_\\__, |'
  echo -E '                                             __/ |'
  echo -E '                                            |___/ '
  echo "----------------------------------------"
  echo "Now you might want to run following command:"
  echo "$ config_proxy"
  echo "----------------------------------------"
}

config_proxy() {
  __config_proxy
}

proxy() {
  echo "1" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
  __enable_proxy
  __check_ip
}

refresh_proxy() {
  wsl2_host_ip=$(__wsl2_host_ip)
  if [ -n "${wsl2_host_ip}" ]; then
    echo "update wsl2 host ip to $wsl2_host_ip"
    echo "http://${wsl2_host_ip}" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/http"
    sed -i "s@//.*:@//$wsl2_host_ip:@" "${ZDOTDIR:-${HOME}}/.zsh-proxy/socks5"
    if grep -q "1" "${ZDOTDIR:-${HOME}}/.zsh-proxy/status"; then
      __enable_proxy
    fi
  else
    echo 'refresh proxy only works for wsl2'
  fi
}

noproxy() {
  echo "0" >"${ZDOTDIR:-${HOME}}/.zsh-proxy/status"
  __disable_proxy
  __check_ip
}

myip() {
  __check_ip
}

zsh_proxy_update() {
  __zsh_proxy_update
}

__check_whether_init
__auto_proxy
