# claude-safe cheatsheet

## Lifecycle

```bash
cd ~/Code/my-project
claude-safe                    # launch or reattach
# Ctrl-b d                     # detach (container keeps running)
claude-safe                    # reattach
claude-safe stop               # stop container for current dir
claude-safe stop my-feature    # stop container for worktree
```

## Worktree workflow (parallel agents)

```bash
claude-safe new add-search "implement full-text search"
claude-safe new ui-polish
claude-safe new fix-tests

claude-safe ls                 # see all containers + sessions
claude-safe start add-search

claude-safe merge add-search --squash
claude-safe rm add-search  # stop container + delete worktree + branch
```

## Inside tmux (all sandboxed)

| Keys | Action |
|---|---|
| `Ctrl-b \|` | Split vertical (shell beside Claude) |
| `Ctrl-b -` | Split horizontal (shell below Claude) |
| `Ctrl-b c` | New window (shows on bottom bar) |
| `Alt-1` `Alt-2` `Alt-3` | Switch windows by number |
| `Alt-←` `Alt-→` `Alt-↑` `Alt-↓` | Switch panes |
| `Ctrl-b Shift-←/→/↑/↓` | Resize pane |
| `Ctrl-b d` | Detach (back to host, container stays running) |
| `Ctrl-b D` | Detach (explicit alternative to Ctrl-b d) |
| `Ctrl-b z` | Zoom pane (toggle fullscreen) |
| `Ctrl-b [` | Copy mode (vi keys, `v` select, `y` copy) |
| `Ctrl-b R` | Force redraw (fixes rendering glitches) |
| `Ctrl-b S` | Session chooser |

## Claude Code commands

| Command | What |
|---|---|
| `/model sonnet` or `/model opus` | Switch model mid-session |
| `/extra-usage` | Enable Opus 4.6 bonus usage |
| `/compact` | Compress context (do this before it gets too long) |
| `/clear` | Reset conversation |
| `/cost` | Show session cost |
| `/doctor` | Claude Code self-check |
| `Shift-Tab` | Cycle permission modes (ask/auto/bypass) |

## Effective patterns

**Start focused.** Give Claude a single clear task per session. Use worktrees for parallel work instead of context-switching one session.

```
claude-safe new fix-auth "fix the JWT refresh token race condition in auth.ts"
```

**Use CLAUDE.md.** Put project context, conventions, and constraints in `CLAUDE.md` at the repo root. Claude reads it automatically.

**Compact early.** Run `/compact` when context gets heavy (after ~20 tool uses). Don't wait for degraded responses.

**Bypass mode for trusted repos.** `Shift-Tab` to cycle to bypass mode when you trust the codebase. Saves confirmation fatigue.

**Let it run, detach, come back.** Start a long task, `Ctrl-b d` to detach, do something else. Reattach with `claude-safe`. The bottom bar highlights windows with new output.

**Shell pane for verification.** `Ctrl-b |` to split, run tests or check git status while Claude works in the other pane. Both are inside the container.

**Prompt with constraints, not steps.** Bad: "first do X, then Y, then Z." Good: "achieve X. constraints: must pass existing tests, don't modify the public API, use the existing logger."

## Troubleshooting

```bash
claude-safe doctor             # check deps, credentials, image
claude-safe config             # see resolved settings
claude-safe shell              # raw bash inside the running container
claude-safe --raw              # disposable container, no tmux (debugging)
```

**Container won't start:** `docker ps -a --filter label=claude-safe` → stale container? `claude-safe stop` then retry.

**"Not logged in":** Run `claude` on the host once to populate Keychain. `claude-safe doctor` checks this.

**Rendering glitch:** `Ctrl-b R` to redraw, or `Ctrl-l` inside a pane.

**Kill everything:** `docker rm -f $(docker ps --filter label=claude-safe -q)`
