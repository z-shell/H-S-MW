<table><tr><td>
<h1 align="center">
  <a href="https://github.com/z-shell/zi" target="_blank">
    <img src="https://github.com/z-shell/zi/raw/main/docs/images/logo.svg" alt="Logo" width="60" height="60" />
  </a>
❮ ZI ❯ - History Search Multi Word
</h1>

Binds <kbd>Ctrl-R</kbd> to a widget that searches for multiple keywords in `AND` fashion. In other words, you can enter multiple words, and history entries that match all of them will be found. The entries are syntax highlighted.

<a href="https://asciinema.org/a/155704" target="_blank"><img src="https://asciinema.org/a/155704.svg" /></a>

</td></tr>
<tr><td align="center">
<a href="../LICENSE" target="_blank">
  <img align="center" src="https://img.shields.io/badge/license-GNU%20GPL%20version%203-blue.svg?style=flat-square" alt="License (GPL version 3)">
</a>
<img align="center" src="https://img.shields.io/badge/zsh-v5.0.0-orange.svg?style=flat-square" alt="ZSH 5.0.0">
</td></tr></table>

## Customizing

H-S-MW has feature called **context viewing** – see all occurrences of a command together with surrounding commands set:

```shell
zstyle :plugin:history-search-multi-word reset-prompt-protect 1
```

Use `zle reset-prompt` in `sched` calls, in presence of `z-shell/fast-syntax-highlighting`, `zsh-users/zsh-syntax-highlighting`, `zsh-users/zsh-autosuggestions` and other plugins that hook up into Zshell by overloading Zle widgets, e.g.:

```shell
PROMPT=%B%F{yellow}%D{%H:%M:%S}%B%b%f
schedprompt() {
  zle && zle reset-prompt
  sched +1 schedprompt
}

zmodload -i zsh/sched
schedprompt
```

Refresh the clock in prompt every second. The `reset-prompt-protect` zstyle needs to be set to 1 for correct cooperation with HSMW. Or, you could use `zle .reset-prompt` (i.e. with the dot in front) to call the original, not overloaded (by F-Sy-H, zsh-autosuggestsions, etc.) `reset-prompt` widget.

### Zstyles

```shell
zstyle ":history-search-multi-word" page-size "8"                      # Number of entries to show (default is $LINES/3)
zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold"   # Color in which to highlight matched, searched text (default bg=17 on 256-color terminals)
zstyle ":plugin:history-search-multi-word" synhl "yes"                 # Whether to perform syntax highlighting (default true)
zstyle ":plugin:history-search-multi-word" active "underline"          # Effect on active history entry. Try: standout, bold, bg=blue (default underline)
zstyle ":plugin:history-search-multi-word" check-paths "yes"           # Whether to check paths for existence and mark with magenta (default true)
zstyle ":plugin:history-search-multi-word" clear-on-cancel "no"        # Whether pressing Ctrl-C or ESC should clear entered query
```

### Syntax highlighting

Syntax highlighting is customized via `HSMW_HIGHLIGHT_STYLES` associative array. It has keys like `reserved-word`, `alias`, `command`, `path`, etc. which are assigned with strings like `fg=blue,bold`, to configure how given elements are to be colored.

If you assign this array before or after loading `hsmw` you will change the defaults. Complete list of available keys is [at the beginning](https://github.com/z-shell/H-S-MW/blob/main/functions/hsmw-highlight#L34-L62) of `hsmw-highlight` file. Example `~/.zshrc` addition that sets `path` key – paths that exist will be highlighted with background magenta, foreground white, bold:

```shell
typeset -gA HSMW_HIGHLIGHT_STYLES
HSMW_HIGHLIGHT_STYLES[path]="bg=magenta,fg=white,bold"
```

Following code will enable coloring of options of form "-o" and "--option", with cyan:

```shell
typeset -gA HSMW_HIGHLIGHT_STYLES
HSMW_HIGHLIGHT_STYLES[single-hyphen-option]="fg=cyan"
HSMW_HIGHLIGHT_STYLES[double-hyphen-option]="fg=cyan"
```

Following code will use 256 colors to highlight command separators (like ";" or "&&"):

```shell
HSMW_HIGHLIGHT_STYLES[commandseparator]="fg=241,bg=17"
```

## Installation

**The plugin is "standalone"**, which means that only sourcing it is needed. So to
install, unpack `H-S-MW` somewhere and add to `zshrc`:

```shell
source {where-hsmw-is}/H-S-MW.plugin.zsh
```

If using a plugin manager, then `Zplugin` is recommended, but you can use any
other too, and also install with `Oh My Zsh` (by copying directory to
`~/.oh-my-zsh/custom/plugins`).

### [ZI](https://github.com/z-shell/zi)

Add `zi load z-shell/H-S-MW` to your `.zshrc` file. ZI will handle cloning the plugin for you automatically the next time you start zsh.

### Zinit

Add `zinit load z-shell/H-S-MW` to your `.zshrc` file.

### Antigen

Add `antigen bundle z-shell/H-S-MW` to your `.zshrc` file. Antigen will handle cloning the plugin for you automatically the next time you start zsh. You can also add the plugin to a running zsh with `antigen bundle z-shell/H-S-MW` for testing before adding it to your `.zshrc`.

### Oh-My-Zsh

1. `cd ~/.oh-my-zsh/custom/plugins`
2. `git clone git@github.com:z-shell/H-S-MW.git`
3. Add `H-S-MW` to your plugin list

### Zgen

Add `zgen load z-shell/H-S-MW` to your .zshrc file in the same place you're doing your other `zgen load` calls in.

1. Start a new terminal session
