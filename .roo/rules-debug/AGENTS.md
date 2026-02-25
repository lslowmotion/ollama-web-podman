# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Debug Mode Rules

### Debugging Gotchas

- GPU detection in `run.sh` uses `lspci | grep ' VGA '` - may fail and need manual selection
- IPEX profile requires `ZES_ENABLE_SYSMAN=1` and `ONEAPI_DEVICE_SELECTOR=level_zero:0` env vars
- ComfyUI profiles: `auto-cuda`, `auto-rocm`, `comfy-cuda`, `comfy-rocm`, `comfy-ipex`

### Service Debugging

- Ollama logs: Check systemd user service logs with `systemctl --user status ollama.service`
- ComfyUI logs: Check systemd user service logs with `systemctl --user status comfy.service`
- SearXNG logs: Check systemd user service logs with `systemctl --user status searxng.service`
- Open WebUI logs: Check systemd user service logs with `systemctl --user status open-webui.service`

### Container Debugging

- List running containers: `podman ps`
- View container logs: `podman logs <container_name>`
- Access container shell: `podman exec -it <container_name> /bin/bash`

### Quadlet Debugging

- Quadlet location: `~/.config/containers/systemd/*.container`
- After modifying quadlets, run `systemctl --user daemon-reload`
- Quadlets use variable substitution via sed in `run.sh`