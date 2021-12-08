# No plugin manager is needed to use this file. All that is needed is adding:
#   source {where-unpacked}/history-search-multi-word.plugin.zsh to ~/.zshrc.
#

# According to the standard:
# https://github.com/z-shell/zi/wiki/Zsh-Plugin-Standard
0="${${ZERO:-${0:#$ZSH_ARGZERO}}:-${(%):-%N}}"
0="${${(M)0:#/*}:-$PWD/$0}"

HSMW_REPO_DIR="${0:h}"

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
