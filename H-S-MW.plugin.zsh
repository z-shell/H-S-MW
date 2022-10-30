#  ============================================================================  #
#  [ https://github.com/z-shell ] ❮ ZI ❯        [ (c) 2022 Z-SHELL COMMUNITY ]   #
#  ============================================================================  #
#
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# No plugin manager is needed to use this file. All that is needed is adding:
#   source {where-unpacked}/H-S-MW.plugin.zsh to ~/.zshrc.
#
# Standardized $0 Handling
# https://wiki.zshell.dev/community/zsh_plugin_standard#zero-handling
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

HSMW_REPO_DIR="${0:h}"

# Functions directory
# https://wiki.zshell.dev/community/zsh_plugin_standard#funtions-directory
if [[ $PMSPEC != *f* ]] {
  fpath+=( "${0:h}/functions" )
}

autoload history-search-multi-word hsmw-context-main
zle -N history-search-multi-word
zle -N history-search-multi-word-backwards history-search-multi-word
zle -N history-search-multi-word-pbackwards history-search-multi-word
zle -N history-search-multi-word-pforwards history-search-multi-word

[[ ${+termcap[Co]} = 1 && ${termcap[Co]} = 256 ]] && {
  zstyle -s ":history-search-multi-word" highlight-color tmp || zstyle ":history-search-multi-word" highlight-color "bg=17"
  typeset -gA HSMW_HIGHLIGHT_STYLES
  [[ ${HSMW_HIGHLIGHT_STYLES[variable]} = none ]] && HSMW_HIGHLIGHT_STYLES[variable]="fg=112"
}
bindkey "^R" history-search-multi-word
