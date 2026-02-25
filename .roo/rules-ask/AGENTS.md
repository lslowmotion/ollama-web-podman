# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Ask Mode Rules

### Documentation Context

- Main deployment script is `run.sh` - contains all deployment logic
- Quadlet files in `quadlets/` are templates with variable placeholders
- ComfyUI docker-compose.yml uses profiles for different GPU backends
- SearXNG config requires secret key generation via `openssl rand -hex 32`

### Counterintuitive Points

- Ollama IPEX uses `ollama-ipex.container` quadlet, not `ollama.container`
- ComfyUI requires manual FLUX.1 VAE download (HuggingFace login required)
- GPU detection via `lspci | grep ' VGA '` may fail and need manual selection
- ComfyUI workflows must be pre-configured for Open WebUI integration

### Directory Structure

- Quadlets: `quadlets/*.container`
- SearXNG config: `~/.local/share/containers/storage/volumes/searxng/_data/`
- ComfyUI models: `stable-diffusion-webui-podman/data/models/`
- ComfyUI workflows: `stable-diffusion-webui-podman/data/config/comfy/my_workflows/`