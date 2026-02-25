# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Code Mode Rules

### Build/Deploy Commands

- Ollama (IPEX): `cd ollama-ipex-container && podman build -t ollama:ipex -f Dockerfile .`
- ComfyUI: `cd stable-diffusion-webui-podman && podman-compose --profile comfy-${PROFILE} build`
- ComfyUI profiles: `auto-cuda`, `auto-rocm`, `comfy-cuda`, `comfy-rocm`, `comfy-ipex`

### Environment Variables

- IPEX requires `ZES_ENABLE_SYSMAN=1` and `ONEAPI_DEVICE_SELECTOR=level_zero:0`
- Ollama IPEX Dockerfile sets `OLLAMA_NUM_GPU=999` for full GPU utilization

### File Locations

- Quadlets: `quadlets/*.container`
- Ollama IPEX uses `ollama-ipex.container` (not `ollama.container`)
- SearXNG config: `~/.local/share/containers/storage/volumes/searxng/_data/`

### Gotchas

- FLUX.1 VAE must be manually downloaded to `stable-diffusion-webui-podman/data/models/VAE`
- GPU detection uses `lspci | grep ' VGA '` - may fail and need manual selection
- ComfyUI workflows must be pre-configured for Open WebUI integration