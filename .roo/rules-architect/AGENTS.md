# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Architect Mode Rules

### Architecture Overview

- Single script (`run.sh`) orchestrates deployment of Ollama, ComfyUI, SearXNG, and Open WebUI
- Uses Podman quadlets for systemd user services (no root required)
- ComfyUI uses docker-compose profiles for GPU backend selection (CUDA/ROCm/IPEX)

### Hidden Coupling

- Ollama IPEX requires specific env vars: `ZES_ENABLE_SYSMAN=1` and `ONEAPI_DEVICE_SELECTOR=level_zero:0`
- ComfyUI quadlets require variable substitution (`PROFILE`, `DEVICE`, `ROOT_DIR`) via sed
- SearXNG settings.yml requires runtime secret key generation

### Non-Standard Patterns

- GPU detection via `lspci | grep ' VGA '` in shell script (not container-level)
- FLUX.1 VAE must be manually downloaded to `stable-diffusion-webui-podman/data/models/VAE`
- ComfyUI workflows must be pre-configured for Open WebUI integration

### Service Architecture

| Service | Port | Quadlet |
|---------|------|---------|
| Ollama | 11434 | ollama.container / ollama-ipex.container |
| ComfyUI | 7860 | comfy.container |
| SearXNG | 4000 | searxng.container |
| Open WebUI | 3000 | open-webui.container |