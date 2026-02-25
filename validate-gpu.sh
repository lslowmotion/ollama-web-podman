#!/bin/bash

# ============================================================================
# GPU Detection and Validation Script
# ============================================================================
# This script provides comprehensive GPU detection with multiple validation
# sources and user-friendly output.
# ============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")

# Global variables
GPU_SELECTION=""
GPU_PROFILE=""
GPU_IMAGE=""
GPU_DEVICE=""

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo ""
    echo -e "${MAGENTA}${CYAN}========================================${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}${CYAN}========================================${NC}"
    echo ""
}

# ============================================================================
# GPU Detection Functions
# ============================================================================

# Function: Get detailed GPU information via lspci
get_gpu_info_lspci() {
    # Get all VGA and 3D controllers with full details
    local gpu_info=$(lspci -vnn | grep -A 12 -E '(VGA|3D) compatible controller')
    
    if [ -z "$gpu_info" ]; then
        log_error "No GPU devices detected via lspci!"
        return 1
    fi
    
    echo "$gpu_info"
    return 0
}

# Function: Parse GPU vendor from lspci output
parse_gpu_vendor() {
    local lspci_output="$1"
    
    if echo "$lspci_output" | grep -qi "nvidia"; then
        echo "nvidia"
    elif echo "$lspci_output" | grep -qi "amd"; then
        echo "amd"
    elif echo "$lspci_output" | grep -qi "intel"; then
        echo "intel"
    else
        echo "unknown"
    fi
}

# Function: Get specific GPU model from lspci
get_gpu_model() {
    local lspci_output="$1"
    
    # Extract model name - lspci format: "Vendor Device Model (revision xx)"
    # Example: "NVIDIA Corporation GA104 [GeForce RTX 3080] (rev a1)"
    local model=""
    
    # Try to extract text in brackets (most common format for GPUs)
    # Use a more specific pattern to avoid matching [0300] device codes
    model=$(echo "$lspci_output" | grep -oP '\[\K[^\]]+' | grep -vE '^[0-9a-f]{4}$' | head -1)
    
    if [ -z "$model" ]; then
        # Fallback: try to extract after the vendor name
        model=$(echo "$lspci_output" | sed 's/.*: //' | sed 's/.* //' | head -1)
    fi
    
    if [ -z "$model" ]; then
        model="Unknown Model"
    fi
    
    echo "$model"
}

# Function: Validate NVIDIA GPU
validate_nvidia_gpu() {
    log_info "Validating NVIDIA GPU..."
    
    # Check if nvidia-smi is available
    if ! command -v nvidia-smi &> /dev/null; then
        log_warning "nvidia-smi not found. NVIDIA drivers may not be installed."
        return 1
    fi
    
    # Try to get GPU information
    local gpu_count=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | wc -l)
    
    if [ "$gpu_count" -gt 0 ]; then
        local gpu_names=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
        log_success "NVIDIA GPUs detected: $gpu_count"
        echo "$gpu_names" | while read -r name; do
            echo "  - $name"
        done
        
        # Get driver version
        local driver_version=$(nvidia-smi --query=driver.version --format=csv 2>/dev/null | tail -1)
        if [ -n "$driver_version" ] && [ "$driver_version" != "ERROR" ] && [ "$driver_version" != "driver.version" ]; then
            log_info "Driver version: $driver_version"
        fi
        
        return 0
    else
        log_error "nvidia-smi failed. Check NVIDIA drivers."
        return 1
    fi
}

# Function: Validate AMD ROCm GPU
validate_amd_rocm() {
    log_info "Validating AMD ROCm GPU..."
    
    # Check if rocm-smi is available
    if ! command -v rocm-smi &> /dev/null; then
        log_warning "rocm-smi not found. ROCm may not be installed."
        return 1
    fi
    
    # Try to get GPU information
    local gpu_info=$(rocm-smi --showproductname --showproductid --showmemoryinfo 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$gpu_info" ]; then
        local gpu_count=$(echo "$gpu_info" | grep -c "GPU")
        log_success "ROCm GPUs detected: $gpu_count"
        return 0
    else
        log_error "rocm-smi failed. Check ROCm installation."
        return 1
    fi
}

# Function: Validate Intel IPEX GPU
validate_intel_ipex() {
    log_info "Validating Intel IPEX GPU..."
    
    # Check if sycl-ls is available (part of oneAPI)
    if ! command -v sycl-ls &> /dev/null; then
        log_warning "sycl-ls not found. Intel oneAPI may not be installed."
        return 1
    fi
    
    # Check for Intel GPU devices using sycl-ls
    local sycl_output=$(sycl-ls 2>/dev/null)
    
    # Look for Level Zero GPU devices (most reliable for Arc GPUs)
    local gpu_devices=$(echo "$sycl_output" | grep -c "ext_oneapi_level_zero:gpu")
    
    if [ "$gpu_devices" -gt 0 ]; then
        log_success "Intel GPUs detected: $gpu_devices"
        echo "$sycl_output" | grep "ext_oneapi_level_zero:gpu" | while read -r line; do
            local device_name=$(echo "$line" | sed 's/\[ext_oneapi_level_zero:gpu:[0-9]*\] //')
            echo "  - $device_name"
        done
        return 0
    else
        log_warning "No Intel GPU devices found via sycl-ls."
        log_warning "Please ensure Intel oneAPI is properly installed and drivers are loaded."
        return 1
    fi
}

# Function: Check for CPU-only system
check_cpu_only() {
    log_warning "No GPU detected. Using CPU mode (slow, not recommended)."
    log_warning "For best performance, consider using a system with a dedicated GPU."
    return 0
}

# ============================================================================
# GPU Selection Functions
# ============================================================================

# Function: Present GPU options to user
present_gpu_options() {
    local nvidia_detected="$1"
    local amd_detected="$2"
    local intel_detected="$3"
    
    # Use gum for selection if available
    if command -v gum &> /dev/null; then
        # gum requires interactive TTY, so we need to handle this differently
        # For non-interactive mode, use the first option or prompt manually
        if [ -t 0 ]; then
            local options=()
            
            if [ "$nvidia_detected" = "true" ]; then
                options+=("Nvidia (CUDA)")
            fi
            
            if [ "$amd_detected" = "true" ]; then
                options+=("AMD (ROCm)")
            fi
            
            if [ "$intel_detected" = "true" ]; then
                options+=("Arc (IPEX)")
            fi
            
            # Always add CPU option
            options+=("CPU (slow, not recommended)")
            
            local selection=$(printf '%s\n' "${options[@]}" | gum choose --header "Select the type of graphics card you want to use")
            echo "$selection"
        else
            # Non-interactive mode: auto-select first GPU option if available, otherwise CPU
            if [ "$nvidia_detected" = "true" ]; then
                echo "Nvidia (CUDA)"
            elif [ "$amd_detected" = "true" ]; then
                echo "AMD (ROCm)"
            elif [ "$intel_detected" = "true" ]; then
                echo "Arc (IPEX)"
            else
                echo "CPU (slow, not recommended)"
            fi
        fi
    else
        # gum not available, use manual selection
        if [ "$nvidia_detected" = "true" ]; then
            echo "Nvidia (CUDA)"
        elif [ "$amd_detected" = "true" ]; then
            echo "AMD (ROCm)"
        elif [ "$intel_detected" = "true" ]; then
            echo "Arc (IPEX)"
        else
            echo "CPU (slow, not recommended)"
        fi
    fi
}

# Function: Set GPU configuration based on selection
set_gpu_config() {
    local selection="$1"
    
    case "$selection" in
        "Nvidia (CUDA)")
            GPU_PROFILE="cuda"
            GPU_IMAGE="latest"
            GPU_DEVICE="nvidia.com/gpu=all"
            ;;
        "AMD (ROCm)")
            GPU_PROFILE="rocm"
            GPU_IMAGE="rocm"
            GPU_DEVICE="/dev/dri:/dev/dri /dev/kfd:/dev/kfd"
            ;;
        "Arc (IPEX)")
            GPU_PROFILE="ipex"
            GPU_IMAGE="latest"
            GPU_DEVICE="/dev/dri:/dev/dri"
            ;;
        *)
            GPU_PROFILE="cpu"
            GPU_IMAGE="latest"
            GPU_DEVICE=""
            ;;
    esac
}

# ============================================================================
# Main Function
# ============================================================================

main() {
    log_header "GPU Detection and Validation"
    
    # Step 1: Detect GPUs via lspci
    log_info "Scanning for GPUs via lspci..."
    local lspci_output
    lspci_output=$(get_gpu_info_lspci)
    
    if [ $? -ne 0 ]; then
        log_error "GPU detection failed!"
        log_info "Please check your hardware and drivers."
        exit 1
    fi
    
    # Step 2: Parse GPU vendor
    local gpu_vendor=$(parse_gpu_vendor "$lspci_output")
    local gpu_model=$(get_gpu_model "$lspci_output")
    
    # Strip ANSI color codes from model name for display
    local clean_model=$(echo "$gpu_model" | sed 's/\x1b\[[0-9;]*m//g')
    log_info "Detected: $gpu_vendor $clean_model"
    echo ""
    
    # Step 3: Validate each GPU type
    local nvidia_detected="false"
    local amd_detected="false"
    local intel_detected="false"
    
    case "$gpu_vendor" in
        "nvidia")
            if validate_nvidia_gpu; then
                nvidia_detected="true"
            fi
            ;;
        "amd")
            if validate_amd_rocm; then
                amd_detected="true"
            fi
            ;;
        "intel")
            if validate_intel_ipex; then
                intel_detected="true"
            fi
            ;;
        *)
            check_cpu_only
            ;;
    esac
    
    # Step 4: Present options and get selection
    local gpu_selection
    gpu_selection=$(present_gpu_options "$nvidia_detected" "$amd_detected" "$intel_detected")
    
    # Step 5: Set GPU configuration
    set_gpu_config "$gpu_selection"
    
    # Output results
    echo ""
    log_success "Selected: $gpu_selection"
    echo ""
    echo "Configuration:"
    echo "  Profile: $GPU_PROFILE"
    echo "  Image: $GPU_IMAGE"
    echo "  Device: $GPU_DEVICE"
    echo ""
    
    # Export variables for parent script
    echo "export GPU_SELECTION=$gpu_selection"
    echo "export GPU_PROFILE=$GPU_PROFILE"
    echo "export GPU_IMAGE=$GPU_IMAGE"
    echo "export GPU_DEVICE=$GPU_DEVICE"
}

# Run main function
main "$@"