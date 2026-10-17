#  ============================================================================  #
#  [ https://github.com/z-shell ] ❮ ZI ❯        [ (c) 2022 Z-SHELL COMMUNITY ]   #
#  ============================================================================  #
#
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# No plugin manager is needed to use this file:
#   source {where-unpacked}/H-S-MW.plugin.zsh
#
# Project identifier: history-search-multi-word. docs/README.md lists the
# public surface; everything else is named _history_search_multi_word_*.
#
# The scoped loader keeps every option and temporary parameter local.
# https://wiki.zshell.dev/community/zsh_plugin_standard#entrypoints-and-repository-layout
() {
  builtin emulate -L zsh

  local -r source_path=${1:a}
  local -r plugin_dir=${source_path:h}
  local -r functions_dir=$plugin_dir/functions

  # A repeated source changes nothing: the first load owns every resource.
  (( ${+functions[history-search-multi-word_plugin_unload]} )) && return 0

  # What this load and the first search add, so unload removes only that:
  #   fpath       - the functions/ entry, when this load appended it
  #   keymap      - the keymap main named at load, where Ctrl-R is bound
  #   ctrl_r_kind - what Ctrl-R did there before: widget, string, or empty
  #                 when it was unbound or already ran this plugin's widget
  #   ctrl_r      - that widget name or string
  #   modules     - terminal modules the search loaded (it records them)
  typeset -gA _history_search_multi_word_state
  _history_search_multi_word_state=( fpath '' keymap '' ctrl_r_kind '' ctrl_r '' modules '' )

  # Add functions/ only when no manager or earlier load already did.
  if (( ! ${fpath[(Ie)$functions_dir]} )); then
    fpath+=( "$functions_dir" )
    _history_search_multi_word_state[fpath]=$functions_dir
  fi

  autoload -Uz history-search-multi-word _history_search_multi_word_context _history_search_multi_word_highlight

  # Declared before any widget exists so a failed load can still be undone.
  # https://wiki.zshell.dev/community/zsh_plugin_standard#unload-function
  history-search-multi-word_plugin_unload() {
    builtin emulate -L zsh
    builtin setopt extended_glob

    local -A state
    (( ${+_history_search_multi_word_state} )) && state=( "${(@kv)_history_search_multi_word_state}" )
    local definition binding module keymap=${state[keymap]-}
    local -a words

    if zmodload -e zsh/zle; then
      # Ctrl-R gets back what it did before loading, in the keymap it was
      # bound in, but only while it still runs the search: a binding the user
      # made after loading is theirs.
      if [[ -n $keymap ]]; then
        binding=$(builtin bindkey -M "$keymap" '^R' 2>/dev/null)
        if [[ $binding == '"^R" history-search-multi-word' ]]; then
          case ${state[ctrl_r_kind]-} in
            (widget) builtin bindkey -M "$keymap" '^R' "${state[ctrl_r]}" ;;
            (string) builtin bindkey -M "$keymap" -s '^R' "${state[ctrl_r]}" ;;
            (*) builtin bindkey -M "$keymap" -r '^R' ;;
          esac
        fi
      fi
      builtin bindkey -D history-search-multi-word 2>/dev/null
      # Delete the plugin's widgets by name. A wrapper that replaced a public
      # widget is removed with it; copies and aliases under other names belong
      # to whoever made them.
      for definition in "${(@f)$(builtin zle -lL 2>/dev/null)}"; do
        words=( "${(@Q)${(z)definition}}" )
        [[ ${words[1]} == zle && ${words[2]} == -N ]] || continue
        [[ ${words[3]} == (history-search-multi-word(|-backwards|-pbackwards|-pforwards)|_history_search_multi_word_*) ]] &&
          builtin zle -D -- "${words[3]}"
      done
    fi

    functions +M _history_search_multi_word_append 2>/dev/null
    # Modules the search loaded go back to their autoloaded state.
    for module in ${=state[modules]-}; do
      zmodload -e "$module" && zmodload -u "$module" 2>/dev/null
    done
    if [[ -n ${state[fpath]-} ]] && (( ${fpath[(Ie)${state[fpath]}]} )); then
      fpath[${fpath[(ie)${state[fpath]}]}]=()
    fi

    builtin unfunction -m 'history-search-multi-word' '_history_search_multi_word_*' 2>/dev/null
    builtin unset -m '_history_search_multi_word_*'
    builtin unfunction history-search-multi-word_plugin_unload H-S-MW_plugin_unload 2>/dev/null
    return 0
  }

  # Zi calls <repository>_plugin_unload, so `zi unload z-shell/H-S-MW` needs
  # this name; it only forwards to the function above.
  H-S-MW_plugin_unload() { history-search-multi-word_plugin_unload "$@" }

  # Widgets and key bindings belong to the line editor of an interactive shell.
  [[ -o interactive ]] || return 0

  # Bind Ctrl-R in the keymap main names now, so a later bindkey -e or -v does
  # not move it, and record what it did there. A builtin's output can only be
  # read through a subshell; this is the one the load costs.
  local keymap=main
  local -a listing words
  listing=( "${(@f)$(builtin bindkey -lL main; builtin bindkey -M main -L '^R')}" ) 2>/dev/null
  words=( "${(@Q)${(z)listing[1]-}}" )
  # bindkey -A KEYMAP main
  [[ ${words[1]-} == bindkey && ${words[2]-} == -A && ${words[4]-} == main ]] && keymap=${words[3]}
  _history_search_multi_word_state[keymap]=$keymap
  # bindkey [-s] -M KEYMAP "^R" WIDGET-OR-STRING
  words=( "${(@Q)${(z)listing[2]-}}" )
  if [[ ${words[2]-} == -s ]]; then
    _history_search_multi_word_state[ctrl_r_kind]=string
    _history_search_multi_word_state[ctrl_r]=${words[-1]}
  elif [[ -n ${words[-1]-} && ${words[-1]} != (undefined-key|history-search-multi-word) ]]; then
    _history_search_multi_word_state[ctrl_r_kind]=widget
    _history_search_multi_word_state[ctrl_r]=${words[-1]}
  fi
  if ! {
    builtin zle -N history-search-multi-word &&
      builtin zle -N history-search-multi-word-backwards history-search-multi-word &&
      builtin zle -N history-search-multi-word-pbackwards history-search-multi-word &&
      builtin zle -N history-search-multi-word-pforwards history-search-multi-word &&
      builtin bindkey -M "$keymap" '^R' history-search-multi-word
  } 2>/dev/null; then
    print -u2 -r -- "history-search-multi-word: cannot create its widgets; the plugin is not loaded"
    history-search-multi-word_plugin_unload
    return 1
  fi
} "${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
