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

__read_proxy_config() {
    __ZSHPROXY_STATUS=$(cat "${HOME}/.zsh-proxy/status")
    __ZSHPROXY_SOCKS5=$(cat "${HOME}/.zsh-proxy/socks5")
    __ZSHPROXY_HTTP=$(cat "${HOME}/.zsh-proxy/http")
    __ZSHPROXY_NO_PROXY=$(cat "${HOME}/.zsh-proxy/no_proxy")
    __ZSHPROXY_GIT_PROXY_TYPE=$(cat "${HOME}/.zsh-proxy/git_proxy_type")
}

__check_whether_init() {
    if [ ! -f "${HOME}/.zsh-proxy/status" ] || [ ! -f "${HOME}/.zsh-proxy/http" ] || [ ! -f "${HOME}/.zsh-proxy/socks5" ] || [ ! -f "${HOME}/.zsh-proxy/no_proxy" ]; then
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
    echo -n "IPv4: "
    curl -s https://api-ipv4.ip.sb/ip
    echo "----------------------------------------"
    echo -n "IPv6: "
    curl -s https://api-ipv6.ip.sb/ip

    if which python >/dev/null; then
      echo "----------------------------------------"
      echo "Info: "
      curl -s https://api.ip.sb/geoip | python -m json.tool
      echo ""
    fi

    echo "========================================"
}

__config_proxy() {
    echo "========================================"
    echo "ZSH Proxy Plugin Config"
    echo "----------------------------------------"

    echo -n "[socks5 proxy] {Default as 127.0.0.1:1080}
(address:port): "
    read __read_socks5

    echo -n "[http proxy]   {Default as 127.0.0.1:8080}
(address:port): "
    read __read_http

    echo -n "[no proxy domain] {Default as 'localhost,127.0.0.1,localaddress,.localdomain.com'}
(comma separate domains): "
    read __read_no_proxy

    echo -n "[git proxy type] {Default as socks5}
(socks5 or http): "
    read __read_git_proxy_type
    echo "========================================"

    if [ ! -n "${__read_socks5}" ]; then
        __read_socks5="127.0.0.1:1080"
    fi
    if [ ! -n "${__read_http}" ]; then
        __read_http="127.0.0.1:8080"
    fi
    if [ ! -n "${__read_no_proxy}" ]; then
        __read_no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
    fi
    if [ ! -n "${__read_git_proxy_type}" ]; then
        __read_git_proxy_type="socks5"
    fi

    echo "http://${__read_http}" >${HOME}/.zsh-proxy/http
    echo "socks5://${__read_socks5}" >${HOME}/.zsh-proxy/socks5
    echo "${__read_no_proxy}" >${HOME}/.zsh-proxy/no_proxy
    echo "${__read_git_proxy_type}" >${HOME}/.zsh-proxy/git_proxy_type

    __read_proxy_config
}

# ==================================================

# Proxy for APT

__enable_proxy_apt() {
    if [ -d "/etc/apt/apt.conf.d" ] ; then
      sudo touch /etc/apt/apt.conf.d/proxy.conf
      echo -e "Acquire::http::Proxy \"${__ZSHPROXY_HTTP}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf >/dev/null
      echo -e "Acquire::https::Proxy \"${__ZSHPROXY_HTTP}\";" | sudo tee -a /etc/apt/apt.conf.d/proxy.conf >/dev/null
      echo "- apt"
    fi
}

__disable_proxy_apt() {
    if [ -d "/etc/apt/apt.conf.d" ] ; then
      sudo rm -rf /etc/apt/apt.conf.d/proxy.conf
    fi
}

# Proxy for pip
# pip can read http_proxy & https_proxy

# Proxy for terminal

__enable_proxy_all() {
    # http_proxy
    export http_proxy="${__ZSHPROXY_HTTP}"
    export HTTP_PROXY="${__ZSHPROXY_HTTP}"
    # https_proxy
    export https_proxy="${__ZSHPROXY_HTTP}"
    export HTTPS_proxy="${__ZSHPROXY_HTTP}"
    # ftp_proxy
    export ftp_proxy="${__ZSHPROXY_HTTP}"
    export FTP_PROXY="${__ZSHPROXY_HTTP}"
    # rsync_proxy
    export rsync_proxy="${__ZSHPROXY_HTTP}"
    export RSYNC_PROXY="${__ZSHPROXY_HTTP}"
    # all_proxy
    export ALL_PROXY="${__ZSHPROXY_SOCKS5}"
    export all_proxy="${__ZSHPROXY_SOCKS5}"

    export no_proxy="${__ZSHPROXY_NO_PROXY}"
}

__disable_proxy_all() {
    unset http_proxy
    unset HTTP_PROXY
    unset https_proxy
    unset HTTPS_PROXY
    unset ftp_proxy
    unset FTP_PROXY
    unset rsync_proxy
    unset RSYNC_PROXY
    unset ALL_PROXY
    unset all_proxy
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
    if which npm >/dev/null; then
      npm config set proxy ${__ZSHPROXY_HTTP}
      npm config set https-proxy ${__ZSHPROXY_HTTP}
      echo "- npm"
    fi
    if which yarn >/dev/null; then
      yarn config set proxy ${__ZSHPROXY_HTTP} >/dev/null 2>&1
      yarn config set https-proxy ${__ZSHPROXY_HTTP} >/dev/null 2>&1
      echo "- yarn"
    fi
}

__disable_proxy_npm() {
    if which npm >/dev/null; then
      npm config delete proxy
      npm config delete https-proxy
    fi
    if which yarn >/dev/null; then
      yarn config delete proxy >/dev/null 2>&1
      yarn config delete https-proxy >/dev/null 2>&1
    fi
}

# ==================================================

__enable_proxy() {
    if [ ! -n "${__ZSHPROXY_STATUS}" ] || [ ! -n "${__ZSHPROXY_SOCKS5}" ] || [ ! -n "${__ZSHPROXY_HTTP}" ]; then
        echo "========================================"
        echo "zsh-proxy can not read configuration."
        echo "You may have to reinitialize and reconfigure the plugin."
        echo "Use following commands would help:"
        echo "$ init_proxy"
        echo "$ config_proxy"
        echo "$ proxy"
        echo "========================================"
    else
        echo "========================================"
        echo -n "Resetting proxy... "
        __disable_proxy_all
        __disable_proxy_git
        __disable_proxy_npm
        __disable_proxy_apt
        echo "Done!"
        echo "----------------------------------------"
        echo "Enable proxy for:"
        echo "- shell"
        __enable_proxy_all
        echo "- git"
        __enable_proxy_git
        # npm & yarn"
        __enable_proxy_npm
        # apt"
        __enable_proxy_apt
        echo "Done!"
    fi
}

__disable_proxy() {
    __disable_proxy_all
    __disable_proxy_git
    __disable_proxy_npm
    __disable_proxy_apt
}

__auto_proxy() {
    if [ "${__ZSHPROXY_STATUS}" = "1" ]; then
        __enable_proxy_all
    fi
    if [ "${__ZSHPROXY_STATUS}" = "0" ]; then
    fi
}

# ==================================================

init_proxy() {
    mkdir -p $HOME/.zsh-proxy
    touch $HOME/.zsh-proxy/status
    echo "0" >${HOME}/.zsh-proxy/status
    touch $HOME/.zsh-proxy/http
    touch $HOME/.zsh-proxy/socks5
    touch $HOME/.zsh-proxy/no_proxy
    touch ${HOME}/.zsh-proxy/git_proxy_type
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
    echo "1" >${HOME}/.zsh-proxy/status
    __enable_proxy
    __check_ip
}

noproxy() {
    echo "0" >${HOME}/.zsh-proxy/status
    __disable_proxy
    __check_ip
}

myip() {
    __check_ip
}

__check_whether_init
__auto_proxy
