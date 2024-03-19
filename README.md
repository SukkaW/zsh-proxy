# zsh-proxy

[![Author](https://img.shields.io/badge/Author-Sukka-b68469.svg?style=flat-square)](https://skk.moe)
[![License](https://img.shields.io/github/license/sukkaw/zsh-proxy.svg?style=flat-square)](./LICENSE)

:nut_and_bolt: An [`oh-my-zsh`](https://ohmyz.sh/) plugin to configure proxy for some packages manager and software.

## Installation

### oh-my-zsh

Firstly, clone this repository in `oh-my-zsh`'s plugins directory.

```bash
git clone https://github.com/sukkaw/zsh-proxy.git ~/.oh-my-zsh/custom/plugins/zsh-proxy
```

Secondly, activate the plugin in `~/.zshrc`. Enable it by adding `zsh-proxy` to the [plugins array](https://github.com/robbyrussell/oh-my-zsh/blob/master/templates/zshrc.zsh-template#L66).

```
plugins=(
    [plugins
     ...]
    zsh-proxy
)
```

### Antigen

[Antigen](https://github.com/zsh-users/antigen) is a zsh plugin manager, and it support `oh-my-zsh` plugin as well. You only need to add `antigen bundle sukkaw/zsh-proxy` to your `.zshrc` with your other bundle commands if you are using Antigen. Antigen will handle cloning the plugin for you automatically the next time you start zsh. You can also add the plugin to a running zsh with `antigen bundle sukkaw/zsh-proxy` for testing before adding it to your `.zshrc`.

----

Congratulations! Open a new terminal or run `source $HOME/.zshrc`. If you see following lines, you have successfully installed `zsh-proxy`:

```
----------------------------------------
You should run following command first:
$ init_proxy
----------------------------------------
```

## Usage

### `init_proxy`

The tip mentioned below will show up next time you open a new terminal if you haven't  initialized the plugin with `init_proxy`.

After you run `init_proxy`, it is time to configure the plugin.

### `config_proxy`

Execute `config_proxy` will lead you to zsh-proxy configuration. Fill in socks5 & http proxy address in format `address:port` like `127.0.0.1:1080` & `127.0.0.1:8080`.

Default configuration of socks5 proxy is `127.0.0.1:1080`, and http proxy is `127.0.0.1:8080`. You can leave any of them blank during configuration to use their default configuration.

Currently `zsh-proxy` doesn't support proxy with authentication, but I am working on it.

### `proxy`

After you configure the `zsh-proxy`, you are good to go. Try following command will enable proxy for supported package manager & software:

```bash
$ proxy
```

And next time you open a new terminal, zsh-proxy will automatically enable proxy for you.

### `noproxy`

If you want to disable proxy, you can run following command:

```bash
$ noproxy
```

### `myip`

If you forget whether you have enabled proxy or not, it is fine to run `proxy` command directly, as `proxy` will reset all the proxy before enable them. But the smarter way is to use following command to check which IP you are using now:

```bash
$ myip
```

Check procedure will use `curl` and the IP data come from `ipip.net`, `ip.cn` & `ip.gs`.

## Uninstallation

**If you install `zsh-proxy` with Antigen**, you need to remove `antigen bundle sukkaw/zsh-proxy` to disable the plugin.
**If you install `zsh-proxy` with oh-myzsh**, you need to remove `zsh-proxy` item from plugin array, then run `rm -rf ~/.oh-my-zsh/custom/plugins/zsh-proxy` to remove the plugin.

And you can clean up files & folders created by `zsh-proxy` using following command:

```bash
$ rm -rf ~/.zsh-proxy
```

## Supported

`zsh-proxy` currently support those package manager & software:

- `http_proxy`
- `https_proxy`
- `ftp_proxy`
- `rsync_proxy`
- `all_proxy`
- git (http)
- npm & yarn
- apt

## Todo List

- socks5 & http proxy with authentication.
- check whether the program exist before enable proxy for it
- proxy for sudo user (`env_keep` or sorts of things)
- proxy for:
  - yum
  - pip
  - gradle
  - git with ssh
  - gem
- `no_proxy` config
- learn some from [arch wiki](https://wiki.archlinux.org/index.php/Proxy_server)

## Author

**zsh-proxy** © [Sukka](https://github.com/SukkaW), Released under the [MIT](https://github.com/SukkaW/zsh-proxy/blob/master/LICENSE) License.<br>
Authored and maintained by Sukka with help from contributors ([list](https://github.com/SukkaW/zsh-proxy/graphs/contributors)).

> [Personal Website](https://skk.moe) · [Blog](https://blog.skk.moe) · GitHub [@SukkaW](https://github.com/SukkaW) · Telegram Channel [@SukkaChannel](https://t.me/SukkaChannel) · Twitter [@isukkaw](https://twitter.com/isukkaw) · Keybase [@sukka](https://keybase.io/sukka)

<p align="center">
  <a href="https://github.com/sponsors/SukkaW/">
    <img src="https://sponsor.cdn.skk.moe/sponsors.svg"/>
  </a>
</p>
