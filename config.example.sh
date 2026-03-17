#!/usr/bin/env bash
# config.example.sh
# Example configuration for claude-safe
# Copy to ~/.config/claude-safe/config.sh and customize

# ────────────────────────────────────────────────────────────────────────────
# Sandbox Configuration
# ────────────────────────────────────────────────────────────────────────────

# Sandbox isolation mode
# - "docker" (default): Standard Docker containers
# - "docker-sandbox": Enhanced isolation (if available)
# - "none": No sandboxing (run claude directly on host)
CLAUDE_SAFE_SANDBOX_MODE="docker"

# Docker image template to use for containers
# Default: uses official anthropics/claude-code image
# Set to custom image name (e.g., "claude-safe") for extended tooling
CLAUDE_SAFE_TEMPLATE=""

# Credential injection method
# - "host" (default): Use host credentials (Keychain on macOS)
# - Other values reserved for future use
CLAUDE_SAFE_CREDENTIALS="host"

# Container network mode
# - "host" (default): Container shares host network stack (best for k8s/Tailscale)
# - "bridge": Isolated network with port mapping
CLAUDE_SAFE_NETWORK="host"

# ────────────────────────────────────────────────────────────────────────────
# Mount Options
# ────────────────────────────────────────────────────────────────────────────

# Mount ~/.kube (read-only) for kubectl access
CLAUDE_SAFE_MOUNT_KUBE=true

# Limit kube access to specific contexts (colon-separated)
# Empty (default) mounts entire ~/.kube directory
# When set, builds a filtered kubeconfig with only the named contexts
# Example: "homelab:staging"
CLAUDE_SAFE_KUBE_PROFILES=""

# Mount ~/.claude with granular read-only/read-write permissions
# Base mount is read-only; specific subdirs get rw (projects, plans, todos, etc.)
CLAUDE_SAFE_MOUNT_CLAUDE=true

# Mount ~/.ssh (read-only) for git operations over SSH
CLAUDE_SAFE_MOUNT_SSH=true

# SSH access mode (requires CLAUDE_SAFE_MOUNT_SSH=true)
# - "agent" (default): Forward SSH_AUTH_SOCK only + mount config/known_hosts read-only
#             Exposes signing capability only — private keys never enter container
# - "keys": Mount entire ~/.ssh read-only (legacy behavior, exposes private keys)
CLAUDE_SAFE_SSH_MODE="agent"

# Read-only directories mounted at /home/agent/<basename> (colon-separated)
# Example: "$HOME/Code:$HOME/Work:$HOME/go/src"
CLAUDE_SAFE_RO_DIRS="$HOME/Code"

# Read-write directories mounted at /home/agent/<basename> (colon-separated)
# Example: "$HOME/.cargo/registry"
CLAUDE_SAFE_RW_DIRS=""

# Mount ~/.gitconfig (read-only) for git user identity
CLAUDE_SAFE_MOUNT_GITCONFIG=true

# Mount ~/.config/gh (read-only) for GitHub CLI authentication
CLAUDE_SAFE_MOUNT_GH=true

# Mount Tailscale socket for direct VPN access from container
# Only needed if container must establish Tailscale connections
# (Usually not needed if using NETWORK=host)
CLAUDE_SAFE_MOUNT_TAILSCALE=false

# Mount Docker socket for Docker-in-Docker workflows
# Options: false (default), proxy, true
#   false  — no Docker access from container
#   proxy  — filtered API access via socket proxy (recommended if needed)
#            Allows: build, images, containers, volumes, networks
#            Blocks: exec, auth, swarm, system, secrets, plugins
#   true   — full socket mount (requires CLAUDE_SAFE_DOCKER_SOCKET_CONFIRM=true)
#            ⚠️  WARNING: full host root access — container can escape sandbox
CLAUDE_SAFE_DOCKER_SOCKET=false
# CLAUDE_SAFE_DOCKER_SOCKET_CONFIRM=true  # required when DOCKER_SOCKET=true

# Auto-allow direnv .envrc files without requiring 'direnv allow'
# Safe inside containers since the container IS the sandbox
# Set to false to require explicit 'direnv allow' per directory
CLAUDE_SAFE_DIRENV_AUTO_ALLOW=true

# Additional volume mounts (space-separated)
# Format: "host_path:container_path:mode host_path2:container_path2:mode"
# Example: "$HOME/.npm:/home/agent/.npm:ro $HOME/.cache:/home/agent/.cache:rw"
CLAUDE_SAFE_EXTRA_VOLUMES=""

# ────────────────────────────────────────────────────────────────────────────
# Environment Variables
# ────────────────────────────────────────────────────────────────────────────

# Host environment variable NAMES to forward into container (space-separated)
# Values are read from your shell at launch time — never stored in config
# Example: "GH_TOKEN ANTHROPIC_API_KEY NPM_TOKEN"
# Tip: Define these in ~/.zshrc or a sourced secrets file
CLAUDE_SAFE_HOST_ENV=""

# Static environment variables for container (space-separated KEY=VALUE pairs)
# Use for non-secret configuration, feature flags, etc.
# Example: "NODE_ENV=development CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
CLAUDE_SAFE_EXTRA_ENV=""

# ────────────────────────────────────────────────────────────────────────────
# Resource Limits
# ────────────────────────────────────────────────────────────────────────────

# Memory limit for containers (Docker format: "512m", "2g", etc.)
# Unset (default) means no limit
CLAUDE_SAFE_MEMORY=""

# CPU limit for containers (fractional cores: "0.5", "2", etc.)
# Unset (default) means no limit
CLAUDE_SAFE_CPUS=""

# ────────────────────────────────────────────────────────────────────────────
# Git Worktree & tmux
# ────────────────────────────────────────────────────────────────────────────

# Enable tmux session management (default: true)
# When false, claude-safe launches claude directly in an ephemeral container
# (like --raw) — no detach/reattach, no multi-session. Worktrees still work.
CLAUDE_SAFE_TMUX=true

# Directory name for git worktrees (relative to project root)
# claude-safe creates branch worktrees here for isolation
CLAUDE_SAFE_WORKTREE_DIR=".worktrees"

# tmux session prefix for auto-generated session names
# Sessions are named: {prefix}-{project}-{branch}
CLAUDE_SAFE_TMUX_PREFIX="cs"

# Setup hook script to run after creating worktree/session
# Path relative to project root. Runs inside container before launching claude.
# Example: ".cmux/setup" could install deps, start services, etc.
CLAUDE_SAFE_SETUP_HOOK=".cmux/setup"

# ────────────────────────────────────────────────────────────────────────────
# Claude Configuration
# ────────────────────────────────────────────────────────────────────────────

# Permission mode for Claude Code sessions
# - "" (default): Normal permission prompts
# - "bypass": Adds --dangerously-skip-permissions --allow-dangerously-skip-permissions (use --dangerous flag for one-off)
# Container isolation makes bypass mode safer — the container IS the sandbox
CLAUDE_SAFE_PERMISSION_MODE=""

# Additional arguments passed to claude command
# Example: "--model sonnet"
CLAUDE_SAFE_CLAUDE_ARGS=""

# ────────────────────────────────────────────────────────────────────────────
# tmux Configuration
# ────────────────────────────────────────────────────────────────────────────

# Custom tmux config file to mount in container
# Unset (default) uses container's default /etc/tmux.conf
# Example: "$HOME/.config/claude-safe/tmux.conf"
CLAUDE_SAFE_TMUX_CONF=""

# Path where tmux config is mounted inside container
# Only change if you have conflicts with container's existing config
CLAUDE_SAFE_CONTAINER_TMUX_CONF="/etc/tmux.conf"

# ────────────────────────────────────────────────────────────────────────────
# Notifications & Clipboard
# ────────────────────────────────────────────────────────────────────────────

# Command to run when tmux session exits (notifications)
# Receives session name as final argument
# Examples:
#   "terminal-notifier -title claude-safe -message"  # macOS notifications
#   "curl -s -d 'Claude finished' ntfy.sh/YOUR_TOPIC"  # ntfy.sh
CLAUDE_SAFE_NOTIFY_CMD=""

# ────────────────────────────────────────────────────────────────────────────
# Maintenance
# ────────────────────────────────────────────────────────────────────────────

# Automatically remove containers when tmux session exits
# Disable if you want to inspect container state after sessions end
CLAUDE_SAFE_AUTO_CLEANUP=true

# Seconds between automatic image rebuilds from Dockerfile.claude-safe
# Default 86400 = once per day. Fast no-op if Dockerfile hasn't changed.
# Set to 0 to rebuild every launch, or -1 to never auto-build.
CLAUDE_SAFE_BUILD_INTERVAL=86400

# Check for Claude Code version updates at new session creation
# Compares installed version against npm registry; warns if stale.
# Disable if you're offline or want to skip the network check.
CLAUDE_SAFE_VERSION_CHECK=true
