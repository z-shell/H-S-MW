#!/usr/bin/env zsh
#
# End-to-end behaviour of the search widget in an interactive shell: matching,
# selection, navigation, context view, cancellation and syntax highlighting of
# the result list.

emulate -R zsh
setopt pipe_fail extended_glob
typeset +x FPATH

source -- "${${(%):-%N}:A:h}/lib/session.zsh"

# History, oldest first; the search lists the newest match first.
typeset -r history_fragment="
print -s 'git commit -m one'
print -s 'echo between'
print -s 'grep commit notes.txt'
print -s 'git push origin'
print -s 'ls -la /tmp'
"
typeset -r load_fragment="source -- ${(q)hsmw_test_root}/H-S-MW.plugin.zsh"

# expect NAME PROBE FIELD PATTERN [MESSAGE]: the probe's field matches PATTERN.
expect() {
  local name=$1 probe=$2 field=$3 pattern=$4 line value
  line=${reply[(r)$probe\|*]}
  if [[ -z $line ]]; then
    hsmw_test_fail "$name: probe $probe did not run (${#reply} dump lines)"
    return 1
  fi
  value=$(hsmw_test_field "$line" "$field")
  [[ $value == ${~pattern} ]] || {
    hsmw_test_fail "$name: $field is [$value], expected [$pattern]"
    return 1
  }
}

run() {
  local name=$1 fragment=$2
  shift 2
  hsmw_test_session "$name" "$load_fragment
$fragment
$history_fragment" "$@"
}

# Accepting puts the newest matching entry in the buffer.
run select '' $'\C-r' 'ls' $'\r' $'\C-xa' &&
  expect select a buffer 'ls -la /tmp' && hsmw_test_pass select

# Words match in any order and all must be present.
run multi-word '' $'\C-r' 'commit git' $'\r' $'\C-xa' &&
  expect multi-word a buffer 'git commit -m one' && hsmw_test_pass multi-word

# A lower-case query ignores case; an upper-case letter makes it exact.
run case '' $'\C-r' 'GIT' $'\C-xa' $'\C-v' $'\C-r' 'GIt' $'\C-xb' $'\C-v' &&
  expect case a postdisplay '*No matches found*' &&
  expect case b postdisplay '*No matches found*' && hsmw_test_pass case
run case-insensitive '' $'\C-r' 'git push' $'\r' $'\C-xa' &&
  expect case-insensitive a buffer 'git push origin' && hsmw_test_pass case-insensitive

# Smart case: a lower-case query folds case, an upper-case letter does not.
hsmw_test_session smart-case "$load_fragment
print -s 'git push origin'
print -s 'Git Push upstream'" \
  $'\C-r' 'push' $'\C-xa' $'\C-v' $'\C-u' $'\C-r' 'Push' $'\C-xb' $'\C-v' &&
  expect smart-case a postdisplay '*Entry \#1 of 2*' &&
  expect smart-case b postdisplay '*Entry \#1 of 1*Git Push upstream*' && hsmw_test_pass smart-case

# Down moves to the next older match; Up from the first wraps to the last.
run navigate '' $'\C-r' 'git' $'\C-n' $'\r' $'\C-xa' &&
  expect navigate a buffer 'git commit -m one' && hsmw_test_pass navigate
run wrap '' $'\C-r' 'git' $'\C-p' $'\r' $'\C-xa' &&
  expect wrap a buffer 'git commit -m one' && hsmw_test_pass wrap

# The result list shows the entry count and marks the selection.
run listing '' $'\C-r' 'git' $'\C-xa' $'\C-n' $'\C-xb' $'\C-v' &&
  expect listing a postdisplay '*Entry \#1 of 2*>*git push origin*' &&
  expect listing b postdisplay '*Entry \#2 of 2*' && hsmw_test_pass listing

# Page down moves by the configured page size.
run page 'zstyle :history-search-multi-word page-size 2' \
  $'\C-r' '' $'\e[6~' $'\r' $'\C-xa' &&
  expect page a buffer 'grep commit notes.txt' && hsmw_test_pass page

# Ctrl-K shows the entry in context and Ctrl-K again returns to the list.
run context '' $'\C-r' 'push' $'\C-k' $'\C-xa' $'\C-k' $'\C-xb' $'\r' $'\C-xc' &&
  expect context a postdisplay '*Showing context of history entry*' &&
  expect context b postdisplay '*Ctrl-K – context*' &&
  expect context c buffer 'git push origin' && hsmw_test_pass context

# Cancelling keeps the query by default, or clears it when configured.
run cancel '' $'\C-r' 'git' $'\C-v' $'\C-xa' &&
  expect cancel a buffer 'git' && expect cancel a postdisplay '' &&
  hsmw_test_pass cancel
run clear-on-cancel 'zstyle :history-search-multi-word clear-on-cancel yes' \
  $'\C-r' 'git' $'\C-v' $'\C-xa' &&
  expect clear-on-cancel a buffer '' && hsmw_test_pass clear-on-cancel

# The result list is syntax highlighted below the buffer, unless disabled.
run highlight '' $'\C-r' 'ls' $'\C-xa' $'\C-v' &&
  expect highlight a region_highlight '*fg=green*fg=cyan*fg=magenta*' &&
  expect highlight a region_highlight '*bg=17*' && hsmw_test_pass highlight
run no-highlight 'zstyle :history-search-multi-word synhl no' \
  $'\C-r' 'ls' $'\C-xa' $'\C-v' &&
  expect no-highlight a region_highlight '^(*fg=magenta*)' &&
  expect no-highlight a region_highlight '*underline*' && hsmw_test_pass no-highlight

# Token styles come from the :history-search-multi-word:highlight context.
run token-style 'zstyle :history-search-multi-word:highlight command fg=red' \
  $'\C-r' 'ls' $'\C-xa' $'\C-v' &&
  expect token-style a region_highlight '*fg=red*' &&
  expect token-style a region_highlight '^(*fg=green*)' &&
  expect token-style a region_highlight '*fg=cyan*' && hsmw_test_pass token-style

# An empty token style falls back to its default.
run empty-token-style "zstyle :history-search-multi-word:highlight command ''" \
  $'\C-r' 'ls' $'\C-xa' $'\C-v' &&
  expect empty-token-style a region_highlight '*fg=green*' && hsmw_test_pass empty-token-style

# Paths matching a skip-paths pattern are not tested, so not shown as paths.
run skip-paths "zstyle :history-search-multi-word skip-paths '/t*'" \
  $'\C-r' 'ls' $'\C-xa' $'\C-v' &&
  expect skip-paths a region_highlight '^(*fg=magenta*)' &&
  expect skip-paths a region_highlight '*fg=green*fg=cyan*' && hsmw_test_pass skip-paths

# Version 2 reads one context: the former :plugin: context has no effect.
run former-context 'zstyle :plugin:history-search-multi-word synhl no' \
  $'\C-r' 'ls' $'\C-xa' $'\C-v' &&
  expect former-context a region_highlight '*fg=magenta*' && hsmw_test_pass former-context

# Editing the query restarts the search.
run edit-query '' $'\C-r' 'gix' $'\C-h' 't' $'\C-xa' $'\r' $'\C-xb' &&
  expect edit-query a postdisplay '*Entry \#1 of 2*' &&
  expect edit-query b buffer 'git push origin' && hsmw_test_pass edit-query

exit $hsmw_test_status
