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
# The scoped loader keeps every option and temporary parameter local.
# https://wiki.zshell.dev/community/zsh_plugin_standard#entrypoints-and-repository-layout
() {
  builtin emulate -L zsh

  local -r source_path=${1:a}
  local -r plugin_dir=${source_path:h}
  local -r functions_dir=$plugin_dir/functions

  # Add functions/ only when no manager or earlier load already did.
  if (( ! ${fpath[(Ie)$functions_dir]} )); then
    fpath+=( "$functions_dir" )
  fi

  autoload -Uz history-search-multi-word _history_search_multi_word_context _history_search_multi_word_highlight

  # Widgets and key bindings belong to the line editor of an interactive shell.
  [[ -o interactive ]] || return 0
  zle -N history-search-multi-word
  zle -N history-search-multi-word-backwards history-search-multi-word
  zle -N history-search-multi-word-pbackwards history-search-multi-word
  zle -N history-search-multi-word-pforwards history-search-multi-word
  bindkey "^R" history-search-multi-word
} "${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
