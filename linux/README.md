# Linux Scripts

This directory groups Linux-specific helper scripts and configuration snippets.

## Subdirectories

`devbox`

- Bash tooling for building and managing SSH-enabled development containers
- Includes image build helpers, container lifecycle commands, local deploy, and remote deploy support

`nvidia-switch`

- Ready-made `modprobe.d` profiles for switching NVIDIA driver behavior
- Intended for systems that rebuild initramfs and reboot after changing the active profile

## Usage

Read the README in each subdirectory before using the scripts:

```bash
less ./linux/devbox/README.md
less ./linux/nvidia-switch/README.md
```

Those documents contain the actual command examples, assumptions, and cautions for each tool.
