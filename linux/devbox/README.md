# Devbox

`devbox` is a Bash toolkit for creating and operating SSH-enabled development containers on a local Linux machine. It is designed for a simple workflow: build an image, create a container with a mounted project directory, then enter it through SSH as a normal development user.

The directory contains:

- `devbox`: the main command-line entry point
- `build-image.sh`: image build helper
- `Dockerfile`: Ubuntu-based development image
- `devbox-init.sh`: container init logic that creates the runtime user and starts services
- `supervisord.conf`: process supervision for `sshd`

## Requirements

- A container runtime compatible with the Docker CLI, such as Docker or Podman
- Local `ssh` for `devbox ssh` and `deploy-remote`
- A local SSH key pair in `~/.ssh`, typically `id_ed25519` or `id_rsa`

The default runtime is `docker`. Override it with `CONTAINER_CMD` when needed.

## Quick Start

Build the bundled image:

```bash
bash ./build-image.sh
```

Create a container from an image whose name starts with `devbox-`:

```bash
bash ./devbox run
```

List managed containers:

```bash
bash ./devbox list
```

Open a normal development session through SSH:

```bash
bash ./devbox ssh
```

Open a direct maintenance shell as `root`:

```bash
bash ./devbox shell
```

## Command Reference

Show all managed containers:

```bash
bash ./devbox list
```

Create a new container:

```bash
bash ./devbox run [name]
```

Start, stop, or restart a container:

```bash
bash ./devbox start [name]
bash ./devbox stop [name]
bash ./devbox restart [name]
```

Remove a container:

```bash
bash ./devbox rm [name]
```

Inspect one container:

```bash
bash ./devbox info [name]
```

Open a root shell inside the container:

```bash
bash ./devbox shell [name]
```

SSH into the container as the configured development user:

```bash
bash ./devbox ssh [name]
```

Deploy local development settings into a local container:

```bash
bash ./devbox deploy [name]
```

Deploy the same environment model to a remote Linux host:

```bash
bash ./devbox deploy-remote [user@]host [-p port]
```

Show built-in help:

```bash
bash ./devbox --help
```

If a command accepts `[name]` and the name is omitted, `devbox` shows an interactive selection list.

## Typical Workflow

1. Build the image with `bash ./build-image.sh`.
2. Run `bash ./devbox run mybox` and answer the prompts.
3. Let `devbox` map a random SSH port on `127.0.0.1`.
4. Optionally run an initial deploy during creation.
5. Use `bash ./devbox ssh mybox` for daily work.
6. Use `bash ./devbox shell mybox` only for repair or administration.

## What `run` Prompts For

When you create a container, `devbox` collects:

- Container name
- Whether to inherit the current host user name, group, UID, and GID
- A custom login user, group, UID, and GID if you do not inherit host values
- The project directory to mount into the container
- The image to use, selected from local images whose name starts with `IMAGE_PREFIX`
- Whether GPU access should be attached when the runtime advertises `--gpus`
- Whether to run `deploy` immediately after container creation

The mounted project directory becomes the container working directory, which defaults to `/workspace`.

The created container hostname is set to the normalized container name, so the in-container hostname matches what `devbox` manages on the host side.

`devbox` refuses to mount your home directory directly. That guard exists to prevent broad and accidental host exposure.

On macOS, `devbox` intentionally skips the GPU prompt even if Docker reports a `--gpus` flag. Docker Desktop may advertise the option while still rejecting actual GPU values for this workflow.

## Access Modes

There are two main ways to enter a local container:

- `ssh`: the normal development path, using the configured development user and the published SSH port
- `shell`: a direct `docker exec` or `podman exec` shell as `root`

Use `ssh` for day-to-day development because it matches the intended login user, shell environment, and file ownership model.

Use `shell` for system inspection, package repair, or other administrative work.

## Local Deploy

`bash ./devbox deploy [name]` prepares a local container for interactive development.

It does the following:

- Verifies that a local SSH public key exists
- Appends that public key to both the container user's and `root`'s `authorized_keys`
- Writes proxy helper functions to `/etc/profile.d/devbox_env.sh`
- Copies configured files and directories into the container
- Runs configured deploy commands inside the container
- Restarts `sshd`

The deploy behavior is configured near the top of the `devbox` script:

- `PROXY_ENV_VARS`
- `DEPLOY_SYNC_FILES`
- `DEPLOY_COMMANDS`

`DEPLOY_SYNC_FILES` still uses the `source_path:target_path` format, but `target_path` now supports a few runtime placeholders:

- `{{DEVBOX_HOME}}`: the resolved home directory of the container development user
- `{{DEVBOX_USER}}`: the resolved development user name
- `{{CONTAINER_WORKDIR}}`: the configured container workdir, `/workspace` by default

Example:

```bash
DEPLOY_SYNC_FILES=(
  "$HOME/.gitconfig:{{DEVBOX_HOME}}/.gitconfig"
  "$HOME/.ssh/config:{{DEVBOX_HOME}}/.ssh/config"
  "$HOME/project.env:{{CONTAINER_WORKDIR}}/.env"
)
```

The generated profile script defines two shell functions:

- `proxy_on`: exports proxy variables inherited from the host environment
- `proxy_off`: unsets those proxy variables again

`proxy_on` is executed by default when the profile is sourced.

If the host has no proxy variables set, both functions still exist but `proxy_on` becomes a no-op.

Example pattern:

```bash
# Edit the arrays in ./devbox first, then apply them
bash ./devbox deploy mybox
```

## Remote Deploy

`deploy-remote` applies the same environment-sync idea to a remote Linux host over SSH. It is separate from local container creation.

Behavior summary:

- It first tries public-key authentication.
- If that fails, it tries an SSH connection that can prompt for a password.
- When password login succeeds, it installs your local public key for the target user.
- It does not modify `root` unless the target account itself is `root`.
- It reuses a temporary SSH control connection so you usually enter the password only once.

Examples:

```bash
bash ./devbox deploy-remote dev@example.com
bash ./devbox deploy-remote root@example.com -p 2222
```

If both key-based and password-based login fail, the script exits and suggests an `ssh-copy-id` command.

## Image Build

The bundled image helper builds this image by default:

```text
devbox-ubuntu:24.04
```

Build it with:

```bash
bash ./build-image.sh
```

You can override the build inputs:

```bash
IMAGE_NAME=my-devbox:latest CONTAINER_CMD=podman bash ./build-image.sh
```

The script checks whether the image already exists.

- If the image does not exist, it builds it.
- If the image exists, it asks before overwriting it.
- If any containers still use that image, it refuses to remove the image and prints the blocking container list.

## Runtime Defaults

Important defaults from `devbox`:

- `CONTAINER_CMD=docker`
- `CONTAINER_PREFIX=devbox-`
- `IMAGE_PREFIX=devbox-`
- `CONTAINER_WORKDIR=/workspace`
- `PREFERRED_SHELL=bash`
- `DEFAULT_GPU_ENABLE=yes`
- `PORT_RANGE_START=20000`
- `PORT_RANGE_END=39999`

Useful overrides:

```bash
CONTAINER_CMD=podman bash ./devbox list
CONTAINER_PREFIX=work- IMAGE_PREFIX=work- bash ./devbox run
CONTAINER_WORKDIR=/src bash ./devbox info mybox
PORT_RANGE_START=30000 PORT_RANGE_END=30999 bash ./devbox run mybox
```

## Image Contents

The bundled `Dockerfile` creates an Ubuntu 24.04 image with common development tools and an SSH server. It includes packages such as:

- `apt-utils`
- `bash`, `git`, `git-lfs`, `tmux`, `htop`, `less`
- `build-essential`, `cmake`, `patch`, `file`
- `curl`, `iproute2`, `iputils-ping`, `net-tools`, `dnsutils`, `lsof`, `strace`
- `ripgrep`, `fd`, `jq`, `rsync`
- `python3`, `python3-pip`, `python3-venv`
- `openssh-server`, `supervisor`, `tini`, `sudo`

Container startup is handled by `devbox-init.sh`.

That script:

- Creates or reuses the requested user and group
- Aligns UID and GID when possible
- Creates `~/.ssh/authorized_keys`
- Grants passwordless `sudo` to the non-root development user
- Stores resolved runtime values in `/etc/devbox/user.env`
- Starts `supervisord`, which in turn keeps `sshd` running

## GPU Support

When the selected container runtime reports support for `--gpus`, `devbox run` offers to attach GPUs.

On macOS, this prompt is skipped on purpose.

Typical answers are:

- `all`
- `0,1`
- `none`

This is only a thin pass-through to the runtime. Driver installation, NVIDIA Container Toolkit setup, and host compatibility are still your responsibility.

## Troubleshooting

`No local image found with prefix ...`

Build an image first, or adjust `IMAGE_PREFIX`.

`No SSH public key found under ~/.ssh`

Create a local SSH key pair before using `ssh`, `deploy`, or `deploy-remote`.

`Container SSH port is not mapped`

The container may not have been created by `devbox`, or the port mapping may have been altered manually.

`Container runtime not found`

Install Docker or Podman, or set `CONTAINER_CMD` correctly.

## Notes

- Container names are normalized with `CONTAINER_PREFIX`.
- Short names like `mybox` become `devbox-mybox` by default.
- `ssh` always targets the configured development user, not `root`.
- `shell` always opens as `root`.
- The helper is intentionally interactive. It is optimized for operator-driven local usage rather than unattended automation.
