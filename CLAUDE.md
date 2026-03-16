# CLAUDE.md

## Project overview

claude-safe is a bash script (~850 lines) that runs Claude Code inside Docker containers with in-container tmux session management, git worktree isolation, and credential forwarding. It targets macOS with OrbStack but also works with Docker Engine on Linux.

## Architecture

**Model A: tmux inside the container.** The container runs detached (`sleep infinity`). claude-safe uses `docker exec` to create and attach tmux sessions inside it. All panes and windows are sandboxed. No host shell leakage.

```
host: claude-safe → docker run -d (sleep infinity)
                  → docker exec tmux new-session → claude
                  ← docker exec tmux attach (reattach)
```

Key design decisions:
- Container lifecycle is independent of tmux sessions
- `_start_container()` creates the container, `_create_session()` creates tmux inside it
- `_attach_session()` is the only function that uses `exec` (replaces the host shell)
- `_add_docker_args()` uses bash dynamic scoping to append to the caller's `cmd` array
- Credentials are written to `~/.claude/.credentials.json` on the host, then bind-mounted in

## File structure

```
claude-safe              single-file bash script, all logic here (includes `install` subcommand)
Dockerfile.claude-safe    multi-arch image (ARG TARGETARCH for arm64/amd64)
config.example.sh        user config template
tmux.conf                tmux config for remote tmux sessions
CHEATSHEET.md            user-facing quick reference
README.md                project documentation
```

## Code conventions

### Bash style
- `set -euo pipefail` — strict mode, all scripts must pass `bash -n`
- ANSI-C quoting for colors: `RED=$'\033[0;31m'` not `RED='\033[0;31m'`
- Functions prefixed with `_` are internal, `cmd_` are subcommands
- Use `local` for all function variables
- Arithmetic: `ok=$((ok+1))` not `((ok++))` (the latter returns exit 1 when ok=0)
- Array building: `cmd+=()` pattern, expanded with `"${cmd[@]}"`

### Naming
- Container names: `cs-{parent_dir}-{basename}-{hash}` via `_container_name()`
- Session names: `cs-{project}-{branch}` via `_session_name()`
- Config vars: `CLAUDE_SAFE_*` prefix

### Docker patterns
- `_add_docker_args()` mutates caller's `cmd` array (dynamic scoping)
- Volume mounts: base `~/.claude:ro` with rw overlays for specific subdirs
- `.credentials.json` is always mounted separately, never in `CLAUDE_RW_FILES`
- `_inject_keychain_creds()` writes to host `~/.claude/.credentials.json` (macOS only)

### tmux interaction
- All tmux commands go through `docker exec <container> tmux ...`
- `new-session -d` creates detached session (no `-d` on the docker exec itself)
- `_attach_session()` uses `exec docker exec -it` to replace the shell
- tmux config is mounted at `/etc/tmux.conf` inside the container

## Common tasks

### Adding a new mount option
1. Add default in the "Defaults" section: `: "${CLAUDE_SAFE_MOUNT_THING:=false}"`
2. Add mount logic in `_build_volume_args()`
3. Add to `cmd_config()` display
4. Add check in `cmd_doctor()`
5. Document in `config.example.sh`

### Adding a new subcommand
1. Create `cmd_foo()` function
2. Add case in the main `case` block at the bottom
3. Add to help text
4. Add to completion words in `_cs_comp()`

### Adding a tool to the Docker image
1. Add to `Dockerfile.claude-safe` — use `${TARGETARCH}` for arch-specific URLs
2. For `.deb` packages, use `$(dpkg --print-architecture)`
3. For GitHub releases, use the API to get latest version
4. Clean up in the same RUN layer (`rm -rf /var/lib/apt/lists/*`)

## Testing

There are no automated tests. Validate changes with:

```bash
bash -n claude-safe                    # syntax check
claude-safe doctor                     # runtime checks
claude-safe config                     # verify config rendering
claude-safe --raw                      # test ephemeral launch
claude-safe                            # test full session lifecycle
claude-safe shell                      # test shell exec
claude-safe ls                         # test container/session listing
```

After editing the Dockerfile:
```bash
docker build -t claude-safe -f Dockerfile.claude-safe .
docker run --rm claude-safe tmux -V     # verify tmux
docker run --rm claude-safe locale      # verify UTF-8
docker run --rm claude-safe kubectl version --client  # verify tools
```

## Known gotchas

- `_build_claude_mounts()` returns space-separated args via `echo`. This breaks on paths with spaces. Current assumption: no spaces in `$HOME` or `$CLAUDE_HOME`.
- `docker exec -d` (detached) for tmux session creation races with subsequent `docker exec` calls that configure the session. Use `docker exec` (foreground) for `new-session -d` instead — tmux's `-d` detaches the session, docker's foreground ensures it completes before the next command.
- macOS Keychain extraction writes credentials to `~/.claude/.credentials.json` on the host filesystem. This is acceptable because the parent directory is user-only, but it means credentials persist on disk between runs.
- Container names are truncated to 63 chars. Hash suffix prevents collisions but names can be opaque.
- `sleep infinity` containers are orphan-prone if claude-safe crashes. `claude-safe ls` shows them; `claude-safe stop` or `docker rm -f` cleans up.
