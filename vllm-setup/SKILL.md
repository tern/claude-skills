---
name: vllm-setup
description: Set up, configure, diagnose, and run vllm with AMD ROCm on Steam Deck inside a distrobox container. Use when user mentions vllm, ROCm GPU inference, running LLMs locally on Steam Deck, or asks to start/fix/diagnose vllm.
---

# vllm-setup

vllm 0.6.6.dev0 + ROCm 6.3.4 running on Steam Deck gfx1033 (RDNA2 APU) inside the `vllm` distrobox container.

## Quick start

```bash
# Enter container
distrobox enter vllm

# Activate environment
source /opt/vllm-env/bin/activate
export PATH=/opt/rocm/bin:/opt/rocm-6.3.4/lib/llvm/bin:$PATH
export HSA_OVERRIDE_GFX_VERSION=10.3.0
export LD_LIBRARY_PATH=/opt/rocm/lib:$LD_LIBRARY_PATH
export VLLM_TARGET_DEVICE=rocm
export PYTORCH_ROCM_ARCH=gfx1033

# Verify
python3 -c "import vllm; import torch; print(vllm.__version__, torch.cuda.get_device_name(0))"

# Serve a model (8GB VRAM — start small)
vllm serve Qwen/Qwen2.5-1.5B-Instruct --gpu-memory-utilization 0.7
```

## Workflows

### Check current status
```bash
podman exec vllm bash -c "
  export PATH=/opt/rocm/bin:\$PATH
  export HSA_OVERRIDE_GFX_VERSION=10.3.0
  export LD_LIBRARY_PATH=/opt/rocm/lib:\$LD_LIBRARY_PATH
  /opt/vllm-env/bin/python3 -c 'import vllm; import torch; print(\"vllm:\", vllm.__version__); print(\"GPU:\", torch.cuda.get_device_name(0)); print(\"VRAM:\", torch.cuda.get_device_properties(0).total_memory // 1024**2, \"MB\")'
"
```

### Rebuild vllm from source
See [REFERENCE.md](REFERENCE.md) for the full patched build procedure.

### Diagnose GPU / ROCm
```bash
podman exec vllm bash -c "
  export PATH=/opt/rocm/bin:\$PATH
  export LD_LIBRARY_PATH=/opt/rocm/lib:\$LD_LIBRARY_PATH
  rocm-smi
  rocminfo | grep -E 'gfx|Name|VRAM'
"
```

## Key facts

| Item | Value |
|------|-------|
| Container | `vllm` (distrobox / podman) |
| GPU | gfx1033, AMD Custom APU (RDNA2) |
| VRAM | ~8 GB (HSA unified memory) |
| ROCm | 6.3.4 at `/opt/rocm` |
| PyTorch | 2.5.1+rocm6.2 |
| vllm | 0.6.6.dev0 source build at `/opt/vllm` |
| venv | `/opt/vllm-env` |
| Key env var | `HSA_OVERRIDE_GFX_VERSION=10.3.0` (required) |

## Model size guide

| Model size | VRAM needed | Example |
|-----------|-------------|---------|
| 1–2B      | ~2–3 GB     | Qwen2.5-1.5B, SmolLM2-1.7B |
| 3–4B      | ~3–5 GB     | Phi-3-mini, Qwen2.5-3B |
| 7B (Q4)   | ~5–6 GB     | Llama-3.2-3B, Mistral-7B-GPTQ |
| 7B (fp16) | ~14 GB      | ❌ too large |
