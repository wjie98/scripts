# Scripts

This repository collects small platform-specific helpers for local development environments, machine setup, and workflow automation.

The scripts are organized by operating system. Each subdirectory has its own README with command examples and caveats.

## Directory Layout

`linux/`

- Linux-focused helpers and configuration snippets
- Includes development container tooling and NVIDIA driver mode switching
- See [linux/README.md](/home/wenjie/repo/scripts/linux/README.md)

`macos/`

- macOS-specific local sandbox helper
- Includes notes about known networking limitations for some Rust-based coding-agent stacks
- See [macos/README.md](/home/wenjie/repo/scripts/macos/README.md)

## Linux Tools

`linux/devbox/`

- Interactive Bash toolkit for building and managing SSH-enabled development containers
- Supports image build, container lifecycle, local deploy, and remote deploy
- See [linux/devbox/README.md](/home/wenjie/repo/scripts/linux/devbox/README.md)

`linux/nvidia-switch/`

- `modprobe.d` profiles for switching between integrated, hybrid, and compute-oriented NVIDIA setups
- Intended for systems that rebuild initramfs and reboot after switching modes
- See [linux/nvidia-switch/README.md](/home/wenjie/repo/scripts/linux/nvidia-switch/README.md)

## macOS Tools

`macos/sandbox`

- Wrapper around `sandbox-exec` for launching a command in a constrained local environment
- Useful for cautious local shell isolation, but not a replacement for containers
- See [macos/README.md](/home/wenjie/repo/scripts/macos/README.md)

## How to Use This Repository

1. Go to the relevant platform directory.
2. Read that directory's README before running anything.
3. Follow the documented commands and prerequisites.

Examples:

```bash
less ./linux/devbox/README.md
less ./linux/nvidia-switch/README.md
less ./macos/README.md
```

## Notes

- These scripts are intentionally lightweight and operator-oriented.
- Some helpers change low-level system behavior, so read the cautions before use.
- The macOS sandbox helper should be treated carefully for network-dependent Rust/Codex-like tools.
