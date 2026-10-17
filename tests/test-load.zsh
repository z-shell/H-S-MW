#!/usr/bin/env zsh
#
# Load contract in clean processes: native syntax, repeated and hostile-option
# loading, and the absence of load-time side effects beyond the documented
# ones (fpath entry, autoload stubs and, in an interactive shell, the widgets
# and the Ctrl-R binding).

emulate -R zsh
setopt pipe_fail extended_glob
typeset +x FPATH

typeset -r root=${${(%):-%N}:A:h:h}
typeset -r plugin=$root/H-S-MW.plugin.zsh
typeset -r zsh_bin=${TEST_ZSH:-zsh}
integer test_status=0
typeset home
home=$(command mktemp -d "${TMPDIR:-/tmp}/hsmw-load.XXXXXXXX") || exit 2
trap 'command rm -rf -- "$home"' EXIT
trap 'command rm -rf -- "$home"; exit 130' HUP INT TERM

fail() { print -u2 -r -- "FAIL: $1"; test_status=1 }

# in_clean_shell NAME SCRIPT: run SCRIPT in `zsh -f`; it must print OK last.
in_clean_shell() {
  local name=$1 script=$2 out
  out=$(command env -u FPATH -u PMSPEC HOME=$home ZDOTDIR=$home "$zsh_bin" -f -c "$script" 2>&1)
  if [[ ${out##*$'\n'} == OK ]]; then
    print -r -- "ok: $name"
  else
    fail "$name: ${out:-<no output>}"
  fi
}

typeset -a sources=( $plugin $root/functions/*~*.zwc(N.) )
local file
for file in $sources; do
  out=$(command env -u FPATH "$zsh_bin" -f -n -- "$file" 2>&1)
  [[ -z $out ]] || fail "zsh -n ${file#$root/}: $out"
done
print -r -- "ok: native syntax of ${#sources} files"

in_clean_shell plain "source ${(q)plugin} && print OK"
in_clean_shell repeated "source ${(q)plugin} && source ${(q)plugin} && print OK"
# Under hostile options the plugin must still find its own directory: run
# from / so a wrong guess cannot land on the checkout by accident.
in_clean_shell hostile-options "cd /; setopt ksh_arrays sh_word_split glob_subst; source ${(q)plugin} || exit 1; autoload +X history-search-multi-word || exit 1; print OK"
in_clean_shell posix-argzero "cd /; setopt no_function_argzero posix_argzero; source ${(q)plugin} || exit 1; autoload +X history-search-multi-word || exit 1; print OK"

# The functions directory is added once, even when loaded twice, and found by
# autoload whatever the caller's working directory.
in_clean_shell fpath-once "
  cd /
  source ${(q)plugin}; source ${(q)plugin}
  [[ \${#\${(M)fpath:#${(q)root}/functions}} == 1 ]] || { print fpath=\$fpath; exit 1 }
  autoload +X history-search-multi-word || exit 1
  print OK"

# A manager that already put functions/ on fpath gets no second entry.
in_clean_shell fpath-manager "
  fpath+=( ${(q)root}/functions )
  PMSPEC=0fuUpiPs source ${(q)plugin}
  [[ \${#\${(M)fpath:#${(q)root}/functions}} == 1 ]] || { print fpath=\$fpath; exit 1 }
  print OK"

# An inherited PMSPEC must not stop a directly sourced plugin from loading.
in_clean_shell inherited-pmspec "
  export PMSPEC=0fuUpiPs
  source ${(q)plugin}
  autoload +X history-search-multi-word || exit 1
  print OK"

# Loading leaves no stray parameters, styles or modules behind, and options are
# unchanged.
in_clean_shell no-side-effects "
  zmodload zsh/parameter
  typeset -a params_before=( \${(k)parameters} ) modules_before=( \${(k)modules} )
  typeset -a styles_before=( \"\${(@f)\$(zstyle -L)}\" )
  typeset options_before=\${(kv)options}
  source ${(q)plugin}
  typeset -a new_params=( \${\${(k)parameters}:|params_before} )
  new_params=( \${new_params:#(params_before|modules_before|styles_before|options_before|_history_search_multi_word_state)} )
  (( \$#new_params == 0 )) || { print new parameters: \$new_params; exit 1 }
  typeset -a new_modules=( \${\${(k)modules}:|modules_before} )
  (( \$#new_modules == 0 )) || { print new modules: \$new_modules; exit 1 }
  [[ \"\${(@f)\$(zstyle -L)}\" == \"\$styles_before\" ]] || { print styles: \$(zstyle -L); exit 1 }
  [[ \${(kv)options} == \$options_before ]] || { print options changed; exit 1 }
  print OK"

# A non-interactive load defines no widgets and binds no keys.
in_clean_shell non-interactive "
  source ${(q)plugin}
  (( \${+widgets[history-search-multi-word]} == 0 )) || { print widget defined; exit 1 }
  print OK"

exit $test_status
