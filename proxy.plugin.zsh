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

__check_whether_init() {
    if [ ! -f "${HOME}/.zsh-proxy/status" ] || [ ! -f "${HOME}/.zsh-proxy/http" ] || [ ! -f "${HOME}/.zsh-proxy/socks5" ]; then
        echo "----------------------------------------"
        echo "You should run following command first:"
        echo "$ init_proxy"
        echo "----------------------------------------"
    else
        __ZSHPROXY_STATUS=$(cat "${HOME}/.zsh-proxy/status")
        __ZSHPROXY_SOCKS5=$(cat "${HOME}/.zsh-proxy/socks5")
        __ZSHPROXY_HTTP=$(cat "${HOME}/.zsh-proxy/http")
    fi
}

__check_ip() {
    echo "========================================"
    echo "Check what your IP is"
    echo "----------------------------------------"
    curl https://ip.cn
    echo "----------------------------------------"
    curl https://ip.gs
    echo "========================================"
}

__config_proxy() {
    echo "========================================"
    echo "Start Configuring ZSH Plugin"
    echo "----------------------------------------"
    echo -n "[socks5 proxy] (address:port): "
    read __read_socks5
    echo -n "[http proxy]   (address:port): "
    read __read_http
    echo "========================================"

    if [ ! -n "${__read_socks5}" ]; then
        __read_socks5="127.0.0.1:1080"
    fi
    if [ ! -n "${__read_http}" ]; then
        __read_http="127.0.0.1:8080"
    fi

    echo "http://${__read_http}" >${HOME}/.zsh-proxy/http
    echo "socks5://${__read_socks5}" proxy/socks5 >${HOME}/.zsh-proxy/socks5
}

# ==================================================

# Proxy for terminal

__enable_proxy_all() {
    export ALL_PROXY="${_ZSHPROXY_SOCKS5}"
    export all_proxy="${_ZSHPROXY_SOCKS5}"
}

__disable_proxy_all() {
    unset ALL_PROXY
    unset all_proxy
}

# Proxy for Git

__enable_proxy_git() {
    git config --global http.proxy "${__ZSHPROXY_SOCKS5}"
    git config --global https.proxy "${__ZSHPROXY_SOCKS5}"
}

__disable_proxy_git() {
    git config --global --unset http.proxy
    git config --global --unset https.proxy
}

# ==================================================

__enable_proxy() {
    __enable_proxy_all
    __enable_proxy_git
}

__disable_proxy() {
    __disable_proxy_all
    __disable_proxy_git
}

__auto_proxy() {
    if [ "${_PROXY_STATUS}" = "1" ]; then
        __enable_proxy
    fi
    if [ "${_PROXY_STATUS}" = "0" ]; then
        __disable_proxy
    fi
}

# ==================================================

init_proxy() {
    mkdir -p $HOME/.zsh-proxy
    touch $HOME/.zsh-proxy/status
    touch $HOME/.zsh-proxy/http
    touch $HOME/.zsh-proxy/socks5
    echo "----------------------------------------"
    echo "Great! The zsh-proxy is initialized"
    echo ""
    echo "  ______ _____ _    _   _____  "
    echo " |___  // ____| |  | | |  __ \ "
    echo "    / /| (___ | |__| | | |__| ) __ _____  ___   _ "
    echo "   / /  \___ \|  __  | |  ___/ '__/ _ \ \/ | | | |"
    echo "  / /__ ____) | |  | | | |   | | | (_) >  <| |_| |"
    echo " /_____|_____/|_|  |_| |_|   |_|  \___/_/\_\\\\__, |"
    echo "                                             __/ |"
    echo "                                            |___/ "
    echo "----------------------------------------"
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
