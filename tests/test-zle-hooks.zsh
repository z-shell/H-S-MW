#!/usr/bin/env zsh
#
# The search runs a recursive edit and pauses other plugins' ZLE hooks while
# it owns the display. They must all be back once the search ends, whichever
# way it ends: syntax highlighters such as F-Sy-H paint from the
# line-pre-redraw hook, and lose every repaint after a single search if it is
# not restored.

emulate -R zsh
setopt pipe_fail
typeset +x FPATH

source -- "${${(%):-%N}:A:h}/lib/session.zsh"

typeset -r rc_fragment="
source -- ${(q)hsmw_test_root}/H-S-MW.plugin.zsh
autoload -Uz add-zle-hook-widget
typeset -gi hsmw_test_redraws=0
_hsmw_test_redraw() { hsmw_test_redraws+=1 }
_hsmw_test_keymap_select() { : }
zle -N _hsmw_test_redraw
zle -N _hsmw_test_keymap_select
add-zle-hook-widget line-pre-redraw _hsmw_test_redraw
add-zle-hook-widget keymap-select _hsmw_test_keymap_select
print -s 'echo first'
print -s 'ls -la /tmp'
"

# check_hooks NAME EXIT_KEY: search for "ls", leave the search with EXIT_KEY,
# then check that typing still runs the line-pre-redraw hook.
check_hooks() {
  local name=$1 exit_key=$2 before after
  integer failed=$hsmw_test_status
  hsmw_test_status=0
  hsmw_test_session "$name" "$rc_fragment" \
    $'\C-r' 'ls' "$exit_key" $'\C-u' $'\C-xa' 'x' $'\C-xb' || return
  before=${reply[(r)a\|*]} after=${reply[(r)b\|*]}
  if [[ -z $before || -z $after ]]; then
    hsmw_test_fail "$name: the probes did not run (${#reply} dump lines)"
    return
  fi
  [[ -n $(hsmw_test_field "$before" pre_redraw) ]] ||
    hsmw_test_fail "$name: the zle-line-pre-redraw widget is gone after the search"
  [[ -n $(hsmw_test_field "$before" keymap_select) ]] ||
    hsmw_test_fail "$name: the zle-keymap-select widget is gone after the search"
  (( $(hsmw_test_field "$after" redraws) > $(hsmw_test_field "$before" redraws) )) ||
    hsmw_test_fail "$name: typing after the search no longer runs the line-pre-redraw hook"
  (( hsmw_test_status )) || hsmw_test_pass "$name"
  (( hsmw_test_status |= failed ))
}

# check_no_leftovers NAME EXIT_KEY: the search paints the result list it shows
# below the buffer. Once it ends, none of those entries may remain: nobody else
# paints in this shell, so region_highlight must be empty. A highlighter that
# keeps other plugins' entries, as F-Sy-H does on Zsh 5.9, would otherwise
# repaint them over the buffer and over suggestions.
check_no_leftovers() {
  local name=$1 exit_key=$2 probe entries
  integer failed=$hsmw_test_status
  hsmw_test_status=0
  hsmw_test_session "$name" "$rc_fragment" $'\C-r' 'ls' "$exit_key" $'\C-xa' || return
  probe=${reply[(r)a\|*]}
  if [[ -z $probe ]]; then
    hsmw_test_fail "$name: the probe did not run (${#reply} dump lines)"
    return
  fi
  entries=$(hsmw_test_field "$probe" region_highlight)
  [[ -z $entries ]] ||
    hsmw_test_fail "$name: search highlights remain after the search: $entries"
  (( hsmw_test_status )) || hsmw_test_pass "$name"
  (( hsmw_test_status |= failed ))
}

# check_repaint NAME KEYS...: a highlighter that, like F-Sy-H, repaints only
# when BUFFER changed must find its paint again after a search that leaves
# the buffer as it was.
check_repaint() {
  local name=$1 before after
  integer failed=$hsmw_test_status
  hsmw_test_status=0
  shift
  hsmw_test_session "$name" "$rc_fragment
typeset -g hsmw_test_prior=
_hsmw_test_paint() {
  [[ \$BUFFER == \"\$hsmw_test_prior\" ]] && return 0
  hsmw_test_prior=\$BUFFER
  region_highlight=( \"0 \${#BUFFER} fg=red\" )
}
zle -N _hsmw_test_paint
add-zle-hook-widget line-pre-redraw _hsmw_test_paint" 'ls -la /tmp' $'\C-xa' "$@" $'\C-xb' || return
  before=${reply[(r)a\|*]} after=${reply[(r)b\|*]}
  if [[ -z $before || -z $after ]]; then
    hsmw_test_fail "$name: the probes did not run (${#reply} dump lines)"
    return
  fi
  [[ $(hsmw_test_field "$before" region_highlight) == '0 11 fg=red' ]] ||
    hsmw_test_fail "$name: the stub highlighter did not paint: $before"
  [[ $(hsmw_test_field "$after" region_highlight) == '0 11 fg=red' ]] ||
    hsmw_test_fail "$name: the line lost its highlighting: $(hsmw_test_field "$after" region_highlight)"
  (( hsmw_test_status )) || hsmw_test_pass "$name"
  (( hsmw_test_status |= failed ))
}

check_hooks accept $'\r'
check_hooks cancel $'\C-v'
check_repaint repaint-after-cancel $'\C-r' $'\C-v'
check_repaint repaint-after-same-entry $'\C-r' $'\r'
check_no_leftovers accept-leftovers $'\r'
check_no_leftovers cancel-leftovers $'\C-v'

exit $hsmw_test_status
