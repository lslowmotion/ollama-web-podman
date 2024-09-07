# Ollama Web Podman

One script to run them all!

This script will help you run:
- Ollama (CUDA/ROCm/CPU)
- ComfyUI with FLUX.1-dev support (CUDA/ROCm)
- SearxNG
- Open WebUI

## Prerequisites
- Podman
- [Gum](https://github.com/charmbracelet/gum)

## Quick Setup
Clone the repository
```
git clone --recursive https://github.com/lslowmotion/ollama-web-podman.git
```
Run `run.sh` and follow the instructions.

## Note
ComfyUI workflow would need to be set up first to be able to be used with Open WebUI.
[Setting Up Open WebUI with ComfyUI](https://docs.openwebui.com/tutorial/images#setting-up-open-webui-with-comfyui)

Also, FLUX.1 VAE need to be downloaded manually because of HuggingFace login requirements.
[Read more](https://github.com/lslowmotion/stable-diffusion-webui-podman?tab=readme-ov-file#flux1-gguf)

## Address/Ports
| Service       | Address/Ports         |
|---------------|-----------------------|
| Ollama        | 11434                 |
| ComfyUI       | http://localhost:7860 |
| SearxNg       | http://localhost:4000 |
| Open WebUI    | http://localhost:3000 |