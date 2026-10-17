# AGENTS.md - z-shell/H-S-MW

AI agent orientation for this repository.
Organization policy is owned by [`z-shell/.github` `AGENTS.md`](https://github.com/z-shell/.github/blob/main/AGENTS.md); read it before non-trivial work. This file narrows implementation detail and never overrides it.

## What this repo is

A Zsh plugin that binds <kbd>Ctrl-R</kbd> to a multi-word, syntax-highlighted history search. It is consumed directly from Git via Zi or any other Zsh plugin manager, or sourced without one.

## Release model

**Class 3 - git-consumed source.** Do not add release automation.

- Development and stable consumable branch: `main`.
- Releases: push a semver tag manually if a milestone needs marking.
- Reference: [org release runbook](https://github.com/z-shell/.github/blob/main/runbooks/release.md).

## Branching and commits

- All work branches from `main`, and pull requests target `main`.
- Branch names carry a type shape, such as `feature-<id>`, `bug-<id>` or `<type>/<slug>`.
- Commit format: [Conventional Commits](https://www.conventionalcommits.org/); see [decision 0003](https://github.com/z-shell/.github/blob/main/decisions/0003-conventional-commits.md).
- Branch model: [decision 0019](https://github.com/z-shell/.github/blob/main/decisions/0019-trunk-on-main-default.md).
- A `Co-authored-by` trailer may credit a real human, including the pull-request author. Never credit a bot, AI agent, or automation as a co-author.

## Plugin structure

| Path                                             | Purpose                                                                       |
| ------------------------------------------------ | ----------------------------------------------------------------------------- |
| `H-S-MW.plugin.zsh`                              | Entrypoint: fpath, autoloads, widgets, Ctrl-R binding and the unload function |
| `functions/history-search-multi-word`            | The search widget: matching, paging, display and the recursive edit           |
| `functions/_history_search_multi_word_context`   | Context view of the selected entry (Ctrl-K)                                   |
| `functions/_history_search_multi_word_highlight` | Highlighter for the result list; defines its helpers on first call            |
| `tests/test-*.zsh`                               | Standalone test files; each prints `ok:` or `FAIL:` lines                     |
| `tests/lib/session.zsh`                          | zpty harness that drives an isolated interactive shell                        |
| `docs/README.md`                                 | User-facing documentation, including the public shell surface                 |

Review the plugin against the [Z-Shell Plugin Standard](https://wiki.zshell.dev/community/zsh_plugin_standard), version 2:

- The project identifier is `history-search-multi-word`. Public names are the `history-search-multi-word` function, the four `history-search-multi-word*` widgets, the two style contexts and the unload functions; every other function, parameter, widget and saved copy is `_history_search_multi_word_*`.
- All configuration is read from `:history-search-multi-word` and `:history-search-multi-word:highlight` when a search starts. Do not add global configuration parameters or a second context.
- `history-search-multi-word_plugin_unload` must reverse every side effect of loading and searching. `H-S-MW_plugin_unload` exists only because Zi calls the unload function by repository name.
- The widget reads the caller's `ignore_braces`, `path_dirs`, `multi_func_def` and `interactive_comments` before `emulate` on purpose, so history is highlighted the way the user's shell parses it.
- While a search runs it pauses other plugins' ZLE hooks and replaces their widgets; everything is restored from an `always` block. Any new hook handling needs a case in `tests/test-zle-hooks.zsh`.

## Running tests

```zsh
# From the repository root.
for test in tests/test-*.zsh; do zsh -f "$test"; done
# Another Zsh for the shells under test:
TEST_ZSH=/path/to/zsh zsh -f tests/test-search.zsh
```

The supported floor is Zsh 5.8; CI runs the suites on 5.8.1 and 5.9.2 (`.github/workflows/tests.yml`). Run test shells without an inherited `FPATH`, or another installed copy of the plugin may be autoloaded instead of this checkout.

## Key org cross-references

- [PATTERNS.md](https://github.com/z-shell/.github/blob/main/PATTERNS.md) - established cross-repository idioms; do not copy retired entry-point snippets
- [z-shell/F-Sy-H](https://github.com/z-shell/F-Sy-H) - the highlighter this widget most often runs beside
- [GitHub issues](https://github.com/z-shell/H-S-MW/issues) and [pull requests](https://github.com/z-shell/H-S-MW/pulls) - authoritative records for active, blocked, and deferred work

## Before starting non-trivial work

1. Check open issues and PRs in this repo.
2. Treat any Project 28 item only as a view of the owning GitHub issue or pull request, not as a separate authority.
3. Leave an `Agent handoff` comment on the relevant issue when work is unfinished or blocked.
