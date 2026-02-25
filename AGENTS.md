# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Deployment Commands

- Run main menu: `./run.sh`
- Ollama (CUDA/ROCm): `podman pull docker.io/ollama/ollama:${IMAGE}` then `systemctl --user restart ollama.service`
- Ollama (IPEX): `cd ollama-ipex-container && podman build -t ollama:ipex -f Dockerfile .`
- ComfyUI: `cd stable-diffusion-webui-podman && podman-compose --profile comfy-${PROFILE} build`
- SearXNG config: `cp -rf searxng-config/* ~/.local/share/containers/storage/volumes/searxng/_data/`
- Generate random SearXNG secret: `openssl rand -hex 32`

## Quadlet Files

- Location: `quadlets/*.container`
- Ollama IPEX uses `ollama-ipex.container` (not `ollama.container`)
- ComfyUI requires `ROOT_DIR` and `PROFILE` variable substitution in quadlets
- SearXNG settings.yml requires secret key replacement via sed

## Important Gotchas

- FLUX.1 VAE must be downloaded manually (HuggingFace login required) to `stable-diffusion-webui-podman/data/models/VAE`
- ComfyUI workflows must be pre-configured for Open WebUI integration
- GPU detection in `run.sh` uses `lspci | grep ' VGA '` - may need manual selection if detection fails
- IPEX profile requires `ZES_ENABLE_SYSMAN=1` and `ONEAPI_DEVICE_SELECTOR=level_zero:0` env vars
- ComfyUI profiles: `auto-cuda`, `auto-rocm`, `comfy-cuda`, `comfy-rocm`, `comfy-ipex`

## Service Ports

| Service | Port |
|---------|------|
| Ollama | 11434 |
| ComfyUI | 7860 |
| SearXNG | 4000 |
| Open WebUI | 3000 |