# NVIDIA Switch

This directory stores a few ready-to-use `modprobe.d` configurations for switching NVIDIA driver behavior on Linux systems.

The files are based on the naming and layout used by `system76-power`:

- `system76-nvidia-integrated`
- `system76-nvidia-hybrid`
- `system76-nvidia-compute`

The usual workflow is to point `/etc/modprobe.d/system76-nvidia.conf` at one of these files, rebuild the initramfs, and reboot.

## Modes

`integrated`

- Blacklists the NVIDIA driver stack
- Intended for systems that should stay on integrated graphics only

`hybrid`

- Enables the NVIDIA stack with DRM modesetting
- Suitable for mixed graphics setups where the discrete GPU remains available

`compute`

- Keeps core NVIDIA support for compute-oriented usage while blacklisting the DRM and modeset pieces
- Useful when the GPU should not be used as the display device but is still needed for CUDA or similar workloads

## Apply a Mode

Choose one configuration and create or update the symlink:

```bash
sudo ln -sfn /path/to/scripts/linux/nvidia-switch/system76-nvidia-hybrid /etc/modprobe.d/system76-nvidia.conf
```

Rebuild initramfs:

```bash
sudo update-initramfs -u
```

Reboot the machine:

```bash
sudo reboot
```

The change does not fully take effect until after reboot because kernel module loading policy is involved.

## Examples

Switch to integrated-only mode:

```bash
sudo ln -sfn /path/to/scripts/linux/nvidia-switch/system76-nvidia-integrated /etc/modprobe.d/system76-nvidia.conf
sudo update-initramfs -u
sudo reboot
```

Switch to hybrid mode:

```bash
sudo ln -sfn /path/to/scripts/linux/nvidia-switch/system76-nvidia-hybrid /etc/modprobe.d/system76-nvidia.conf
sudo update-initramfs -u
sudo reboot
```

Switch to compute mode:

```bash
sudo ln -sfn /path/to/scripts/linux/nvidia-switch/system76-nvidia-compute /etc/modprobe.d/system76-nvidia.conf
sudo update-initramfs -u
sudo reboot
```

## Verify the Active File

Check the symlink target:

```bash
readlink -f /etc/modprobe.d/system76-nvidia.conf
```

Review the active configuration:

```bash
cat /etc/modprobe.d/system76-nvidia.conf
```

## Caution

- These files affect low-level driver loading behavior.
- Use them only if your system is already set up for NVIDIA drivers and initramfs-based boot.
- On distributions that do not use `update-initramfs`, replace that step with the equivalent initramfs rebuild command.
- If your system uses another GPU switching tool, make sure it will not overwrite `/etc/modprobe.d/system76-nvidia.conf`.
