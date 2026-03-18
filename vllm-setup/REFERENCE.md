# vllm-setup Reference

## Full build procedure (from scratch)

Run all commands inside the `vllm` distrobox container (`distrobox enter vllm`).

### 1. ROCm repo setup

```bash
# Add AMD GPG key
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor > /etc/apt/keyrings/rocm.gpg

# Add repo
echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.3.4 noble main' \
  > /etc/apt/sources.list.d/rocm.list

# Override Ubuntu's conflicting rocminfo package
cat > /etc/apt/preferences.d/rocm-pin-600 << 'EOF'
Package: *
Pin: release o=repo.radeon.com
Pin-Priority: 1001
EOF

apt-get update
```

### 2. Install ROCm userspace + dev packages

```bash
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  rocm-hip-libraries rocm-smi-lib hipblas miopen-hip rocrand \
  hip-dev rocm-llvm rocm-device-libs \
  rocprim-dev hipcub-dev rocthrust-dev \
  rocblas-dev rocsolver-dev hipsparse-dev \
  rocm-dev cmake build-essential
```

### 3. Create wrapper scripts (hipcc and hipconfig missing in ROCm 6.3.4)

```bash
# hipcc wrapper
cat > /opt/rocm/bin/hipcc << 'EOF'
#!/bin/bash
if [[ "$*" == *"--version"* ]]; then
    echo 'HIP version: 6.3.42134'
    /opt/rocm-6.3.4/lib/llvm/bin/amdclang++ --version 2>&1
else
    exec /opt/rocm-6.3.4/lib/llvm/bin/amdclang++ "$@"
fi
EOF
chmod +x /opt/rocm/bin/hipcc

# hipconfig wrapper (--version must output bare version number for CMake)
cat > /opt/rocm/bin/hipconfig << 'EOF'
#!/bin/bash
HIP_VERSION=6.3.42134
case "$1" in
  --version) echo "$HIP_VERSION" ;;
  --path|-p)  echo "/opt/rocm" ;;
  --rocmpath) echo "/opt/rocm" ;;
  --compiler) echo "amd" ;;
  --platform) echo "amd" ;;
  --runtime)  echo "rocclr" ;;
  *) echo "HIP version   : $HIP_VERSION"; echo "HIP_PATH      : /opt/rocm"; echo "HIP_COMPILER  : amd" ;;
esac
EOF
chmod +x /opt/rocm/bin/hipconfig
```

### 4. Fix amdsmi (pip version 7.0.2 incompatible with ROCm 6.3.4)

```bash
# Install system amdsmi (comes with amd-smi-lib Ubuntu package)
apt-get install -y amd-smi-lib

# Copy system amdsmi to venv (instead of pip version)
pip uninstall amdsmi -y  # remove 7.0.2
cp -r /usr/local/lib/python3.12/dist-packages/amdsmi /opt/vllm-env/lib/python3.12/site-packages/
```

### 5. Create Python venv and install PyTorch ROCm

```bash
mkdir -p /opt/pip-tmp /root/.cache/pip
python3 -m venv /opt/vllm-env
/opt/vllm-env/bin/pip install --upgrade pip

/opt/vllm-env/bin/pip install torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/rocm6.2

# Verify
/opt/vllm-env/bin/python3 -c "import torch; print(torch.version.hip, torch.cuda.get_device_name(0))"
```

### 6. Clone vllm v0.6.5 and patch

```bash
cd /opt
git clone --branch v0.6.5 --depth 1 https://github.com/vllm-project/vllm.git

# Patch 1: Add gfx1033 to supported arch list (line 40 of CMakeLists.txt)
sed -i 's/gfx906;gfx908;gfx90a;gfx940;gfx941;gfx942;gfx1030;gfx1100;gfx1101/gfx906;gfx908;gfx90a;gfx940;gfx941;gfx942;gfx1030;gfx1033;gfx1100;gfx1101/' \
  /opt/vllm/CMakeLists.txt

# Patch 2: Use Python3_EXECUTABLE for hipify (cmake/utils.cmake ~line 79)
sed -i 's|COMMAND ${CMAKE_SOURCE_DIR}/cmake/hipify.py|COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/cmake/hipify.py|' \
  /opt/vllm/cmake/utils.cmake
```

### 7. Install CPU torch in system Python (for cmake hipify step)

```bash
/usr/bin/python3 -m pip install torch --index-url https://download.pytorch.org/whl/cpu \
  --break-system-packages -q
```

### 8. Install vllm requirements and build

```bash
export PATH=/opt/rocm/bin:/opt/rocm-6.3.4/lib/llvm/bin:$PATH
export PYTORCH_ROCM_ARCH=gfx1033
export ROCM_HOME=/opt/rocm
export ROCM_PATH=/opt/rocm
export HIP_PATH=/opt/rocm
export HIP_ROOT_DIR=/opt/rocm
export CUDA_HOME=/opt/rocm
export HSA_OVERRIDE_GFX_VERSION=10.3.0
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
export TMPDIR=/opt/pip-tmp
export VLLM_TARGET_DEVICE=rocm
export CMAKE_PREFIX_PATH=/opt/rocm
export AMDGPU_TARGETS=gfx1033

cd /opt/vllm
/opt/vllm-env/bin/pip install -r requirements-rocm.txt

# Build (~20–40 min on Steam Deck)
/opt/vllm-env/bin/pip install -e . --no-build-isolation
```

---

## All patches applied (summary)

| # | Problem | Fix |
|---|---------|-----|
| 1 | Ubuntu rocminfo conflicts with ROCm 6.3.4 | apt pin priority 1001 for ROCm repo |
| 2 | pip build isolation downloads CUDA torch | `--no-build-isolation` |
| 3 | TMPDIR (tmpfs 7GB) fills up during build | `export TMPDIR=/opt/pip-tmp` |
| 4 | setup.py can't detect runtime env (`lsmod` missing) | `export VLLM_TARGET_DEVICE=rocm` |
| 5 | `CUDA_HOME` assertion fails | `export CUDA_HOME=/opt/rocm` |
| 6 | `hipcc` binary missing in ROCm 6.3.4 | wrapper script → amdclang++ |
| 7 | `hipconfig --version` outputs string, not bare version | wrapper outputs bare `6.3.42134` |
| 8 | `AMDDeviceLibs` cmake not found | `apt install rocm-device-libs` |
| 9 | `rocprim`/`hipcub` cmake not found | `apt install rocprim-dev hipcub-dev rocm-dev` |
| 10 | `gfx1033` not in vllm supported arch list | patch `CMakeLists.txt` line 40 |
| 11 | cmake hipify.py uses system Python (no torch) | patch `cmake/utils.cmake` + CPU torch in system Python |
| 12 | pip amdsmi 7.0.2 incompatible with ROCm 6.3.4 | replace with system amdsmi from amd-smi-lib |

---

## Troubleshooting

### `HSA_OVERRIDE_GFX_VERSION` not set → kernel launch errors
gfx1033 needs override to 10.3.0. Always set before running.

### VRAM shows 1GB (not 8GB)
Expected from `rocm-smi`; PyTorch reports 8GB via HSA unified memory. Use `torch.cuda.get_device_properties(0).total_memory`.

### Container restarts lose `/opt/rocm/bin/hipcc` etc.
These wrappers are in the container overlay filesystem — they persist across restarts as long as the container isn't recreated.

### OOM when loading model
Reduce `--gpu-memory-utilization` (default 0.9 → try 0.6–0.7) or use a smaller/quantized model.
