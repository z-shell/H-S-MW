#!/usr/bin/env zsh
#
# Exact lifecycle: after load (and a search, in an interactive shell) the
# unload function returns the shell to its pre-load state, keeps state the
# user changed after loading, survives a failed load, and a second load
# works again.

emulate -R zsh
setopt pipe_fail extended_glob
typeset +x FPATH

source -- "${${(%):-%N}:A:h}/lib/session.zsh"

typeset -r plugin=$hsmw_test_root/H-S-MW.plugin.zsh

# Shell code that writes a description of the observable shell state to $1.
# Parameters are recorded by name and type, not value, so counters such as
# SECONDS do not count as differences, and without reading them, so module
# parameters such as terminfo stay unloaded. The observer runs once before any
# baseline: reading parameter types and styles autoloads modules (zsh/watch,
# zsh/zle, zsh/zutil) that must not be attributed to the plugin. Two more
# modules are primed: ZLE loads zsh/complete on the first edit, and
# zsh/zutil provides zstyle, which a user's configuration of the plugin loads
# before the plugin. The plugin must never unload zsh/zutil: it holds every
# style the user has set.
typeset -r snapshot_fragment='
zmodload zsh/parameter zsh/complete zsh/zutil
hsmw_test_snapshot() {
  emulate -L zsh
  local LC_ALL=C key
  local -a names=( ${(ok)functions} )
  {
    print -r -- "functions $names"
    # typeset + gives names and types without autoloading module parameters.
    print -r -- "parameters"; typeset +
    for key in ${(ok)aliases}; do print -r -- "alias $key=${aliases[$key]}"; done
    for key in ${(ok)options}; do print -r -- "option $key=${options[$key]}"; done
    for key in ${(ok)modules}; do print -r -- "module $key=${modules[$key]}"; done
    print -r -- "fpath $fpath"
    print -r -- "path $path"
    print -r -- "math $(functions -M)"
    print -r -- "traps $(trap)"
    print -r -- "styles $(zstyle -L)"
    print -r -- "keymaps $(bindkey -l 2>/dev/null)"
    # Each keymap separately: main is only an alias that bindkey -e or -v moves.
    print -r -- "main $(bindkey -lL main 2>/dev/null)"
    for key in emacs viins vicmd; do print -r -- "keymap $key $(bindkey -M $key -L 2>/dev/null)"; done
    print -r -- "widgets $(zle -lL 2>/dev/null)"
  } >| $1
}
hsmw_test_snapshot /dev/null
'

# same_state NAME BEFORE AFTER: the two snapshots are identical.
same_state() {
  local name=$1 before=$2 after=$3 difference
  if [[ ! -r $before || ! -r $after ]]; then
    hsmw_test_fail "$name: a snapshot is missing"
    return 1
  fi
  difference=$(command diff -- "$before" "$after")
  [[ -z $difference ]] || {
    hsmw_test_fail "$name: the shell differs from its pre-load state:"$'\n'"$difference"
    return 1
  }
}

# in_clean_shell NAME SCRIPT [ZSH_FLAG...]: run SCRIPT in a clean shell and
# compare its before and after snapshots. With -i the shell is interactive, so
# loading creates the widgets and the Ctrl-R binding, though no line editor
# runs; searches need the zpty sessions below.
in_clean_shell() {
  local name=$1 script=$2 dir=$hsmw_test_tmp/$1 out
  shift 2
  command mkdir -p -- "$dir" || { hsmw_test_fail "$name: cannot create $dir"; return 1 }
  out=$(command env -u FPATH -u PMSPEC -u EDITOR -u VISUAL HOME=$dir ZDOTDIR=$dir \
    "${TEST_ZSH:-zsh}" -f "$@" -c "$snapshot_fragment
$script" 2>&1 </dev/null) || { hsmw_test_fail "$name: $out"; return 1 }
  same_state "$name" "$dir/before" "$dir/after" && hsmw_test_pass "$name"
}

# Sourcing twice, then unloading once, leaves nothing behind.
in_clean_shell unload-after-repeated-source "
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}; source ${(q)plugin}
  history-search-multi-word_plugin_unload
  hsmw_test_snapshot \$HOME/after"
in_clean_shell unload-after-repeated-source-interactive "
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}; source ${(q)plugin}
  history-search-multi-word_plugin_unload
  hsmw_test_snapshot \$HOME/after" -i

# Ctrl-R is bound in the keymap main named at load time, and restored there
# even after main has been moved to another keymap.
in_clean_shell unload-after-keymap-switch "
  bindkey -e
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}
  bindkey -v
  history-search-multi-word_plugin_unload
  bindkey -e
  hsmw_test_snapshot \$HOME/after" -i

# A string binding on Ctrl-R comes back as the same string.
in_clean_shell unload-string-binding "
  bindkey -s '^R' 'echo hi'
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}
  history-search-multi-word_plugin_unload
  hsmw_test_snapshot \$HOME/after" -i

# Ctrl-R already running the plugin's widget before load (the manual setup
# the widget's header describes) is unbound, not left on a deleted widget.
typeset dir=$hsmw_test_tmp/unload-already-bound
command mkdir -p -- $dir
out=$(command env -u FPATH -u PMSPEC -u EDITOR -u VISUAL HOME=$dir ZDOTDIR=$dir "${TEST_ZSH:-zsh}" -f -i -c "
  zle -N history-search-multi-word
  bindkey '^R' history-search-multi-word
  source ${(q)plugin}
  history-search-multi-word_plugin_unload
  bindkey -M emacs '^R'" 2>&1 </dev/null)
[[ $out == '"^R" undefined-key' ]] && hsmw_test_pass unload-already-bound ||
  hsmw_test_fail "unload-already-bound: Ctrl-R is [$out], expected it unbound"

# The same for any of the plugin's widgets, such as the backwards one.
dir=$hsmw_test_tmp/unload-already-bound-sibling
command mkdir -p -- $dir
out=$(command env -u FPATH -u PMSPEC -u EDITOR -u VISUAL HOME=$dir ZDOTDIR=$dir "${TEST_ZSH:-zsh}" -f -i -c "
  zle -N history-search-multi-word-backwards history-search-multi-word
  bindkey '^R' history-search-multi-word-backwards
  source ${(q)plugin}
  history-search-multi-word_plugin_unload
  bindkey -M emacs '^R'" 2>&1 </dev/null)
[[ $out == '"^R" undefined-key' ]] && hsmw_test_pass unload-already-bound-sibling ||
  hsmw_test_fail "unload-already-bound-sibling: Ctrl-R is [$out], expected it unbound"

# A plugin that wraps every widget (zsh-autosuggestions does, on each precmd)
# replaces the public widget and keeps a copy under its own name. Unload
# removes the plugin's widgets by name and leaves the wrapper's copy and a
# user's alias alone.
dir=$hsmw_test_tmp/unload-wrapped-widget
command mkdir -p -- $dir
out=$(command env -u FPATH -u PMSPEC -u EDITOR -u VISUAL HOME=$dir ZDOTDIR=$dir "${TEST_ZSH:-zsh}" -f -i -c "
  source ${(q)plugin}
  zle -A history-search-multi-word my-alias
  zle -A history-search-multi-word wrapper-orig-history-search-multi-word
  _wrap() { zle wrapper-orig-history-search-multi-word }
  zle -N history-search-multi-word _wrap
  history-search-multi-word_plugin_unload
  zle -lL" 2>&1 </dev/null)
if [[ $out == *'zle -N history-search-multi-word '* ]]; then
  hsmw_test_fail "unload-wrapped-widget: the public widget survives unload: $out"
elif [[ $out != *'zle -N my-alias '* || $out != *'zle -N wrapper-orig-history-search-multi-word '* ]]; then
  hsmw_test_fail "unload-wrapped-widget: unload deleted widgets it does not own: $out"
else
  hsmw_test_pass unload-wrapped-widget
fi

in_clean_shell unload "
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}
  history-search-multi-word_plugin_unload
  hsmw_test_snapshot \$HOME/after"

in_clean_shell zi-unload "
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}
  H-S-MW_plugin_unload
  hsmw_test_snapshot \$HOME/after"

in_clean_shell unload-hostile-options "
  setopt ksh_arrays sh_word_split glob_subst no_function_argzero
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}
  history-search-multi-word_plugin_unload
  hsmw_test_snapshot \$HOME/after"

# A functions/ entry a manager added stays where it was.
in_clean_shell unload-keeps-manager-fpath "
  fpath+=( ${(q)hsmw_test_root}/functions )
  hsmw_test_snapshot \$HOME/before
  source ${(q)plugin}
  history-search-multi-word_plugin_unload
  hsmw_test_snapshot \$HOME/after"

# Interactive: the search itself creates widgets, a keymap, a math function
# and may load modules. Unload after a search must remove all of it.
run_interactive() {
  local name=$1 fragment=$2
  shift 2
  hsmw_test_session "$name" "$snapshot_fragment
print -s 'echo first'
print -s 'ls -la /tmp'
$fragment" "$@"
}

typeset dir
dir=$hsmw_test_tmp/unload-after-search
run_interactive unload-after-search '' \
  " hsmw_test_snapshot ${(q)dir}/before; source -- ${(q)plugin}" $'\r' \
  $'\C-r' 'ls' $'\C-v' $'\C-u' \
  " history-search-multi-word_plugin_unload; hsmw_test_snapshot ${(q)dir}/after" $'\r' $'\C-xa' &&
  same_state unload-after-search $dir/before $dir/after &&
  hsmw_test_pass unload-after-search

# Load, unload, load: the second load searches again.
run_interactive reload "source -- ${(q)plugin}" \
  $'\C-r' 'ls' $'\C-v' $'\C-u' \
  " history-search-multi-word_plugin_unload; source -- ${(q)plugin}" $'\r' \
  $'\C-r' 'ls' $'\r' $'\C-xa' && {
  [[ $(hsmw_test_field "${reply[(r)a\|*]}" buffer) == 'ls -la /tmp' ]] &&
    hsmw_test_pass reload ||
    hsmw_test_fail "reload: Ctrl-R does not search after a second load: ${reply[(r)a\|*]}"
}

# A Ctrl-R binding the user made after loading survives unload.
dir=$hsmw_test_tmp/user-binding
run_interactive user-binding "source -- ${(q)plugin}" \
  " bindkey '^R' redisplay; history-search-multi-word_plugin_unload; bindkey -M main '^R' >| ${(q)dir}/binding" $'\r' $'\C-xa' && {
  [[ $(<$dir/binding) == '"^R" redisplay' ]] &&
    hsmw_test_pass user-binding ||
    hsmw_test_fail "user-binding: unload changed the user's binding: $(<$dir/binding)"
}

# A load that cannot create its widgets fails with a diagnostic and leaves
# nothing behind.
dir=$hsmw_test_tmp/failed-load
run_interactive failed-load "
disable zle
hsmw_test_snapshot ${(q)dir}/before
source -- ${(q)plugin} 2>| ${(q)dir}/stderr
print -r -- \$? >| ${(q)dir}/status
hsmw_test_snapshot ${(q)dir}/after
enable zle" $'\C-xa' && {
  [[ $(<$dir/status) == 1 ]] ||
    hsmw_test_fail "failed-load: source returned $(<$dir/status), expected 1"
  [[ $(<$dir/stderr) == *'cannot create its widgets'* ]] ||
    hsmw_test_fail "failed-load: no diagnostic: $(<$dir/stderr)"
  same_state failed-load $dir/before $dir/after && hsmw_test_pass failed-load
}

exit $hsmw_test_status
