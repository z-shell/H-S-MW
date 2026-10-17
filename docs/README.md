<h1 align="center"><p>
  <a href="https://github.com/z-shell/zi" target="_blank">
    <img src="https://github.com/z-shell/zi/raw/main/docs/images/logo.svg" alt="ZI logo" width="60px" height="60px" />
    ❮ Zi ❯
  </a> - H-S-MW (History Search Multi Word)
</p></h1>
<h2 align="center"><p>
  Binds <kbd>Ctrl-R</kbd> to search for multiple keywords.<br/>
  History entries that match all keywords will be found and syntax highlighted.
</p></h2>
</p></h3>
<p align="center"><img src="https://user-images.githubusercontent.com/59910950/182902165-a2e82ec4-c4e8-49a7-a83f-036e0a698655.gif" alt="ASCIInema Colored Zsh History – context of command demo" /></p>
<p align="center"><a href="../LICENSE" target="_blank">
  <img align="center" src="https://img.shields.io/badge/license-GNU%20GPL%20version%203-blue.svg?style=flat-square" alt="License (GPL version 3)">
</a>
<img align="center" src="https://img.shields.io/badge/zsh-v5.8-orange.svg?style=flat-square" alt="Zsh 5.8 or newer"></p><hr />

## Usage

Press <kbd>Ctrl-R</kbd> and type one or more words. Entries that contain every word, in any order, are listed below the command line with syntax highlighting; the newest match comes first. A query in lower case ignores case, and any upper-case letter makes it exact. A leading `^` anchors the first word to the start of the entry and a trailing `$` anchors the last word to its end.

| Key                                                                  | Action                                            |
| -------------------------------------------------------------------- | ------------------------------------------------- |
| <kbd>Up</kbd>, <kbd>Down</kbd>, <kbd>Ctrl-P</kbd>, <kbd>Ctrl-N</kbd> | Move to the previous or next match                |
| <kbd>Page Up</kbd>, <kbd>Page Down</kbd>                             | Move by a page                                    |
| <kbd>Enter</kbd>                                                     | Put the selected entry on the command line        |
| <kbd>Ctrl-K</kbd>                                                    | Show the entry in context, and again to go back   |
| <kbd>Ctrl-J</kbd>                                                    | Copy the selected entry to the end of history     |
| <kbd>Ctrl-V</kbd>, <kbd>Esc</kbd>                                    | Cancel and keep the query (see `clear-on-cancel`) |

## Configuration

Every setting is a style in the `:history-search-multi-word` context, read when a search starts, so a change takes effect on the next <kbd>Ctrl-R</kbd>.

```zsh
zstyle :history-search-multi-word page-size 8
zstyle :history-search-multi-word highlight-color "fg=yellow,bold"
```

| Style                  | Type    | Default                                                | Effect                                                                   |
| ---------------------- | ------- | ------------------------------------------------------ | ------------------------------------------------------------------------ |
| `page-size`            | integer | `LINES / 3`                                            | Entries shown per page; an arithmetic expression such as `LINES/4` works |
| `highlight-color`      | string  | `bg=17` on 256-colour terminals, else `fg=yellow,bold` | How the searched words are marked in the list                            |
| `active`               | string  | `underline`                                            | How the selected entry is marked, e.g. `standout`, `bold`, `bg=blue`     |
| `synhl`                | boolean | `yes`                                                  | Syntax-highlight the list                                                |
| `check-paths`          | boolean | `yes`                                                  | Test whether words are existing paths and mark them as paths             |
| `skip-paths`           | array   | empty                                                  | Patterns of paths never tested, e.g. slow network mounts                 |
| `clear-on-cancel`      | boolean | `no`                                                   | Clear the query when the search is cancelled                             |
| `reset-prompt-protect` | boolean | `no`                                                   | Keep the search running when something calls `zle reset-prompt`          |

```zsh
zstyle :history-search-multi-word skip-paths '/mnt/nfs/*' '/media/*'
```

### Syntax highlighting styles

The colours of the highlighted list are styles in the `:history-search-multi-word:highlight` context, one per token type:

```zsh
zstyle :history-search-multi-word:highlight path "bg=magenta,fg=white,bold"
zstyle :history-search-multi-word:highlight commandseparator "fg=241,bg=17"
```

Token types and their defaults: `default` (none), `unknown-token` (`fg=red,bold`), `reserved-word` (`fg=yellow`), `alias`, `suffix-alias`, `builtin`, `function`, `command`, `precommand`, `hashed-command` (all `fg=green`), `commandseparator` (none), `path` (`fg=magenta`), `path_pathseparator` (empty), `globbing` and `history-expansion` (`fg=blue,bold`), `single-hyphen-option` and `double-hyphen-option` (`fg=cyan`), `back-quoted-argument` (none), `single-quoted-argument`, `double-quoted-argument` and `dollar-quoted-argument` (`fg=yellow`), `back-or-dollar-double-quoted-argument` and `back-dollar-quoted-argument` (`fg=cyan`), `assign` and `redirection` (none), `comment` and `newline` (`fg=black,bold`), `variable` (none).

### reset-prompt

A prompt that refreshes itself, for example a clock redrawn from `sched`, calls `zle reset-prompt` while the search may be open. With `reset-prompt-protect` set, the search redraws itself after such a call instead of being disturbed:

```zsh
zstyle :history-search-multi-word reset-prompt-protect yes

PROMPT=%B%F{yellow}%D{%H:%M:%S}%B%b%f
schedprompt() {
  zle && zle reset-prompt
  sched +1 schedprompt
}

zmodload -i zsh/sched
schedprompt
```

Alternatively, call `zle .reset-prompt` (with the dot) to run the built-in widget rather than a copy other plugins may have wrapped.

### Upgrading from earlier versions

This version follows [version 2 of the Zsh Plugin Standard](https://wiki.zshell.dev/community/zsh_plugin_standard) and reads only the styles above. Move older settings as follows:

| Earlier setting                                        | Now                                                        |
| ------------------------------------------------------ | ---------------------------------------------------------- |
| `zstyle :plugin:history-search-multi-word STYLE VALUE` | `zstyle :history-search-multi-word STYLE VALUE`            |
| `HSMW_HIGHLIGHT_STYLES[TOKEN]=VALUE`                   | `zstyle :history-search-multi-word:highlight TOKEN VALUE`  |
| `FAST_BLIST_PATTERNS[PATTERN]=1`                       | `zstyle :history-search-multi-word skip-paths PATTERN ...` |

## Public shell surface

The project identifier is `history-search-multi-word`. Loading the plugin in an interactive shell creates exactly these public names; everything else it creates is private and named `_history_search_multi_word_*`.

- Widgets: `history-search-multi-word`, `history-search-multi-word-backwards`, `history-search-multi-word-pforwards`, `history-search-multi-word-pbackwards`.
- Key binding: <kbd>Ctrl-R</kbd> in the `main` keymap.
- Style contexts: `:history-search-multi-word` and `:history-search-multi-word:highlight`.
- Unload function: `history-search-multi-word_plugin_unload`, and `H-S-MW_plugin_unload`, the name Zi calls.
- `fpath`: the plugin's `functions/` directory, added when it is not already there.

A search also creates the `history-search-multi-word` keymap and loads `zsh/terminfo` and `zsh/termcap` when they are not loaded yet. A non-interactive shell gets only the `fpath` entry and the autoload definitions.

## Unloading

`history-search-multi-word_plugin_unload` removes everything the plugin created: its widgets, keymap, functions, parameters, the `fpath` entry it added and the terminal modules a search loaded. <kbd>Ctrl-R</kbd> gets back the widget it ran before loading, unless you have bound it to something else since. With Zi, `zi unload z-shell/H-S-MW` calls it.

## Installation

**The plugin is "standalone"**, which means that only sourcing it is needed. So to install, unpack `H-S-MW` somewhere and add to `~/.zshrc`:

```zsh
source {where-H-S-MW-is}/H-S-MW.plugin.zsh
```

If using a plugin manager, then [Zi](https://github.com/z-shell/zi) is recommended, but you can use others if you prefer:

### [Zi](https://github.com/z-shell/zi)

Add `zi load z-shell/H-S-MW` to your `~/.zshrc` file. Zi will handle cloning the plugin for you automatically the next time you start zsh.

### [Oh My Zsh](https://github.com/robbyrussell/oh-my-zsh) (OMZ)

1. Run this command to clone and mv to the ~/.oh-my-zsh/custom/plugins directory

   ```zsh
   git clone https://github.com/z-shell/H-S-MW.git \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/H-S-MW
   ```

2. Add `H-S-MW` to your plugin list in the ~/.zshrc file

   `plugins=(... H-S-MW)`

### [Antigen](https://github.com/zsh-users/antigen)

Add `antigen bundle z-shell/H-S-MW` to your `.zshrc` file. Antigen will handle cloning the plugin for you automatically the next time you start zsh. You can also add the plugin to a running zsh with `antigen bundle z-shell/H-S-MW` for testing before adding it to your `.zshrc`.

### [Zgen](https://github.com/tarjoilija/zgen)

1. Add `zgen load z-shell/H-S-MW` to your .zshrc file in the same place you're doing your other `zgen load` calls in.
2. Start a new terminal session

## Supported Zsh versions

Zsh 5.8 or newer. The test workflow runs on Zsh 5.8.1 and 5.9.2.

## Development

The tests drive the widget in an interactive shell through `zsh/zpty`; each file runs on its own and prints `ok:` or `FAIL:` lines:

```zsh
for test in tests/test-*.zsh; do zsh -f "$test"; done
```

Set `TEST_ZSH` to run the shells under test with another Zsh binary. Loading costs about 2 ms in an interactive shell, measured with `zsh/zprof` and `EPOCHREALTIME` on Zsh 5.9.2; half of it is the subshell that records the earlier <kbd>Ctrl-R</kbd> binding so that unloading can restore it.
