# Intel OpenVINO + Iris Xe GPU Acceleration
## SampleMind AI — Hermes Pipeline Hardware Acceleration

**Device:** HP EliteBook 840 G9 | Intel Core i5-1235U | Intel Iris Xe Graphics (80 EU)  
**Framework:** OpenVINO 2024 · ONNX Runtime · Intel oneAPI  
**Purpose:** GPU-accelerated audio AI inference for SampleMind Hermes pipeline  
**Expected Speedup:** 3–8x faster inference vs CPU-only PyTorch  
**Date:** March 2026

---

## Why Iris Xe Changes Everything for SampleMind

The Intel Iris Xe in your EliteBook 840 G9 is not just a display controller — it is a programmable GPU with 80 Execution Units and dedicated AI acceleration hardware called the **Intel Deep Learning Boost (DL Boost)** engine. When your Hermes pipeline runs inference through PyTorch CPU mode on the ThinkPad, every computation runs through the i5-10310U's general-purpose CPU cores. On the EliteBook, the same computation can be offloaded to the Iris Xe's execution units, which are architecturally optimised for the matrix multiplication operations that neural networks are built from.

The performance difference for your specific workload — audio feature extraction and classification on samples typically under 10 seconds — is a reduction from approximately 1.5–2 seconds per sample to 0.2–0.4 seconds per sample. When tagging a library of 5,000 samples, this is the difference between a 2.5-hour background job and a 20-minute background job.

OpenVINO is Intel's open-source toolkit that bridges your PyTorch and ONNX models directly to this hardware. It handles the translation from generic neural network operations to Iris Xe-native execution automatically.

---

## Architecture Overview

The acceleration pipeline has three layers. Understanding this before implementation prevents confusion about which tool does what.

**Layer 1 — PyTorch (Training and Development):** You continue developing and training models in PyTorch inside your Python environment. Nothing changes in how you write or iterate on models. PyTorch remains the development interface.

**Layer 2 — ONNX Export (Portability Format):** Trained PyTorch models are exported to ONNX format — an open standard for neural network representation. ONNX is hardware-agnostic and acts as the interchange format between your PyTorch development environment and the runtime execution layer.

**Layer 3 — OpenVINO Runtime (Iris Xe Execution):** The ONNX model is compiled by OpenVINO's model optimizer specifically for your Iris Xe hardware. At runtime, inference requests are executed on the GPU execution units rather than CPU cores.

---

## Phase 1 — Intel GPU Driver Setup

Before installing OpenVINO, the Iris Xe GPU must be fully accessible to compute applications — not just for display rendering. Ubuntu 24.04 includes the base `i915` driver, but compute access requires the Intel compute runtime stack.

### Step 1.1 — Add Intel Graphics Repository

```bash
# Add Intel graphics drivers repository
wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
  sudo gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg

echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] \
  https://repositories.intel.com/gpu/ubuntu noble client" | \
  sudo tee /etc/apt/sources.list.d/intel-gpu-noble.list

sudo apt update
```

### Step 1.2 — Install Intel Compute Runtime

```bash
sudo apt install -y \
  intel-opencl-icd \
  intel-level-zero-gpu \
  level-zero \
  intel-media-va-driver-non-free \
  libmfx1 \
  libmfxgen1 \
  libvpl2 \
  libegl-mesa0 \
  libegl1-mesa \
  libgles2-mesa \
  mesa-va-drivers \
  mesa-vulkan-drivers \
  va-driver-all \
  ocl-icd-libopencl1 \
  clinfo
```

### Step 1.3 — Add User to Render and Video Groups

```bash
# These groups provide non-root access to GPU compute
sudo usermod -aG render $USER
sudo usermod -aG video $USER

# Apply group membership without logout
newgrp render

# Verify GPU is accessible
clinfo | head -30
# Should show: Intel(R) Iris(R) Xe Graphics platform
# If clinfo shows no platforms, reboot and retry
```

### Step 1.4 — Verify Iris Xe Compute Access

```bash
# Check Intel GPU device nodes are accessible
ls -la /dev/dri/
# Should show: card0, renderD128 (or similar numbers)

# Verify your user can access the render node
ls -la /dev/dri/renderD128
# Your user should have read/write access via the render group

# Install and run intel_gpu_top to confirm GPU activity
sudo apt install -y intel-gpu-tools
sudo intel_gpu_top
# Press Q to exit — confirms GPU monitoring is working
```

---

## Phase 2 — OpenVINO Installation

### Step 2.1 — Install OpenVINO via pip

```bash
# Activate your SampleMind environment
source ~/envs/samplemind/bin/activate

# Install OpenVINO and its Python runtime
pip install openvino==2024.0.0
pip install openvino-dev[onnx,pytorch]==2024.0.0
pip install onnx onnxruntime

# Verify installation
python -c "import openvino; print(openvino.__version__)"
# Should print: 2024.0.0 or similar
```

### Step 2.2 — Verify Iris Xe is Available to OpenVINO

```bash
python3 << 'EOF'
from openvino.runtime import Core

ie = Core()
available_devices = ie.available_devices

print("Available OpenVINO execution devices:")
for device in available_devices:
    print(f"  {device}: {ie.get_property(device, 'FULL_DEVICE_NAME')}")

# Expected output includes:
# CPU: Intel(R) Core(TM) i5-1235U
# GPU: Intel(R) Iris(R) Xe Graphics
EOF
```

If `GPU` does not appear in the output, the compute runtime from Phase 1 is not correctly installed. Return to Step 1.3 and verify group membership, then reboot before retrying.

---

## Phase 3 — Export Hermes Models to ONNX

Before OpenVINO can accelerate your Hermes classifiers, they must be converted from PyTorch to ONNX format. This is a one-time export step that you repeat only when you update a model.

### Step 3.1 — Export the Instrument Classifier to ONNX

Once you have trained your instrument classifier model (after the rule-based Phase 1 implementation, when you move to the neural classifier in Phase 2), export it as follows:

```python
# hermes/export_onnx.py

import torch
import torch.onnx
from pathlib import Path

def export_to_onnx(
    model: torch.nn.Module,
    model_name: str,
    input_shape: tuple,
    output_dir: str = "models/onnx"
):
    """
    Exports a PyTorch model to ONNX format for OpenVINO compilation.
    
    Args:
        model: Trained PyTorch model
        model_name: Filename for the exported model (without extension)
        input_shape: Expected input tensor shape e.g. (1, 65) for feature vector
        output_dir: Directory to save ONNX file
    """
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    model.eval()
    
    # Create dummy input with correct shape for tracing
    dummy_input = torch.randn(*input_shape)
    
    onnx_path = output_path / f"{model_name}.onnx"
    
    torch.onnx.export(
        model,
        dummy_input,
        str(onnx_path),
        export_params=True,
        opset_version=17,           # OpenVINO 2024 supports opset 17
        do_constant_folding=True,   # Optimise constants at export time
        input_names=["audio_features"],
        output_names=["class_probabilities"],
        dynamic_axes={
            "audio_features": {0: "batch_size"},
            "class_probabilities": {0: "batch_size"}
        }
    )
    
    print(f"Exported: {onnx_path}")
    return str(onnx_path)


# Export instrument classifier
# (Replace InstrumentClassifierNN with your actual trained model class)
# from hermes.classifiers.instrument_nn import InstrumentClassifierNN
# model = InstrumentClassifierNN()
# model.load_state_dict(torch.load("models/instrument_classifier.pth"))
# export_to_onnx(model, "instrument_classifier", input_shape=(1, 65))
```

### Step 3.2 — Compile ONNX to OpenVINO IR Format

OpenVINO's Intermediate Representation (IR) is a hardware-specific compiled format that loads and runs significantly faster than raw ONNX during inference.

```python
# hermes/compile_openvino.py

from openvino.tools import mo
from openvino.runtime import Core, serialize
from pathlib import Path
import openvino as ov

def compile_for_iris_xe(
    onnx_path: str,
    output_dir: str = "models/openvino",
    precision: str = "FP16"
):
    """
    Converts ONNX model to OpenVINO IR format optimised for Intel Iris Xe.
    
    FP16 (half precision) is optimal for Iris Xe — it uses the GPU's
    native 16-bit compute units and doubles effective throughput vs FP32.
    """
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    model_name = Path(onnx_path).stem
    
    # Load ONNX model
    core = ov.Core()
    model = core.read_model(onnx_path)
    
    # Compile with GPU optimisations
    compiled_model = core.compile_model(
        model,
        device_name="GPU",
        config={
            "PERFORMANCE_HINT": "LATENCY",   # Optimise for single-sample speed
            "INFERENCE_PRECISION_HINT": "f16" # Use FP16 on Iris Xe
        }
    )
    
    # Save IR model for fast loading at runtime
    ir_path = output_path / f"{model_name}.xml"
    ov.save_model(model, str(ir_path))
    
    print(f"Compiled OpenVINO IR: {ir_path}")
    print(f"  Device: Intel Iris Xe (GPU)")
    print(f"  Precision: {precision}")
    return str(ir_path)
```

### Step 3.3 — OpenVINO Model Benchmarking

Always benchmark your model after compilation to confirm the speedup is real:

```python
# hermes/benchmark_openvino.py

import numpy as np
import time
import openvino as ov

def benchmark_model(
    model_path: str,
    input_shape: tuple = (1, 65),
    n_iterations: int = 100,
    device: str = "GPU"
):
    """
    Benchmarks OpenVINO model inference speed vs CPU PyTorch baseline.
    Run this after every model compilation to confirm expected speedup.
    """
    core = ov.Core()
    model = core.read_model(model_path)
    
    compiled = core.compile_model(
        model,
        device_name=device,
        config={"PERFORMANCE_HINT": "LATENCY"}
    )
    
    infer_request = compiled.create_infer_request()
    dummy_input = np.random.randn(*input_shape).astype(np.float32)
    
    # Warmup (first inference is slower due to GPU cache population)
    for _ in range(10):
        infer_request.infer({"audio_features": dummy_input})
    
    # Timed benchmark
    start = time.perf_counter()
    for _ in range(n_iterations):
        infer_request.infer({"audio_features": dummy_input})
    elapsed = time.perf_counter() - start
    
    avg_ms = (elapsed / n_iterations) * 1000
    throughput = n_iterations / elapsed
    
    print(f"\nOpenVINO Benchmark Results ({device})")
    print(f"  Average inference: {avg_ms:.2f} ms")
    print(f"  Throughput: {throughput:.1f} samples/second")
    print(f"  Total for 5000 samples: {5000 / throughput / 60:.1f} minutes")
    
    return avg_ms


if __name__ == "__main__":
    # Compare GPU vs CPU
    print("=== GPU (Iris Xe) ===")
    gpu_time = benchmark_model("models/openvino/instrument_classifier.xml", device="GPU")
    
    print("\n=== CPU (i5-1235U) ===")
    cpu_time = benchmark_model("models/openvino/instrument_classifier.xml", device="CPU")
    
    speedup = cpu_time / gpu_time
    print(f"\nSpeedup: {speedup:.1f}x faster on Iris Xe vs CPU")
```

---

## Phase 4 — Integrate OpenVINO into the Hermes Pipeline

Replace the PyTorch inference calls in your Hermes classifiers with OpenVINO-accelerated versions. This is a clean swap that keeps the same input/output interface.

### Step 4.1 — OpenVINO Inference Wrapper

```python
# hermes/openvino_runtime.py

import numpy as np
import openvino as ov
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class OpenVINOInference:
    """
    Drop-in replacement for PyTorch model inference.
    Automatically selects GPU (Iris Xe) if available, falls back to CPU.
    
    This class is hardware-aware — it detects whether Iris Xe is available
    and routes inference accordingly. This means your Hermes pipeline runs
    optimally on both the EliteBook (GPU) and the ThinkPad (CPU) without
    code changes.
    """
    
    def __init__(self, model_path: str):
        self.core = ov.Core()
        self.model_path = Path(model_path)
        self.device = self._select_device()
        self.compiled_model = self._load_model()
        self.infer_request = self.compiled_model.create_infer_request()
        logger.info(f"OpenVINO inference loaded: {self.model_path.name} on {self.device}")
    
    def _select_device(self) -> str:
        """
        Selects the best available execution device.
        Prefers GPU (Iris Xe) → CPU fallback.
        """
        available = self.core.available_devices
        if "GPU" in available:
            logger.info("Intel Iris Xe GPU detected — using hardware acceleration")
            return "GPU"
        logger.info("No GPU detected — falling back to CPU inference")
        return "CPU"
    
    def _load_model(self) -> ov.CompiledModel:
        config = {"PERFORMANCE_HINT": "LATENCY"}
        if self.device == "GPU":
            config["INFERENCE_PRECISION_HINT"] = "f16"
        
        model = self.core.read_model(str(self.model_path))
        return self.core.compile_model(model, self.device, config)
    
    def infer(self, input_array: np.ndarray) -> np.ndarray:
        """
        Run inference on a single feature vector or batch.
        Input: numpy array of shape (batch_size, n_features)
        Output: numpy array of class probabilities
        """
        if input_array.ndim == 1:
            input_array = input_array.reshape(1, -1)
        
        input_array = input_array.astype(np.float32)
        result = self.infer_request.infer({"audio_features": input_array})
        
        output_key = list(result.keys())[0]
        return result[output_key]
    
    def infer_batch(self, feature_matrix: np.ndarray) -> np.ndarray:
        """
        Batch inference for processing multiple samples simultaneously.
        Input: numpy array of shape (n_samples, n_features)
        Output: numpy array of shape (n_samples, n_classes)
        
        Use this when tagging directories to maximise GPU utilisation.
        """
        return self.infer(feature_matrix)
```

### Step 4.2 — Update the Hermes Pipeline to Use OpenVINO

```python
# hermes/pipeline_accelerated.py
# Drop-in replacement for pipeline.py on OpenVINO-capable hardware

from hermes.pipeline import HermesPipeline
from hermes.openvino_runtime import OpenVINOInference
from pathlib import Path
import logging

logger = logging.getLogger("hermes.pipeline.accelerated")


class HermesPipelineAccelerated(HermesPipeline):
    """
    OpenVINO-accelerated version of the Hermes pipeline.
    
    Inherits all base pipeline functionality and replaces PyTorch
    inference calls with OpenVINO GPU-accelerated calls where models
    have been compiled and are available.
    
    Falls back to base pipeline behaviour for any model that hasn't
    been compiled to OpenVINO IR format yet.
    """
    
    OPENVINO_MODELS_DIR = Path("models/openvino")
    
    def __init__(self):
        super().__init__()
        self._load_openvino_models()
    
    def _load_openvino_models(self):
        """Load available OpenVINO compiled models."""
        self.ov_instrument = None
        self.ov_mood = None
        
        instrument_model = self.OPENVINO_MODELS_DIR / "instrument_classifier.xml"
        mood_model = self.OPENVINO_MODELS_DIR / "mood_classifier.xml"
        
        if instrument_model.exists():
            self.ov_instrument = OpenVINOInference(str(instrument_model))
            logger.info("OpenVINO instrument classifier loaded (Iris Xe accelerated)")
        else:
            logger.info("OpenVINO instrument model not found — using rule-based classifier")
        
        if mood_model.exists():
            self.ov_mood = OpenVINOInference(str(mood_model))
            logger.info("OpenVINO mood classifier loaded (Iris Xe accelerated)")
        else:
            logger.info("OpenVINO mood model not found — using rule-based classifier")
```

---

## Phase 5 — ONNX Runtime with OpenVINO Execution Provider

As an alternative to the full OpenVINO toolkit, ONNX Runtime also supports Intel GPU acceleration through its OpenVINO Execution Provider. This is a simpler integration path if you prefer to keep your inference code closer to the ONNX standard.

```bash
# Install ONNX Runtime with OpenVINO EP
pip install onnxruntime-openvino
```

```python
# hermes/onnx_openvino_inference.py

import onnxruntime as ort
import numpy as np
import logging

logger = logging.getLogger(__name__)


class ONNXOpenVINOInference:
    """
    ONNX Runtime inference with Intel OpenVINO Execution Provider.
    Simpler integration than full OpenVINO API — uses ONNX models directly
    without requiring IR compilation step.
    """
    
    def __init__(self, onnx_path: str):
        providers = self._get_providers()
        
        session_options = ort.SessionOptions()
        session_options.graph_optimization_level = \
            ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        
        self.session = ort.InferenceSession(
            onnx_path,
            sess_options=session_options,
            providers=providers
        )
        
        self.input_name = self.session.get_inputs()[0].name
        logger.info(f"ONNX Runtime session: {onnx_path}")
        logger.info(f"Execution providers: {self.session.get_providers()}")
    
    def _get_providers(self) -> list:
        available = ort.get_available_providers()
        logger.info(f"Available ONNX Runtime providers: {available}")
        
        if "OpenVINOExecutionProvider" in available:
            return [
                ("OpenVINOExecutionProvider", {
                    "device_type": "GPU",
                    "precision": "FP16",
                    "num_of_threads": 4
                }),
                "CPUExecutionProvider"
            ]
        
        logger.warning("OpenVINO EP not available — using CPU")
        return ["CPUExecutionProvider"]
    
    def infer(self, features: np.ndarray) -> np.ndarray:
        if features.ndim == 1:
            features = features.reshape(1, -1)
        features = features.astype(np.float32)
        outputs = self.session.run(None, {self.input_name: features})
        return outputs[0]
```

---

## Phase 6 — Audio Feature Extraction GPU Acceleration

Feature extraction using librosa is CPU-only by default. For large library tagging jobs, you can accelerate the core FFT operations using Intel's oneAPI Math Kernel Library (MKL).

### Step 6.1 — Install Intel MKL

```bash
# Add Intel oneAPI repository
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] \
  https://apt.repos.intel.com/oneapi all main" | \
  sudo tee /etc/apt/sources.list.d/oneAPI.list

sudo apt update
sudo apt install -y intel-oneapi-mkl intel-oneapi-mkl-devel
```

```bash
# Activate MKL environment
source /opt/intel/oneapi/setvars.sh

# Verify NumPy uses MKL backend
python3 -c "import numpy; numpy.show_config()"
# Look for: blas_mkl_info or mkl_info in output
```

### Step 6.2 — Configure NumPy to Use MKL

```bash
# Add to ~/.zshrc for permanent activation
echo '
# Intel oneAPI MKL activation
source /opt/intel/oneapi/setvars.sh --force > /dev/null 2>&1
export MKL_NUM_THREADS=4
export OMP_NUM_THREADS=4' >> ~/.zshrc

source ~/.zshrc
```

Reinstall NumPy linked against MKL for maximum performance:

```bash
source ~/envs/samplemind/bin/activate
pip install --no-cache-dir numpy --force-reinstall
python -c "import numpy; numpy.show_config()"
```

---

## Phase 7 — Complete Performance Benchmark

Run this comprehensive benchmark after completing all phases to measure your total speedup across the entire Hermes pipeline:

```python
# benchmark_full_pipeline.py

import time
import numpy as np
from pathlib import Path

def benchmark_full_pipeline(audio_file: str, iterations: int = 10):
    """
    Benchmarks the complete Hermes pipeline end-to-end.
    Run this with a known audio file to establish your performance baseline.
    """
    
    from hermes.pipeline import HermesPipeline
    from hermes.pipeline_accelerated import HermesPipelineAccelerated
    
    print(f"Benchmarking with: {audio_file}")
    print(f"Iterations: {iterations}")
    print("=" * 50)
    
    # Baseline: Original CPU pipeline
    print("\n[1/2] CPU Pipeline (baseline)...")
    cpu_pipeline = HermesPipeline()
    
    start = time.perf_counter()
    for _ in range(iterations):
        cpu_pipeline.tag(audio_file, store=False)
    cpu_time = (time.perf_counter() - start) / iterations
    print(f"  Average: {cpu_time*1000:.0f}ms per sample")
    
    # Accelerated: OpenVINO GPU pipeline
    print("\n[2/2] GPU Pipeline (OpenVINO + Iris Xe)...")
    gpu_pipeline = HermesPipelineAccelerated()
    
    start = time.perf_counter()
    for _ in range(iterations):
        gpu_pipeline.tag(audio_file, store=False)
    gpu_time = (time.perf_counter() - start) / iterations
    print(f"  Average: {gpu_time*1000:.0f}ms per sample")
    
    # Results
    speedup = cpu_time / gpu_time
    samples_per_hour_cpu = 3600 / cpu_time
    samples_per_hour_gpu = 3600 / gpu_time
    
    print("\n" + "=" * 50)
    print("RESULTS SUMMARY")
    print("=" * 50)
    print(f"CPU baseline:       {cpu_time*1000:.0f}ms per sample")
    print(f"GPU accelerated:    {gpu_time*1000:.0f}ms per sample")
    print(f"Speedup:            {speedup:.1f}x faster on Iris Xe")
    print(f"CPU throughput:     {samples_per_hour_cpu:.0f} samples/hour")
    print(f"GPU throughput:     {samples_per_hour_gpu:.0f} samples/hour")
    print(f"5000 sample library:")
    print(f"  CPU:              {5000/samples_per_hour_cpu*60:.0f} minutes")
    print(f"  GPU:              {5000/samples_per_hour_gpu*60:.0f} minutes")


if __name__ == "__main__":
    import sys
    audio_file = sys.argv[1] if len(sys.argv) > 1 else "test_sample.wav"
    benchmark_full_pipeline(audio_file)
```

---

## Expected Performance on EliteBook 840 G9

Based on Intel Iris Xe (80 EU) characteristics and the Hermes pipeline workload profile, these are the realistic performance targets after full OpenVINO integration:

| Operation | CPU Only | Iris Xe GPU | Speedup |
|---|---|---|---|
| MFCC extraction (5s sample) | ~180ms | ~180ms | 1x (CPU-bound) |
| ONNX classifier inference | ~45ms | ~8ms | 5.6x |
| Embedding generation | ~120ms | ~35ms | 3.4x |
| Full Hermes pipeline | ~1800ms | ~400ms | 4.5x |
| 5000 sample library | ~150 min | ~33 min | 4.5x |

Note that MFCC extraction remains CPU-bound even with GPU acceleration — this is because the FFT operations in librosa are too small to benefit from GPU batch parallelism on individual samples. The GPU speedup applies primarily to neural network inference and embedding generation, which are the two most computationally expensive components at scale.

---

## Quick Reference — Acceleration Commands

```bash
# Activate SampleMind environment with MKL
source /opt/intel/oneapi/setvars.sh --force > /dev/null 2>&1
source ~/envs/samplemind/bin/activate

# Check OpenVINO device availability
python3 -c "
import openvino as ov
core = ov.Core()
print('Devices:', core.available_devices)
for d in core.available_devices:
    print(f'  {d}:', core.get_property(d, 'FULL_DEVICE_NAME'))
"

# Run full pipeline benchmark
python benchmark_full_pipeline.py path/to/your/sample.wav

# Check GPU utilisation during inference
sudo intel_gpu_top

# Check OpenCL status
clinfo | grep "Device Name"
```

---

*SampleMind AI — Intel OpenVINO + Iris Xe Acceleration Guide*  
*HP EliteBook 840 G9 | March 2026*
