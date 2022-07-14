<h1 align="center"><p>
  <a href="https://github.com/z-shell/zi" target="_blank">
    <img src="https://github.com/z-shell/zi/raw/main/docs/images/logo.svg" alt="ZI logo" width="60px" height="60px" />
    ❮ ZI ❯
  </a> - H-S-MW (History Search Multi Word)
</p></h1>
<h2 align="center"><p>
  Binds <kbd>Ctrl-R</kbd> to search for multiple keywords.<br/>
  History entries that match all keywords will be found and syntax highlighted.
</p></h2>
</p></h3>
<p align="center"><a href="https://asciinema.org/a/155704" target="_blank"><img src="https://asciinema.org/a/155704.svg" alt="ASCIInema Colored Zsh History – context of command demo" /></a></p>
<p align="center"><a href="../LICENSE" target="_blank">
  <img align="center" src="https://img.shields.io/badge/license-GNU%20GPL%20version%203-blue.svg?style=flat-square" alt="License (GPL version 3)">
</a>
<img align="center" src="https://img.shields.io/badge/zsh-v5.0.0-orange.svg?style=flat-square" alt="ZSH v5.0.0"></p><hr />

## Customizing

### Context viewing

See all occurrences of a command together with surrounding commands set:

```zsh
zstyle :plugin:history-search-multi-word reset-prompt-protect 1
```

### reset-prompt

Use `zle reset-prompt` in `sched` calls, in the presence of [`z-shell/F-Sy-H`](https://github.com/z-shell/F-Sy-H), [`zsh-users/zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting), [`zsh-users/zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions), and other plugins that hook up into Z-Shell by overloading ZLE widgets.

For example, to refresh the clock in prompt every second:

```zsh
PROMPT=%B%F{yellow}%D{%H:%M:%S}%B%b%f
schedprompt() {
  zle && zle reset-prompt
  sched +1 schedprompt
}

zmodload -i zsh/sched
schedprompt
```

The `reset-prompt-protect` zstyle needs to be set to 1 for correct cooperation with H-S-MW.

Alternatively, you could use `zle .reset-prompt` (i.e. with the dot in front) to call the original, not an overloaded `reset-prompt` widget (created by [F-Sy-H](https://github.com/z-shell/F-Sy-H), [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), etc.).

### Zstyles

```zsh
zstyle ":history-search-multi-word" page-size "8"                      # Number of entries to show (default is $LINES/3)
zstyle ":history-search-multi-word" highlight-color "fg=yellow,bold"   # Color in which to highlight matched, searched text (default bg=17 on 256-color terminals)
zstyle ":plugin:history-search-multi-word" synhl "yes"                 # Whether to perform syntax highlighting (default true)
zstyle ":plugin:history-search-multi-word" active "underline"          # Effect on active history entry. Try: standout, bold, bg=blue (default underline)
zstyle ":plugin:history-search-multi-word" check-paths "yes"           # Whether to check paths for existence and mark with magenta (default true)
zstyle ":plugin:history-search-multi-word" clear-on-cancel "no"        # Whether pressing Ctrl-C or ESC should clear entered query
```

### Syntax highlighting

Syntax highlighting is customized via `HSMW_HIGHLIGHT_STYLES` associative array. It has keys like `reserved-word`, `alias`, `command`, `path`, etc. which are assigned with strings like `fg=blue,bold`, to configure how given elements are to be colored. The complete list of available keys is at the beginning of [`functions/hsmw-highlight`](/functions/hsmw-highlight#L36-L65).

If you assign this array in `~/.zshrc` before or after loading `hsmw` you will change the defaults.

#### Examples

1. Sets `path` key – paths that exist will be highlighted with background magenta, foreground white, bold

```zsh
typeset -gA HSMW_HIGHLIGHT_STYLES
HSMW_HIGHLIGHT_STYLES[path]="bg=magenta,fg=white,bold"
```

2. Enable coloring of options of form "-o" and "--option", with cyan

```zsh
typeset -gA HSMW_HIGHLIGHT_STYLES
HSMW_HIGHLIGHT_STYLES[single-hyphen-option]="fg=cyan"
HSMW_HIGHLIGHT_STYLES[double-hyphen-option]="fg=cyan"
```

3. Use 256 colors to highlight command separators (like ";" or "&&")

```zsh
HSMW_HIGHLIGHT_STYLES[commandseparator]="fg=241,bg=17"
```

## Installation

**The plugin is "standalone"**, which means that only sourcing it is needed. So to install, unpack `H-S-MW` somewhere and add to `~/.zshrc`:

```zsh
source {where-hsmw-is}/H-S-MW.plugin.zsh
```

If using a plugin manager, then [ZI](https://github.com/z-shell/zi) is recommended, but you can use others if you prefer:

### [ZI](https://github.com/z-shell/zi)

Add `zi load z-shell/H-S-MW` to your `~/.zshrc` file. ZI will handle cloning the plugin for you automatically the next time you start zsh.

### [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh) (OMZ)

1. `cd ~/.oh-my-zsh/custom/plugins`
2. `git clone git@github.com:z-shell/H-S-MW.git`
3. Add `H-S-MW` to your plugin list

### [Zinit](https://github.com/zdharma-continuum/zinit)

Add `zinit load z-shell/H-S-MW` to your `.zshrc` file.

### [Antigen](https://github.com/zsh-users/antigen)

Add `antigen bundle z-shell/H-S-MW` to your `.zshrc` file. Antigen will handle cloning the plugin for you automatically the next time you start zsh. You can also add the plugin to a running zsh with `antigen bundle z-shell/H-S-MW` for testing before adding it to your `.zshrc`.

### [Zgen](https://github.com/tarjoilija/zgen)

1. Add `zgen load z-shell/H-S-MW` to your .zshrc file in the same place you're doing your other `zgen load` calls in.
2. Start a new terminal session
