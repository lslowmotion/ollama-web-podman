#!/bin/sh

ROOT_DIR=${pwd}

echo "INSTALLING OLLAMA"

echo "[INFO] Detecting Hardware..."
GPU_CHOICES=("Nvidia (CUDA)" "AMD (ROCm)" "CPU (slow)")
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
echo "[INFO] Selected ${GPU_SELECTION}!"

case "$GPU_SELECTION" in
    "Nvidia (CUDA)")
        IMAGE=latest
        PROFILE=cuda
        DEVICE="nvidia.com\/gpu=all"
        ;;

    "AMD (ROCm)")
        IMAGE=rocm
        PROFILE=rocm
        DEVICE="\/dev\/dri:\/dev\/kfd"
        ;;
    *)
        IMAGE=latest
        ;;
esac

echo "[INFO] Pulling Ollama"
podman pull docker.io/ollama/ollama:${IMAGE}

echo "[INFO] Copy Ollama quadlet"
if [  ! -f ~/.config/containers/systemd/ollama.container ]; then
    mkdir -p ~/.config/containers/systemd
    cp ollama.container ~/.config/containers/systemd
    sed -e "s/IMAGE/${IMAGE}/g" \
        -i ~/.config/containers/systemd/ollama.container
    sed -e "s/DEVICE/${DEVICE}/g" \
        -i ~/.config/containers/systemd/ollama.container
else
    echo "[WARNING] Ollama container already exists, skipping..."
fi

echo "[INFO] Running Ollama service"
systemctl --user daemon-reload
systemctl --user start ollama.service

echo "INSTALLING COMFYUI"

if [ ${GPU_SELECTION} == "CPU (slow)" ]
    echo "[WARNING] GPU is not available or not selected. Not building ComfyUI"

else
    echo "[INFO] Cloning from github.com/lslowmotion/stable-diffusion-webui-podman"
    git clone https://github.com/lslowmotion/stable-diffusion-webui-podman.git

    cd stable-diffusion-webui-podman

    echo "[INFO] Downloading various models including FLUX.1-dev and its dependencies"
    podman-compose --profile download build
    podman-compose --profile download up

    echo "[INFO] Building ComfyUI with FLUX.1-dev support"
    podman-compose --profile comfy-${PROFILE} build

    echo "[INFO] Copy ComfyUI quadlet"
    mkdir -p ~/.config/containers/systemd
    cp comfy.container ~/.config/containers/systemd

    DEPLOYMENT_CHOICES=("Local only" "Network")

    DEPLOYMENT=$(printf '%s\n' "${DEPLOYMENT_CHOICES[@]}" | gum choose --select-if-one --header "Select deployment")

    if [ ${DEPLOYMENT} == "Local only" ]
        sed -e "s/0.0.0.0://g" \
            -i ~/.config/containers/systemd/comfy.container
    fi

    sed -e "s/PROFILE/${PROFILE}/g" \
        -i ~/.config/containers/systemd/comfy.container
    sed -e "s/DEVICE/${DEVICE}/g" \
        -i ~/.config/containers/systemd/comfy.container
    sed -e "s/ROOT_DIR/${ROOT_DIR}/g" \
        -i ~/.config/containers/systemd/comfy.container

    echo "[INFO] Running ComfyUI service"
    systemctl --user daemon-reload
    systemctl --user start comfy.service

    cd $ROOT_DIR
fi

echo "INSTALLING SEARXNG"

echo "[INFO] Pulling SearxNG"
podman pull docker.io/searxng/searxng:latest

echo "[INFO] Copy SearxNG quadlet"
if [  ! -f ~/.config/containers/systemd/searxng.container ]; then
    mkdir -p ~/.config/containers/systemd
    cp searxng.container ~/.config/containers/systemd

    DEPLOYMENT=$(printf '%s\n' "${DEPLOYMENT_CHOICES[@]}" | gum choose --select-if-one --header "Select deployment")

    if [ ${DEPLOYMENT} == "Local only" ]
        sed -e "s/0.0.0.0://g" \
            -i ~/.config/containers/systemd/searxng.container
    fi
else
    echo "[WARNING] SearxNG container already exists, skipping..."
fi

echo "[INFO] Running SearxNG service"
systemctl --user daemon-reload
systemctl --user start searxng.service

echo "INSTALLING OPEN WEBUI"

echo "[INFO] Pulling Open WebUI"
podman pull ghcr.io/open-webui/open-webui:latest

echo "[INFO] Copy Open WebUI quadlet"
if [  ! -f ~/.config/containers/systemd/open-webui.container ]; then
    mkdir -p ~/.config/containers/systemd
    cp open-webui.container ~/.config/containers/systemd

    DEPLOYMENT=$(printf '%s\n' "${DEPLOYMENT_CHOICES[@]}" | gum choose --select-if-one --header "Select deployment")

    if [ ${DEPLOYMENT} == "Local only" ]
        sed -e "s/0.0.0.0://g" \
            -i ~/.config/containers/systemd/open-webui.container
    fi
else
    echo "[WARNING] Open WebUI container already exists, skipping..."
fi

echo "[INFO] Running Open WebUI service"
systemctl --user daemon-reload
systemctl --user start open-webui.service