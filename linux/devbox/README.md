# Devbox

`devbox` is a small Bash-based toolkit for building and managing SSH-enabled development containers.

It includes:

- `devbox`: container lifecycle, login, deploy, and remote deploy commands
- `build-image.sh`: image build helper for the bundled Ubuntu devbox image
- `Dockerfile`: base image definition
- `devbox-init.sh`: container init script that prepares the runtime user
- `supervisord.conf`: process supervision for `sshd`

## Files

- `devbox`: main entry point
- `build-image.sh`: build the image `devops-ubuntu:24.04`
- `Dockerfile`: image definition
- `devbox-init.sh`: runtime init script
- `supervisord.conf`: supervisor config

## Quick Start

Build the image first:

```bash
bash ./build-image.sh
```

Create and run a container:

```bash
bash ./devbox run
```

List containers:

```bash
bash ./devbox list
```

Log in through SSH:

```bash
bash ./devbox ssh
```

Open a maintenance shell as `root`:

```bash
bash ./devbox shell
```

## Main Commands

Show all managed containers:

```bash
bash ./devbox list
```

Create a container:

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

Show container details:

```bash
bash ./devbox info [name]
```

Open a root maintenance shell:

```bash
bash ./devbox shell [name]
```

Connect to a container by SSH:

```bash
bash ./devbox ssh [name]
```

Deploy local container environment:

```bash
bash ./devbox deploy [name]
```

Deploy to a remote host:

```bash
bash ./devbox deploy-remote [user@]host [-p port]
```

## Container Login Modes

There are two ways to access a local container:

- `ssh`: normal development login through the container SSH service as the configured login user
- `shell`: maintenance shell opened directly as `root`

Use `ssh` for normal daily development.

Use `shell` for inspection, repair, or administrative work.

## Image Build

The bundled build helper creates this image by default:

```text
devops-ubuntu:24.04
```

Build it with:

```bash
bash ./build-image.sh
```

If the image already exists, the script asks whether it should be replaced.

If the image is still used by containers, the script prints the container list and exits.

## Run Workflow

When you create a container with `run`, the script will guide you through:

- container name
- whether to inherit the current host user
- custom login user, group, uid, and gid when not inheriting
- project directory mount
- image selection
- GPU mapping when supported
- automatic deploy after creation

The container publishes its SSH port to a random free host port.

After creation, `devbox` prints both:

- the recommended `bash ./devbox ssh <name>` command
- the direct raw `ssh user@127.0.0.1 -p <port>` command

## Local Deploy

`deploy` prepares a local container for development use.

It will:

- ensure your local SSH public key exists
- install the public key into the container
- sync configured environment variables
- sync configured files
- run configured deploy commands
- restart `sshd` inside the container when needed

Configuration lives at the top of `devbox`:

- `DEPLOY_ENV_VARS`
- `DEPLOY_SYNC_FILES`
- `DEPLOY_COMMANDS`

## Remote Deploy

`deploy-remote` is for a remote Linux host, not for local containers.

It only depends on local `ssh` and `scp`.

Its behavior is:

- try public key login first
- if public key login is unavailable, try password login
- if password login succeeds, install your public key for the target user
- do not touch `root` unless the target user is `root`
- reuse a temporary SSH master connection so you usually enter the password only once

If both public key login and password login fail, `devbox` exits and prints a suggested `ssh-copy-id` command.

## Environment Variables

Common overrides:

```text
CONTAINER_CMD
CONTAINER_PREFIX
IMAGE_PREFIX
CONTAINER_WORKDIR
PORT_RANGE_START
PORT_RANGE_END
```

Example:

```bash
CONTAINER_CMD=podman bash ./devbox list
```

## Notes

- Container names are normalized with the configured prefix.
- If a command accepts `[name]` and you omit it, `devbox` shows an interactive selection list.
- The bundled image uses `tini + supervisord + sshd`.
- `shell` always enters as `root`.
- `ssh` always targets the configured container login user.
