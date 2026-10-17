# Drive an isolated interactive Zsh through zpty for widget tests.
#
# Sourced by the tests under tests/. The child shell runs with an empty HOME
# and ZDOTDIR, no inherited FPATH or PMSPEC (both are exported by plugin
# managers and would load another copy of the functions or skip fpath setup),
# and TEST_ZSH (default: zsh) as its binary.
#
# A test writes an rc fragment and a list of key chunks. The fragment can call
# `hsmw_test_dump LABEL`, which appends one line describing the editor state
# to the session's output file. Chunks are sent one at a time with a pause in
# between, so the editor redraws after each one instead of seeing typeahead.
# The child execs env: a forked shell left in between would inherit the EXIT
# trap below and delete the shared temporary directory when it is killed.

zmodload zsh/zpty || { print -u2 -r -- 'zsh/zpty is unavailable'; exit 2 }

typeset -gr hsmw_test_root=${${(%):-%N}:A:h:h:h}
typeset -g hsmw_test_tmp
hsmw_test_tmp=$(command mktemp -d "${TMPDIR:-/tmp}/hsmw-test.XXXXXXXX") || exit 2
trap 'command rm -rf -- "$hsmw_test_tmp"' EXIT HUP INT TERM
integer -g hsmw_test_status=0

hsmw_test_fail() {
  print -u2 -r -- "FAIL: $1"
  hsmw_test_status=1
}

hsmw_test_pass() {
  print -r -- "ok: $1"
}

# hsmw_test_session NAME RC_FRAGMENT CHUNK...
# Runs the session and leaves the dump lines in $reply.
hsmw_test_session() {
  emulate -L zsh
  local name=$1 fragment=$2 chunk line
  shift 2
  local dir=$hsmw_test_tmp/$name
  local out=$dir/out ready=$dir/ready
  integer deadline
  reply=()
  command mkdir -p -- "$dir" || return 1
  {
    print -r -- "PS1='> ' RPS1= PROMPT_EOL_MARK="
    print -r -- "unsetopt prompt_cr prompt_sp"
    print -r -- "HISTSIZE=100 SAVEHIST=0"
    print -r -- "typeset -g hsmw_test_nl=\$'\\n'"
    print -r -- "hsmw_test_dump() {"
    print -r -- "  print -r -- \"\$1|pre_redraw=\${widgets[zle-line-pre-redraw]-}|keymap_select=\${widgets[zle-keymap-select]-}|redraws=\${hsmw_test_redraws-0}|buffer=\$BUFFER|buffer_length=\${#BUFFER}|postdisplay=\${\${POSTDISPLAY//\$hsmw_test_nl/ }//|/ }|region_highlight=\${(j:,:)region_highlight}\" >> ${(q)out}"
    print -r -- "}"
    print -r -- "for _n in a b c d e f g; do eval \"_hsmw_test_dump_\$_n() { hsmw_test_dump \$_n }\"; zle -N _hsmw_test_dump_\$_n; bindkey \"^X\$_n\" _hsmw_test_dump_\$_n; bindkey -M emacs \"^X\$_n\" _hsmw_test_dump_\$_n; done; unset _n"
    print -r -- "precmd() { : >| ${(q)ready} }"
    print -r -- "$fragment"
  } >| $dir/.zshrc
  zpty -b "hsmw-$name" "exec env -u FPATH -u PMSPEC -u EDITOR -u VISUAL HOME=${(q)dir} ZDOTDIR=${(q)dir} TERM=xterm-256color LINES=40 COLUMNS=120 ${(q)${TEST_ZSH:-zsh}} -o no_global_rcs -i" || {
    hsmw_test_fail "$name: cannot start an interactive shell"
    return 1
  }
  deadline=$(( SECONDS + 15 ))
  while [[ ! -e $ready ]] && (( SECONDS < deadline )); do
    command sleep 0.05
    zpty -r -t "hsmw-$name" line >/dev/null 2>&1
  done
  [[ -e $ready ]] || {
    zpty -d "hsmw-$name"
    hsmw_test_fail "$name: the shell never reached its first prompt"
    return 1
  }
  command sleep 0.2
  for chunk in "$@"; do
    zpty -w -n "hsmw-$name" "$chunk"
    if [[ $chunk == $'\C-x'[a-g] ]]; then
      # A probe: wait for its dump line rather than for a fixed time.
      deadline=$(( SECONDS + 10 ))
      until [[ -r $out && -n ${(M)${(f)"$(<$out)"}:#${chunk[2]}\|*} ]] || (( SECONDS >= deadline )); do
        command sleep 0.05
        while zpty -r -t "hsmw-$name" line >/dev/null 2>&1; do :; done
      done
    else
      # Plain keys: pause so the editor redraws instead of seeing typeahead.
      command sleep 0.3
    fi
    while zpty -r -t "hsmw-$name" line >/dev/null 2>&1; do :; done
  done
  zpty -d "hsmw-$name"
  [[ -r $out ]] && reply=( "${(@f)$(<$out)}" )
  return 0
}

# hsmw_test_field LINE FIELD prints the value of one dump field.
hsmw_test_field() {
  emulate -L zsh
  local line=$1 field=$2
  local -a parts=( "${(@s:|:)line}" )
  local part
  for part in "${parts[@]}"; do
    [[ $part == $field=* ]] && { print -r -- "${part#*=}"; return 0 }
  done
  return 1
}
