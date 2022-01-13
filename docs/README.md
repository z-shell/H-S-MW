<h2 align="center">
  <a href="https://github.com/z-shell/zi">
    <img src="https://github.com/z-shell/zi/raw/main/docs/images/logo.svg" alt="Logo" width="80" height="80" />
  </a>
❮ ZI ❯ - History Search Multi Word
</h2>

<div align="center">

[![License (GPL version 3)](https://img.shields.io/badge/license-GNU%20GPL%20version%203-blue.svg?style=flat-square)](../LICENSE)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](../LICENSE)
![ZSH 5.0.0](https://img.shields.io/badge/zsh-v5.0.0-orange.svg?style=flat-square)

</div>

- [Introduction](#introduction)
- [Installation](#installation)
    - [ZI](#zi)
    - [Zinit](#zinit)
    - [Antigen](#antigen)
    - [Oh-My-Zsh](#oh-my-zsh)
    - [Zgen](#zgen)
- [Customizing](#customizing)
  - [Zstyles](#zstyles)
  - [Syntax highlighting](#syntax-highlighting)

# Introduction

Binds `Ctrl-R` to a widget that searches for multiple keywords in `AND` fashion.
In other words, you can enter multiple words, and history entries that match
all of them will be found. The entries are syntax highlighted.

H-S-MW has feature called **context viewing** – see all occurrences of a command together
with surrounding commands:

[![asciicast](https://asciinema.org/a/155704.png)](https://asciinema.org/a/155704)

Set:

```zsh
zstyle :plugin:history-search-multi-word reset-prompt-protect 1
```

to be able to use `zle reset-prompt` in your e.g. `sched` calls, in presence of
`z-shell/fast-syntax-highlighting`, `zsh-users/zsh-syntax-highlighting`,
`zsh-users/zsh-autosuggestions` and other plugins that hook up into Zshell by
overloading Zle widgets. You could e.g. use `sched` in following way:

```zsh
PROMPT=%B%F{yellow}%D{%H:%M:%S}%B%b%f
schedprompt() {
  zle && zle reset-prompt
  sched +1 schedprompt
}

zmodload -i zsh/sched
schedprompt
```

to refresh the clock in prompt every second. The `reset-prompt-protect` zstyle
needs to be set to 1 for correct cooperation with HSMW. Or, you could use `zle .reset-prompt` (i.e. with the dot in front) to call the original, not
overloaded (by F-Sy-H, zsh-autosuggestsions, etc.) `reset-prompt` widget.

# Installation

**The plugin is "standalone"**, which means that only sourcing it is needed. So to
install, unpack `H-S-MW` somewhere and add

```zsh
source {where-hsmw-is}/H-S-MW.plugin.zsh
```

to `zshrc`.

If using a plugin manager, then `Zplugin` is recommended, but you can use any
other too, and also install with `Oh My Zsh` (by copying directory to
`~/.oh-my-zsh/custom/plugins`).

### [ZI](https://github.com/z-shell/zi)

Add `zi load z-shell/H-S-MW` to your `.zshrc` file.
ZI will handle cloning the plugin for you automatically the next time you
start zsh.

### [Zinit](https://github.com/z-shell/zdharma-continuum)

Add `zinit load z-shell/H-S-MW` to your `.zshrc` file.
Zinit will handle cloning the plugin for you automatically the next time you
start zsh.

### Antigen

Add `antigen bundle z-shell/H-S-MW` to your `.zshrc` file.
Antigen will handle cloning the plugin for you automatically the next time you
start zsh. You can also add the plugin to a running zsh with `antigen bundle z-shell/H-S-MW` for testing before adding it to your
`.zshrc`.

### Oh-My-Zsh

1. `cd ~/.oh-my-zsh/custom/plugins`
2. `git clone git@github.com:z-shell/H-S-MW.git`
3. Add `H-S-MW` to your plugin list

### Zgen

Add `zgen load z-shell/H-S-MW` to your .zshrc file in the same
place you're doing your other `zgen load` calls in.

1. Start a new terminal session

# Customizing

## Zstyles

```zsh
zstyle ":history-search-multi-word" page-size "8"                      # Number of entries to show (default is $LINES/3)
zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold"   # Color in which to highlight matched, searched text (default bg=17 on 256-color terminals)
zstyle ":plugin:history-search-multi-word" synhl "yes"                 # Whether to perform syntax highlighting (default true)
zstyle ":plugin:history-search-multi-word" active "underline"          # Effect on active history entry. Try: standout, bold, bg=blue (default underline)
zstyle ":plugin:history-search-multi-word" check-paths "yes"           # Whether to check paths for existence and mark with magenta (default true)
zstyle ":plugin:history-search-multi-word" clear-on-cancel "no"        # Whether pressing Ctrl-C or ESC should clear entered query
```

## Syntax highlighting

Syntax highlighting is customized via `HSMW_HIGHLIGHT_STYLES` associative array.
It has keys like `reserved-word`, `alias`, `command`, `path`, etc. which are assigned
with strings like `fg=blue,bold`, to configure how given elements are to be
colored. If you assign this array before or after loading `hsmw` you will change the defaults. Complete list
of available keys is [at the beginning](https://github.com/z-shell/H-S-MW/blob/main/hsmw-highlight#L34-L62)
of `hsmw-highlight` file. Example `~/.zshrc` addition that sets `path` key –
paths that exist will be highlighted with background magenta, foreground white, bold:

```zsh
typeset -gA HSMW_HIGHLIGHT_STYLES
HSMW_HIGHLIGHT_STYLES[path]="bg=magenta,fg=white,bold"
```

Following code will enable coloring of options of form "-o" and "--option", with cyan:

```zsh
typeset -gA HSMW_HIGHLIGHT_STYLES
HSMW_HIGHLIGHT_STYLES[single-hyphen-option]="fg=cyan"
HSMW_HIGHLIGHT_STYLES[double-hyphen-option]="fg=cyan"
```

Following code will use 256 colors to highlight command separators (like ";" or "&&"):

```zsh
HSMW_HIGHLIGHT_STYLES[commandseparator]="fg=241,bg=17"
```
