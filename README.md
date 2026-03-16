# claude-safe

Sandboxed Claude Code launcher. Runs Claude Code inside Docker containers with tmux session management and git worktree isolation.

## Architecture

```
host shell
  └─ claude-safe
       └─ docker run -d (container: sleep infinity)
            └─ tmux
                 ├─ window 1: claude    ← main session
                 ├─ window 2: bash      ← user splits
                 └─ window 3: claude    ← user spawns another
```

tmux runs **inside** the container. Every pane and window is sandboxed. `Ctrl-b d` detaches back to the host — the container keeps running. `claude-safe` reattaches.

## Why

Claude Code has unrestricted shell access. Running it on a bare host means it can `rm -rf`, read secrets, install packages globally, or modify system configs. claude-safe puts it in a container with explicit mount controls:

- **Workspace:** read-write (your project only)
- **~/.claude:** granular ro/rw (settings ro, session state rw)
- **~/.kube, ~/.ssh, ~/.gitconfig:** read-only
- **~/Code:** read-only cross-project reference
- **Everything else:** not mounted

## Requirements

- Docker (OrbStack recommended on macOS, Docker Engine on Linux)
- Git
- Bash 4+

tmux is included in the container image — not needed on the host.

## Install

```bash
./claude-safe install
```

The installer detects your environment, prompts for each option with sensible defaults, writes `~/.config/claude-safe/config.sh`, installs the script, and builds the Docker image. Run `claude-safe install` again anytime to reconfigure.

<details>
<summary>Manual install</summary>

```bash
# 1. Build the image
docker build -t claude-safe -f Dockerfile.claude-safe .

# 2. Install the script
cp claude-safe ~/.local/bin/claude-safe
chmod +x ~/.local/bin/claude-safe

# 3. Copy config
mkdir -p ~/.config/claude-safe
cp config.example.sh ~/.config/claude-safe/config.sh
# Edit to match your setup

# 4. (Optional) tmux config for remote access
cp tmux.conf ~/.config/claude-safe/tmux.conf

# 5. Verify
claude-safe doctor
```

</details>

## Usage

### Quick start

```bash
cd ~/Code/my-project
claude-safe              # launch or reattach
# Ctrl-b d              # detach
claude-safe              # reattach
claude-safe stop         # stop container
```

### Parallel agents with worktrees

```bash
claude-safe new fix-auth "fix JWT refresh race condition"
claude-safe new add-tests
claude-safe new refactor-api

claude-safe ls           # see all containers + sessions
claude-safe start fix-auth

claude-safe merge fix-auth --squash
claude-safe rm fix-auth  # stop + delete worktree + branch
```

### Commands

| Command | Description |
|---|---|
| `claude-safe` | Smart launch: reattach or create session |
| `claude-safe new <branch> [prompt]` | Create worktree + container + session |
| `claude-safe start <branch>` | Reattach to worktree session |
| `claude-safe stop [branch]` | Stop container (current dir or branch) |
| `claude-safe ls` | List worktrees, containers, tmux sessions |
| `claude-safe rm <branch>` | Full cleanup: container + worktree + branch |
| `claude-safe merge <branch> [--squash]` | Merge worktree into current branch |
| `claude-safe shell [branch]` | Bash into container (no tmux) |
| `claude-safe dash` | Container overview |
| `claude-safe install` | Interactive installer / reconfigure |
| `claude-safe config` | Show resolved configuration |
| `claude-safe doctor` | Verify dependencies and config |
| `claude-safe --raw` | Disposable container, no tmux |

### tmux keys (inside the container)

| Keys | Action |
|---|---|
| `Ctrl-b \|` | Split vertical |
| `Ctrl-b -` | Split horizontal |
| `Ctrl-b c` | New window |
| `Alt-1..5` | Switch window by number |
| `Alt-arrows` | Switch panes |
| `Ctrl-b z` | Zoom/unzoom pane |
| `Ctrl-b d` | Detach |

## Files

```
claude-safe              main script (~850 lines bash)
Dockerfile.claude-safe    container image (K8s + dev tools + tmux)
config.example.sh        example configuration
tmux.conf                tmux config optimized for remote tmux sessions
CHEATSHEET.md            quick reference
CLAUDE.md                instructions for Claude Code working on this repo
```

## Configuration

All settings live in `~/.config/claude-safe/config.sh`. Key options:

```bash
CLAUDE_SAFE_TEMPLATE="claude-safe"     # Docker image to use
CLAUDE_SAFE_NETWORK="host"            # host networking (for Tailscale/K8s)
CLAUDE_SAFE_MOUNT_KUBE=true           # mount ~/.kube read-only
CLAUDE_SAFE_MOUNT_SSH=true            # mount ~/.ssh read-only
CLAUDE_SAFE_HOST_ENV="GH_TOKEN"       # forward env vars into container
CLAUDE_SAFE_TMUX_CONF="~/.config/claude-safe/tmux.conf"
```

See `config.example.sh` for all options with descriptions.

### Credential handling

On macOS, Claude Code stores OAuth tokens in Keychain. claude-safe extracts them at launch and writes to `~/.claude/.credentials.json` (user-only permissions). The file is bind-mounted into the container.

Host environment variables listed in `CLAUDE_SAFE_HOST_ENV` are forwarded via `docker run -e` at launch time — never written to disk.

## Container image

`Dockerfile.claude-safe` extends `docker/sandbox-templates:shell` with:

- **K8s:** kubectl, helm, k9s, stern, yq
- **Dev:** ripgrep, fd, shellcheck, build-essential, gh, delta
- **DB:** postgresql-client
- **Session:** tmux, ncurses-term
- **Locale:** en_US.UTF-8

Multi-arch: builds natively on arm64 (Apple Silicon) and amd64.

```bash
docker build -t claude-safe -f Dockerfile.claude-safe .
```

## Remote workflow

```
Remote terminal → SSH/Mosh/any → host (tmux inside container)
```

1. Connect to the host via SSH, Mosh, or any remote terminal
2. Configure `CLAUDE_SAFE_TMUX_CONF` to point to `tmux.conf`
3. From remote: `claude-safe`
4. `Ctrl-b d` to detach, disconnect, reconnect anytime

tmux inside the container survives reconnects. The container survives everything until explicitly stopped.
