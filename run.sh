#!/bin/sh

ROOT_DIR=$(pwd)
DEPLOYMENT_CHOICES=("Local" "Network")
GPU_CHOICES=("Nvidia (CUDA)" "AMD (ROCm)" "CPU (slow)")

printf "*****INSTALLING OLLAMA*****\n"

printf "\n[INFO] Detecting Hardware...\n"
DETECTED_OPTIONS=()
# Detect nvidia drivers
if which nvidia-smi > /dev/null 2>&1; then
    DETECTED_OPTIONS+=("${GPU_CHOICES[0]}")
fi
# Detect AMD hardware
if lspci | grep ' VGA ' | grep -sq AMD; then
    DETECTED_OPTIONS+=("${GPU_CHOICES[1]}")
fi
# Nothing detected, ask the user
if [ ${#DETECTED_OPTIONS[@]} -eq 0 ]; then
    GPU_SELECTION=$(printf '%s\n' "${GPU_CHOICES[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
else
    GPU_SELECTION=$(printf '%s\n' "${DETECTED_OPTIONS[@]}" | gum choose --select-if-one --header "Select the type of graphics card you want to use")
fi
printf "\n[INFO] Selected ${GPU_SELECTION}!\n"

case "$GPU_SELECTION" in
    "Nvidia (CUDA)")
        IMAGE=latest
        PROFILE=cuda
        DEVICE="nvidia.com/gpu=all"
        ;;

    "AMD (ROCm)")
        IMAGE=rocm
        PROFILE=rocm
        DEVICE="/dev/dri:/dev/kfd"
        ;;
    *)
        IMAGE=latest
        DEVICE=""
        ;;
esac

printf "\n[INFO] Pulling Ollama\n"
podman pull docker.io/ollama/ollama:${IMAGE}

printf "\n[INFO] Copying Ollama quadlet\n"
if [  ! -f ~/.config/containers/systemd/ollama.container ]; then
    mkdir -p ~/.config/containers/systemd
    cp ollama.container ~/.config/containers/systemd
    sed -e "s/IMAGE/${IMAGE}/g" \
        -i ~/.config/containers/systemd/ollama.container
    sed -e "s:DEVICE:${DEVICE}:g" \
        -i ~/.config/containers/systemd/ollama.container
else
    printf "\n[WARNING] Ollama container already exists, skipping...\n"
fi

printf "\n[INFO] Running Ollama service\n"
systemctl --user daemon-reload
systemctl --user restart ollama.service

printf "\n\n*****INSTALLING COMFYUI*****\n"

if [ -z "${DEVICE}" ]; then
    printf "\n[WARNING] GPU is not available or not selected. Not building ComfyUI\n"
else
    cd stable-diffusion-webui-podman

    printf "\n[INFO] Downloading various models including FLUX.1-dev and its dependencies\n"
    podman-compose --profile download build
    podman run -it --rm -v ./data:/data:Z localhost/models-downloader:latest

    printf "\n[INFO] Building ComfyUI with FLUX.1-dev support\n"
    podman-compose --profile comfy-${PROFILE} build

    cd $ROOT_DIR

    printf "\n[INFO] Copying ComfyUI quadlet\n"
    if [  ! -f ~/.config/containers/systemd/comfy.container ]; then
        mkdir -p ~/.config/containers/systemd
        cp comfy.container ~/.config/containers/systemd

        DEPLOYMENT=$(printf '%s\n' "${DEPLOYMENT_CHOICES[@]}" | gum choose --select-if-one --header "Select deployment")

        if [ ${DEPLOYMENT} == "Local" ]; then
            sed -e "s/0.0.0.0://g" \
                -i ~/.config/containers/systemd/comfy.container
        fi

        sed -e "s/PROFILE/${PROFILE}/g" \
            -i ~/.config/containers/systemd/comfy.container
        sed -e "s:DEVICE:${DEVICE}:g" \
            -i ~/.config/containers/systemd/comfy.container
        sed -e "s:ROOT_DIR:${ROOT_DIR}:g" \
            -i ~/.config/containers/systemd/comfy.container

    else
        printf "\n[WARNING] ComfyUI container already exists, skipping...\n"
    fi

    printf "\n[INFO] Running ComfyUI service\n"
    systemctl --user daemon-reload
    systemctl --user restart comfy.service
fi

printf "\n\n*****INSTALLING SEARXNG*****\n"

printf "\n[INFO] Pulling SearXNG\n"
podman pull docker.io/searxng/searxng:latest

printf "\n[INFO] Copying SearXNG quadlet\n"
if [  ! -f ~/.config/containers/systemd/searxng.container ]; then
    mkdir -p ~/.config/containers/systemd
    cp searxng.container ~/.config/containers/systemd

    DEPLOYMENT=$(printf '%s\n' "${DEPLOYMENT_CHOICES[@]}" | gum choose --select-if-one --header "Select deployment")

    if [ ${DEPLOYMENT} == "Local" ]; then
        sed -e "s/0.0.0.0://g" \
            -i ~/.config/containers/systemd/searxng.container
    fi
else
    printf "\n[WARNING] SearXNG container already exists, skipping...\n"
fi

printf "\n[INFO] Running SearXNG service and copying SearXNG configs\n"
cp -rf searxng-config/* ~/.local/share/containers/storage/volumes/searxng/_data/
sed -e "s/ultrasecretkey/$(openssl rand -hex 32)/g" \
    -i ~/.local/share/containers/storage/volumes/searxng/_data/settings.yml

systemctl --user daemon-reload
systemctl --user restart searxng.service

printf "\n\n*****INSTALLING OPEN WEBUI*****\n"

printf "\n[INFO] Pulling Open WebUI\n"
podman pull ghcr.io/open-webui/open-webui:latest

printf "\n[INFO] Copying Open WebUI quadlet\n"
if [  ! -f ~/.config/containers/systemd/open\-webui.container ]; then
    mkdir -p ~/.config/containers/systemd
    cp open-webui.container ~/.config/containers/systemd

    DEPLOYMENT=$(printf '%s\n' "${DEPLOYMENT_CHOICES[@]}" | gum choose --select-if-one --header "Select deployment")

    if [ ${DEPLOYMENT} == "Local" ]; then
        sed -e "s/0.0.0.0://g" \
            -i ~/.config/containers/systemd/open-webui.container
    fi
else
    printf "\n[WARNING] Open WebUI container already exists, skipping...\n"
fi

printf "\n[INFO] Running Open WebUI service\n"
systemctl --user daemon-reload
systemctl --user restart open-webui.service