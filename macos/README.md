# macOS Sandbox Helper

This directory contains a single script, `sandbox`, which launches a command inside a local `sandbox-exec` policy on macOS. The goal is to provide a lightweight constrained environment for terminal-based coding agents and shell sessions.

It is not a container runtime. It does not create a filesystem namespace, and it does not emulate Linux isolation semantics. It only applies a generated macOS sandbox policy around the launched process.

## Important Limitation

There is a known issue with some Rust-heavy agent applications, including Codex-like stacks, when they run inside nested container-style environments on macOS. Even when networking is nominally enabled, they may still fail to reach the network from inside the constrained environment.

Treat network-dependent workflows inside this sandbox as potentially unreliable. If you are working with Rust-based coding agents, LLM CLIs, or tools that open internal proxy connections, validate connectivity first and prefer conservative usage.

## Requirements

- macOS with `sandbox-exec` available
- `zsh`
- `awk`

The script checks these commands before launching.

## Quick Start

Open an interactive sandboxed shell in the current directory:

```bash
./sandbox
```

Run a single command inside the sandbox:

```bash
./sandbox git status
```

Run a tool with arguments:

```bash
./sandbox bash -lc 'pwd && ls'
```

The current working directory is added to the sandbox's writable path list by default.

## What the Script Does

At startup, the script:

- Validates its feature toggles and path lists
- Resolves and normalizes configured paths
- Refuses obviously dangerous startup directories such as `/`, `/Users`, `/System`, or a user's home directory itself
- Optionally adds the current working directory to writable paths
- Creates a temporary sandbox profile under `/tmp`
- Exports a small sandbox-specific runtime environment
- Launches either an interactive `zsh` session or the command you passed in

When no command is supplied, the script starts `zsh -i` with a generated `ZDOTDIR` and a prefixed prompt like `(sandbox)`.

## Common Usage

Interactive shell:

```bash
./sandbox
```

Git inspection in the current repository:

```bash
./sandbox git status
./sandbox git diff
```

Run a project command with shell parsing:

```bash
./sandbox zsh -lc 'make test'
```

Run a coding agent or CLI cautiously:

```bash
./sandbox codex
./sandbox claude
```

For agent-style tools, assume that network access may still break in practice even with `ENABLE_NET=1`.

## Configuration Knobs

The script is configured by editing variables near the top of `sandbox`.

Important toggles:

- `ENABLE_NET=1`: include `(allow network*)` in the generated policy
- `STRICT_MOUNTS=1`: fail if configured writable or readable paths do not exist
- `AUTO_MOUNT_CWD=1`: add the current directory to writable paths automatically
- `PRINT_CONFIG_SUMMARY=1`: print the resolved configuration before launch
- `DEBUG_PRINT_FINAL_CMD=0`: print the exact `sandbox-exec` invocation
- `DISABLE_HISTORY=1`: disable shell history in the interactive sandbox shell
- `DISABLE_OH_MY_ZSH_IN_SANDBOX=1`: source a filtered version of `~/.zshrc` without oh-my-zsh and powerlevel10k initialization

Path lists:

- `FORBIDDEN_CWD_EXACT`
- `FORBIDDEN_CWD_PREFIXES`
- `ALLOWED_RW_PREFIXES`
- `RO_MOUNTS`
- `RW_MOUNTS`

Environment and startup hooks:

- `PRE_COMMANDS`
- `UNSET_ENVS`
- `EXTRA_ENVS`

## Writable Paths

The generated policy always allows writes to a few runtime locations:

- `/private/tmp`
- `/private/var/tmp`
- `/dev/null`
- `/dev/tty`
- `/dev/stdout`
- `/dev/stderr`

It also adds the configured `RW_MOUNTS`, which by default include several user-local cache and agent directories such as:

- `~/.cache`
- `~/.claude`
- `~/.codex`
- `~/.pi`
- `~/.omp`

With `AUTO_MOUNT_CWD=1`, the current repository or working directory is appended automatically.

## Network Behavior

When `ENABLE_NET=1`, the generated policy includes:

```text
(allow network*)
```

That only means the sandbox policy does not block networking at the policy layer. It does not guarantee that every application will work reliably inside the sandbox.

In particular:

- Rust applications may still fail to connect in nested or constrained setups.
- Agent tools that depend on background daemons, loopback proxies, or platform-specific networking can still break.
- If your task requires stable network access, test with a small command before doing real work.

Practical validation examples:

```bash
./sandbox curl -I https://example.com
./sandbox zsh -lc 'nc -vz api.openai.com 443'
```

If those checks fail, do not assume the target application will behave correctly.

## Interactive Shell Behavior

The interactive mode creates a temporary runtime directory and points several variables into it:

- `SANDBOX_RUNTIME_DIR`
- `SANDBOX_ZDOTDIR`
- `XDG_CACHE_HOME`
- `XDG_STATE_HOME`
- `ZSH_CACHE_DIR`
- `ZSH_COMPDUMP`

It also sets:

- `SANDBOX_ACTIVE=1`
- `SANDBOX_LEVEL=<n>`
- `SANDBOX_PROMPT_PREFIX=(sandbox)` or a repeated variant for nested sessions

This keeps most temporary shell state out of your normal home-directory locations.

## Suggested Use Cases

Good fits:

- Constraining casual shell usage to the current repository
- Running local commands with a smaller writable surface
- Testing how a CLI behaves with filtered shell startup and limited writable paths

Use with caution:

- Network-heavy coding agents
- Rust-based applications that maintain persistent remote sessions
- Tools that expect unrestricted access to your full home directory

Poor fits:

- Anything that truly requires container semantics
- Reproducible Linux build environments
- Workloads that depend on stable nested virtualization or container networking

## Troubleshooting

`current directory is forbidden`

Start the script from a real project directory instead of `/`, `/Users`, `/System`, or your home directory.

`configured path does not exist`

Either create the path first or set `STRICT_MOUNTS=0` while testing.

Networking still fails even though `ENABLE_NET=1`

That is consistent with the known limitation described above. Validate whether the target application is compatible with `sandbox-exec` in your environment before relying on it.

Shell startup behaves strangely

The script intentionally filters parts of `~/.zshrc` when `DISABLE_OH_MY_ZSH_IN_SANDBOX=1`. If you need your full shell initialization, change that toggle and retest.

## Notes

- `sandbox-exec` is deprecated by Apple, so treat this helper as a pragmatic local tool rather than a future-proof platform feature.
- Read access is broad by design. The main restriction is around writes and launch context, not total filesystem visibility.
- The sandbox profile is generated on each run and removed afterward.
