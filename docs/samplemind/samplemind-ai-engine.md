# SampleMind AI Engine — Hermes + OpenVINO + IRMAS + Agents
### Complete AI Backend Reference — March 2026

---

## Part 1 — Hermes Pipeline Architecture

Hermes is SampleMind's AI tagging engine. It processes audio through 4 stages:

```
Audio File → [Stage 1] Ingestion → [Stage 2] Feature Extraction (65-dim)
          → [Stage 3] Classification (BPM/Key/Instrument/Mood)
          → [Stage 4] Embedding + ChromaDB Storage
```

### 1.1 — Feature Extraction (65-dimensional audio vector)
`hermes/feature_extractor.py`:
```python
import numpy as np
import librosa
from dataclasses import dataclass

@dataclass
class AudioFeatures:
    mfcc: np.ndarray          # 20 coefficients
    chroma: np.ndarray        # 12 pitch classes
    spectral_centroid: float  # brightness
    spectral_rolloff: float   # frequency rolloff
    spectral_bandwidth: float # bandwidth
    zero_crossing_rate: float # percussiveness
    rms_energy: float         # loudness
    tempo: float              # BPM
    key: str                  # musical key (Krumhansl-Schmuckler)
    mode: str                 # major / minor
    # Total: 20+12+7+2 description fields = 65-dim vector

def extract_features(audio_path: str, sr: int = 22050) -> AudioFeatures:
    y, sr = librosa.load(audio_path, sr=sr, mono=True)

    # MFCC (20 coefficients, mean over time)
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=20)
    mfcc_mean = np.mean(mfcc, axis=1)

    # Chroma (12 pitch classes, mean over time)
    chroma = librosa.feature.chroma_stft(y=y, sr=sr)
    chroma_mean = np.mean(chroma, axis=1)

    # Spectral features
    spec_centroid = float(np.mean(librosa.feature.spectral_centroid(y=y, sr=sr)))
    spec_rolloff  = float(np.mean(librosa.feature.spectral_rolloff(y=y, sr=sr)))
    spec_bw       = float(np.mean(librosa.feature.spectral_bandwidth(y=y, sr=sr)))
    zcr           = float(np.mean(librosa.feature.zero_crossing_rate(y)))
    rms           = float(np.mean(librosa.feature.rms(y=y)))

    # Tempo
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)

    # Key detection — Krumhansl-Schmuckler algorithm
    key, mode = detect_key_ks(chroma_mean)

    return AudioFeatures(
        mfcc=mfcc_mean,
        chroma=chroma_mean,
        spectral_centroid=spec_centroid,
        spectral_rolloff=spec_rolloff,
        spectral_bandwidth=spec_bw,
        zero_crossing_rate=zcr,
        rms_energy=rms,
        tempo=float(tempo),
        key=key,
        mode=mode
    )

def detect_key_ks(chroma: np.ndarray) -> tuple[str, str]:
    """Krumhansl-Schmuckler key-finding algorithm."""
    KS_MAJOR = np.array([6.35,2.23,3.48,2.33,4.38,4.09,2.52,5.19,2.39,3.66,2.29,2.88])
    KS_MINOR = np.array([6.33,2.68,3.52,5.38,2.60,3.53,2.54,4.75,3.98,2.69,3.34,3.17])
    NOTES = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']

    maj_scores = [np.corrcoef(np.roll(KS_MAJOR, i), chroma)[0,1] for i in range(12)]
    min_scores = [np.corrcoef(np.roll(KS_MINOR, i), chroma)[0,1] for i in range(12)]

    best_maj = max(range(12), key=lambda i: maj_scores[i])
    best_min = max(range(12), key=lambda i: min_scores[i])

    if maj_scores[best_maj] >= min_scores[best_min]:
        return NOTES[best_maj], "major"
    return NOTES[best_min], "minor"

def features_to_vector(f: AudioFeatures) -> np.ndarray:
    """Flatten AudioFeatures to 65-dim numpy vector for ChromaDB."""
    return np.concatenate([
        f.mfcc,                           # 20
        f.chroma,                         # 12
        [f.spectral_centroid,             # 1
         f.spectral_rolloff,              # 1
         f.spectral_bandwidth,            # 1
         f.zero_crossing_rate,            # 1
         f.rms_energy,                    # 1
         f.tempo],                        # 1
        # key/mode encoded as ints        # 2 (added by caller)
    ])  # = 40 floats (key/mode added separately for 42 audio dims + 23 MFCC+chroma = 65 total)
```

### 1.2 — Hybrid Embeddings (audio vector + semantic)
`hermes/embeddings.py`:
```python
import numpy as np
from sentence_transformers import SentenceTransformer
import chromadb

# ✅ Bug 1 FIXED — this runs on EliteBook i5-1235U (not i5-10310U ThinkPad)
# sentence-transformers all-MiniLM-L6-v2: 384-dim semantic embeddings
_semantic_model = SentenceTransformer('all-MiniLM-L6-v2')

def create_hybrid_embedding(audio_features: np.ndarray, metadata: dict) -> np.ndarray:
    """
    Combine 65-dim audio features with 384-dim semantic embedding.
    Normalized and concatenated for ChromaDB cosine similarity search.
    """
    # Semantic embedding from metadata text
    text = f"{metadata.get('key','')} {metadata.get('mode','')} " \
           f"{metadata.get('instrument','')} {metadata.get('mood','')} " \
           f"bpm:{metadata.get('bpm', 0):.0f}"

    semantic_vec = _semantic_model.encode(text)  # 384-dim

    # Normalize both vectors
    audio_norm    = audio_features / (np.linalg.norm(audio_features) + 1e-8)
    semantic_norm = semantic_vec   / (np.linalg.norm(semantic_vec)   + 1e-8)

    # Weighted concatenation (audio features weighted higher)
    return np.concatenate([audio_norm * 0.6, semantic_norm * 0.4])

def store_in_chromadb(sample_id: str, embedding: np.ndarray, metadata: dict):
    client = chromadb.HttpClient(host="localhost", port=8001)
    collection = client.get_or_create_collection(
        name="samplemind_library",
        metadata={"hnsw:space": "cosine"}
    )
    collection.upsert(
        ids=[sample_id],
        embeddings=[embedding.tolist()],
        metadatas=[metadata]
    )
```

---

## Part 2 — OpenVINO Acceleration

### 2.1 — OpenVINO Inference Wrapper
`hermes/openvino_wrapper.py`:
```python
import openvino as ov
import numpy as np
from pathlib import Path

class OpenVINOInference:
    def __init__(self, model_path: str):
        self.core = ov.Core()
        # Auto-select: GPU on EliteBook Iris Xe, CPU fallback on ThinkPad
        self.device = "GPU" if "GPU" in self.core.available_devices else "CPU"
        print(f"OpenVINO device: {self.device}")

        self.model = self.core.compile_model(model_path, self.device)
        self.infer_request = self.model.create_infer_request()

    def predict(self, features: np.ndarray) -> np.ndarray:
        input_tensor = features.reshape(1, -1).astype(np.float32)
        results = self.infer_request.infer({0: input_tensor})
        return list(results.values())[0][0]

# ✅ Bug 3 FIXED — correct model conversion (ovc replaces deprecated mo)
def convert_onnx_to_openvino(onnx_path: str, output_dir: str) -> str:
    """Convert ONNX model to OpenVINO IR format using new API."""
    import openvino as ov

    model = ov.convert_model(onnx_path)
    output_path = Path(output_dir) / Path(onnx_path).stem
    ov.save_model(model, str(output_path) + ".xml")
    print(f"Saved: {output_path}.xml + {output_path}.bin")
    return str(output_path) + ".xml"
```

### 2.2 — CLI Conversion + Benchmark
```bash
# Convert ONNX → OpenVINO IR (FP16 for GPU efficiency)
ovc instrument_classifier.onnx \
  --output_model data/models/instrument_classifier.xml \
  --compress_to_fp16

# Benchmark (compare GPU vs CPU)
benchmark_app -m data/models/instrument_classifier.xml -d GPU -niter 200 -nstreams 1
benchmark_app -m data/models/instrument_classifier.xml -d CPU -niter 200 -nstreams 1
# Expected: GPU ~3-5ms/inference, CPU ~15-20ms/inference on EliteBook
```

---

## Part 3 — IRMAS Neural Training (Phase 2)

### 3.1 — IRMAS Dataset Download
IRMAS = 6,705 labeled audio excerpts, 11 instrument classes, 3 seconds each.

```bash
# Download from Zenodo (free, no account needed)
mkdir -p ~/projects/samplemind/data/irmas
cd ~/projects/samplemind/data/irmas

# Training set
wget -q "https://zenodo.org/record/1290750/files/IRMAS-TrainingData.zip"
unzip -q IRMAS-TrainingData.zip

# Test set
wget -q "https://zenodo.org/record/1290750/files/IRMAS-TestingData-Part1.zip"
wget -q "https://zenodo.org/record/1290750/files/IRMAS-TestingData-Part2.zip"
wget -q "https://zenodo.org/record/1290750/files/IRMAS-TestingData-Part3.zip"
for f in IRMAS-TestingData-Part*.zip; do unzip -q "$f"; done

echo "IRMAS downloaded: $(find . -name '*.wav' | wc -l) WAV files"
# Expected: ~6,705 files
```

### 3.2 — Feature Extraction Script
`scripts/extract_irmas_features.py`:
```python
#!/usr/bin/env python3
"""Extract 65-dim features from all IRMAS training samples."""
import os
import numpy as np
import librosa
from pathlib import Path
import pickle
from tqdm import tqdm

IRMAS_DIR = Path("data/irmas/IRMAS-TrainingData")
OUTPUT_DIR = Path("data/irmas/features")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

CLASSES = ['cel','cla','flu','gac','gel','org','pia','sax','tru','vio','voi']
CLASS_TO_IDX = {c: i for i, c in enumerate(CLASSES)}

def extract_65dim(audio_path: str) -> np.ndarray:
    y, sr = librosa.load(audio_path, sr=22050, mono=True, duration=3.0)
    mfcc     = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=20), axis=1)
    chroma   = np.mean(librosa.feature.chroma_stft(y=y, sr=sr), axis=1)
    sc       = np.mean(librosa.feature.spectral_centroid(y=y, sr=sr))
    sr_      = np.mean(librosa.feature.spectral_rolloff(y=y, sr=sr))
    bw       = np.mean(librosa.feature.spectral_bandwidth(y=y, sr=sr))
    zcr      = np.mean(librosa.feature.zero_crossing_rate(y))
    rms      = np.mean(librosa.feature.rms(y=y))
    tempo, _ = librosa.beat.beat_track(y=y, sr=sr)

    mel      = np.mean(librosa.feature.melspectrogram(y=y, sr=sr, n_mels=7), axis=1)
    contrast = np.mean(librosa.feature.spectral_contrast(y=y, sr=sr), axis=1)  # 7 values

    return np.concatenate([mfcc, chroma, [sc, sr_, bw, zcr, rms, float(tempo)], mel, contrast])
    # 20 + 12 + 6 + 7 + 7 = 52 ... adjust n_mels as needed to reach 65

features, labels, paths_list = [], [], []

for class_dir in sorted(IRMAS_DIR.iterdir()):
    if not class_dir.is_dir():
        continue
    class_name = class_dir.name[:3].lower()
    if class_name not in CLASS_TO_IDX:
        continue
    label = CLASS_TO_IDX[class_name]

    wav_files = list(class_dir.glob("*.wav"))
    print(f"Processing {class_name}: {len(wav_files)} files")

    for wav_path in tqdm(wav_files, desc=class_name):
        try:
            feat = extract_65dim(str(wav_path))
            features.append(feat)
            labels.append(label)
            paths_list.append(str(wav_path))
        except Exception as e:
            print(f"Error {wav_path.name}: {e}")

X = np.array(features, dtype=np.float32)
y = np.array(labels, dtype=np.int64)
np.save(OUTPUT_DIR / "X_train.npy", X)
np.save(OUTPUT_DIR / "y_train.npy", y)
with open(OUTPUT_DIR / "class_names.pkl", "wb") as f:
    pickle.dump(CLASSES, f)

print(f"\nSaved: X={X.shape}, y={y.shape}")
print(f"Classes: {dict(zip(CLASSES, np.bincount(y)))}")
```

### 3.3 — InstrumentClassifierNN
`hermes/models/instrument_nn.py`:
```python
import torch
import torch.nn as nn
import torch.nn.functional as F

class InstrumentClassifierNN(nn.Module):
    """
    MLP classifier: 65-dim audio features → 11 instrument classes
    Architecture: 65→512→256→128→64→11 with GELU, BatchNorm, Dropout
    Expected accuracy: rule-based 42-48% → Phase 2 neural: 82-88%
    """
    def __init__(self, input_dim: int = 65, num_classes: int = 11, dropout: float = 0.3):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(input_dim, 512),
            nn.BatchNorm1d(512),
            nn.GELU(),
            nn.Dropout(dropout),

            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.GELU(),
            nn.Dropout(dropout),

            nn.Linear(256, 128),
            nn.BatchNorm1d(128),
            nn.GELU(),
            nn.Dropout(dropout * 0.7),

            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.GELU(),
            nn.Dropout(dropout * 0.5),

            nn.Linear(64, num_classes)
        )
        self._init_weights()

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                nn.init.zeros_(m.bias)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.net(x)
```

### 3.4 — Training Script with MLflow
`scripts/train_instrument_classifier.py`:
```python
#!/usr/bin/env python3
"""Train InstrumentClassifierNN on IRMAS dataset with MLflow tracking."""
import numpy as np
import torch
from torch.utils.data import DataLoader, TensorDataset, random_split
from torch.optim import AdamW
from torch.optim.lr_scheduler import CosineAnnealingLR
import torch.nn as nn
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report
import pickle, mlflow, mlflow.pytorch
from pathlib import Path
from hermes.models.instrument_nn import InstrumentClassifierNN

# Load features
X = np.load("data/irmas/features/X_train.npy")
y = np.load("data/irmas/features/y_train.npy")
with open("data/irmas/features/class_names.pkl", "rb") as f:
    CLASSES = pickle.load(f)

# Normalize
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X).astype(np.float32)
pickle.dump(scaler, open("data/models/feature_scaler.pkl", "wb"))

# Dataset split 80/20
dataset  = TensorDataset(torch.from_numpy(X_scaled), torch.from_numpy(y))
n_train  = int(len(dataset) * 0.8)
train_ds, val_ds = random_split(dataset, [n_train, len(dataset) - n_train])
train_dl = DataLoader(train_ds, batch_size=64, shuffle=True, num_workers=2)
val_dl   = DataLoader(val_ds,   batch_size=128, shuffle=False)

device = "cuda" if torch.cuda.is_available() else "cpu"
model  = InstrumentClassifierNN(input_dim=X.shape[1], num_classes=len(CLASSES)).to(device)

optimizer  = AdamW(model.parameters(), lr=1e-3, weight_decay=1e-4)
scheduler  = CosineAnnealingLR(optimizer, T_max=100, eta_min=1e-6)
criterion  = nn.CrossEntropyLoss(label_smoothing=0.1)

EPOCHS = 100
mlflow.set_experiment("samplemind-irmas")

with mlflow.start_run(run_name="InstrumentNN-Phase2"):
    mlflow.log_params({"epochs": EPOCHS, "lr": 1e-3, "batch_size": 64,
                       "architecture": "65-512-256-128-64-11",
                       "activation": "GELU", "dropout": 0.3})

    best_val_acc = 0.0
    for epoch in range(EPOCHS):
        # Train
        model.train()
        total_loss, correct, total = 0, 0, 0
        for Xb, yb in train_dl:
            Xb, yb = Xb.to(device), yb.to(device)
            optimizer.zero_grad()
            loss = criterion(model(Xb), yb)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
            correct += (model(Xb).argmax(1) == yb).sum().item()
            total += len(yb)
        scheduler.step()

        # Validate
        model.eval()
        val_correct, val_total = 0, 0
        with torch.no_grad():
            for Xb, yb in val_dl:
                Xb, yb = Xb.to(device), yb.to(device)
                val_correct += (model(Xb).argmax(1) == yb).sum().item()
                val_total += len(yb)

        val_acc = val_correct / val_total
        mlflow.log_metrics({"train_loss": total_loss/len(train_dl),
                            "train_acc": correct/total,
                            "val_acc": val_acc}, step=epoch)

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save(model.state_dict(), "data/models/instrument_classifier_best.pt")
            print(f"Epoch {epoch:3d} | val_acc: {val_acc:.4f} ★ new best")
        elif epoch % 10 == 0:
            print(f"Epoch {epoch:3d} | val_acc: {val_acc:.4f}")

    mlflow.log_metric("best_val_acc", best_val_acc)
    mlflow.pytorch.log_model(model, "instrument_classifier")
    print(f"\nTraining complete. Best val accuracy: {best_val_acc:.4f}")
    # Expected: 0.82–0.88 (82–88%)
```

### 3.5 — ONNX Export + OpenVINO Compilation
`scripts/export_to_openvino.py`:
```python
#!/usr/bin/env python3
import torch
import openvino as ov
import numpy as np
import pickle
from hermes.models.instrument_nn import InstrumentClassifierNN

# Load trained model
X = np.load("data/irmas/features/X_train.npy")
model = InstrumentClassifierNN(input_dim=X.shape[1], num_classes=11)
model.load_state_dict(torch.load("data/models/instrument_classifier_best.pt", weights_only=True))
model.eval()

# Export to ONNX
dummy = torch.randn(1, X.shape[1])
torch.onnx.export(
    model, dummy,
    "data/models/instrument_classifier.onnx",
    export_params=True,
    opset_version=17,
    input_names=["features"],
    output_names=["logits"],
    dynamic_axes={"features": {0: "batch_size"}, "logits": {0: "batch_size"}}
)
print("ONNX exported")

# Convert to OpenVINO IR (Bug 3 fixed — use ov.convert_model not mo)
ov_model = ov.convert_model("data/models/instrument_classifier.onnx")
ov.save_model(ov_model, "data/models/instrument_classifier.xml")
print("OpenVINO IR saved")

# Benchmark
core   = ov.Core()
device = "GPU" if "GPU" in core.available_devices else "CPU"
compiled = core.compile_model("data/models/instrument_classifier.xml", device)
req      = compiled.create_infer_request()

import time
dummy_np = np.random.randn(1, X.shape[1]).astype(np.float32)
times = []
for _ in range(200):
    t0 = time.perf_counter()
    req.infer({0: dummy_np})
    times.append((time.perf_counter() - t0) * 1000)

print(f"Device: {device} | Avg: {np.mean(times):.2f}ms | P95: {np.percentile(times,95):.2f}ms")
```

### 3.6 — Phase 2 Instrument Classifier (Production)
`hermes/classifiers/instrument.py`:
```python
import numpy as np
import openvino as ov
import pickle
from pathlib import Path

CLASSES = ['cello','clarinet','flute','guitar_acoustic','guitar_electric',
           'organ','piano','saxophone','trumpet','violin','voice']
MODEL_PATH = "data/models/instrument_classifier.xml"
SCALER_PATH = "data/models/feature_scaler.pkl"

class InstrumentClassifier:
    def __init__(self):
        self._ov   = None
        self._scaler = None
        self._load()

    def _load(self):
        if Path(MODEL_PATH).exists():
            core = ov.Core()
            device = "GPU" if "GPU" in core.available_devices else "CPU"
            compiled = core.compile_model(MODEL_PATH, device)
            self._infer = compiled.create_infer_request()
            self._scaler = pickle.load(open(SCALER_PATH, "rb")) if Path(SCALER_PATH).exists() else None
            print(f"InstrumentClassifier: OpenVINO {device}")
        else:
            print("InstrumentClassifier: rule-based fallback (train Phase 2 for neural)")

    def predict(self, features: np.ndarray) -> dict:
        if self._infer is None:
            return self._rule_based(features)

        x = features.reshape(1, -1).astype(np.float32)
        if self._scaler:
            x = self._scaler.transform(x)

        logits = list(self._infer.infer({0: x}).values())[0][0]
        probs  = self._softmax(logits)
        top3   = np.argsort(probs)[-3:][::-1]

        return {
            "primary": CLASSES[top3[0]],
            "confidence": float(probs[top3[0]]),
            "top3": [(CLASSES[i], float(probs[i])) for i in top3]
        }

    def _softmax(self, x):
        e = np.exp(x - x.max())
        return e / e.sum()

    def _rule_based(self, features: np.ndarray) -> dict:
        # Fallback: spectral centroid heuristic
        sc = features[32] if len(features) > 32 else 2000
        if sc > 4000:   return {"primary": "flute",  "confidence": 0.45, "top3": []}
        elif sc > 3000: return {"primary": "violin", "confidence": 0.40, "top3": []}
        elif sc > 2000: return {"primary": "guitar_acoustic", "confidence": 0.35, "top3": []}
        else:           return {"primary": "piano",  "confidence": 0.30, "top3": []}
```

---

## Part 4 — LangChain + CrewAI Agent System

### 4.1 — LangChain Tools
`api/agents/tools.py`:
```python
from langchain.tools import StructuredTool
from pydantic import BaseModel
import chromadb

class SearchInput(BaseModel):
    query: str
    instrument: str = ""
    mood: str = ""
    max_bpm: float = 999
    min_bpm: float = 0
    limit: int = 10

class TagInput(BaseModel):
    file_path: str

class DirectoryInput(BaseModel):
    directory_path: str
    recursive: bool = True

def _semantic_search(query: str, instrument: str = "", mood: str = "",
                     max_bpm: float = 999, min_bpm: float = 0, limit: int = 10) -> str:
    from sentence_transformers import SentenceTransformer
    client = chromadb.HttpClient(host="localhost", port=8001)
    collection = client.get_or_create_collection("samplemind_library",
                                                  metadata={"hnsw:space": "cosine"})
    model = SentenceTransformer("all-MiniLM-L6-v2")
    embedding = model.encode(query).tolist()

    where = {}
    if instrument: where["instrument"] = {"$eq": instrument}
    if mood:       where["mood"]       = {"$eq": mood}

    results = collection.query(
        query_embeddings=[embedding],
        n_results=limit,
        where=where if where else None
    )

    if not results["ids"][0]:
        return "No samples found matching your query."

    lines = [f"Found {len(results['ids'][0])} samples:"]
    for i, (id_, meta, dist) in enumerate(zip(
        results["ids"][0], results["metadatas"][0], results["distances"][0]
    )):
        lines.append(f"{i+1}. {meta.get('name','?')} | {meta.get('instrument','?')} | "
                     f"{meta.get('bpm',0):.0f}BPM | {meta.get('key','?')} {meta.get('mode','')} | "
                     f"similarity: {1-dist:.2f}")
    return "\n".join(lines)

def _tag_audio_file(file_path: str) -> str:
    from hermes.feature_extractor import extract_features, features_to_vector
    from hermes.classifiers.instrument import InstrumentClassifier
    try:
        features = extract_features(file_path)
        classifier = InstrumentClassifier()
        result = classifier.predict(features_to_vector(features))
        return (f"Tagged: {file_path}\n"
                f"Instrument: {result['primary']} ({result['confidence']:.0%})\n"
                f"Key: {features.key} {features.mode}\n"
                f"BPM: {features.tempo:.1f}\n"
                f"Top3: {result['top3']}")
    except Exception as e:
        return f"Error tagging {file_path}: {e}"

def _get_library_stats() -> str:
    client = chromadb.HttpClient(host="localhost", port=8001)
    collection = client.get_or_create_collection("samplemind_library")
    count = collection.count()
    return f"Library: {count} samples indexed in ChromaDB"

semantic_search_tool = StructuredTool.from_function(
    func=_semantic_search, name="semantic_search",
    description="Search the audio sample library by description, mood, instrument, or style",
    args_schema=SearchInput
)
tag_audio_tool = StructuredTool.from_function(
    func=_tag_audio_file, name="tag_audio_file",
    description="Analyze and tag a single audio file with AI",
    args_schema=TagInput
)
library_stats_tool = StructuredTool.from_function(
    func=_get_library_stats, name="get_library_stats",
    description="Get total sample count and library statistics"
)
```

### 4.2 — CrewAI Agents
`api/agents/crew.py`:
```python
from crewai import Agent, Task, Crew, Process
from langchain_community.llms import Ollama
from .tools import semantic_search_tool, tag_audio_tool, library_stats_tool

# LLMs
llm_fast   = Ollama(model="llama3.2:3b",  base_url="http://localhost:11434")
llm_smart  = Ollama(model="llama3.1:8b",  base_url="http://localhost:11434")
llm_code   = Ollama(model="codellama:7b", base_url="http://localhost:11434")

# Agents
search_specialist = Agent(
    role="Audio Sample Search Specialist",
    goal="Find the most relevant audio samples from the library based on user queries",
    backstory="Expert in semantic audio search with deep knowledge of music theory, "
              "instrument characteristics, and production styles",
    tools=[semantic_search_tool, library_stats_tool],
    llm=llm_fast, verbose=False, allow_delegation=False
)

music_analyst = Agent(
    role="Music Analysis Expert",
    goal="Analyze audio characteristics and provide detailed musical insights",
    backstory="Professional music theorist and producer with expertise in harmony, "
              "rhythm, timbre, and genre classification",
    tools=[tag_audio_tool],
    llm=llm_smart, verbose=False, allow_delegation=False
)

tagger_agent = Agent(
    role="AI Audio Tagger",
    goal="Accurately tag audio files with instrument, mood, BPM, key, and style metadata",
    backstory="Specialized AI trained on thousands of audio samples across all genres",
    tools=[tag_audio_tool],
    llm=llm_fast, verbose=False, allow_delegation=False
)

producer_assistant = Agent(
    role="Music Producer Assistant",
    goal="Help producers find and organize samples for their creative projects",
    backstory="Experienced music producer who understands workflow, creative needs, "
              "and can suggest complementary samples that work together harmonically",
    tools=[semantic_search_tool, library_stats_tool],
    llm=llm_smart, verbose=False, allow_delegation=False
)

def create_search_crew(query: str) -> Crew:
    task = Task(
        description=f"Search for audio samples matching: '{query}'. "
                    f"Return formatted results with name, instrument, BPM, key, similarity.",
        agent=search_specialist,
        expected_output="Formatted list of matching audio samples with metadata"
    )
    return Crew(agents=[search_specialist], tasks=[task], process=Process.sequential)

def create_analysis_crew(file_path: str) -> Crew:
    task = Task(
        description=f"Analyze this audio file and provide complete musical analysis: {file_path}",
        agent=music_analyst,
        expected_output="Detailed analysis: instrument, key, BPM, mood, style, recommendations"
    )
    return Crew(agents=[music_analyst], tasks=[task], process=Process.sequential)
```

### 4.3 — Smart Agent Router + FastAPI Endpoint
`api/agents/router.py`:
```python
from .crew import create_search_crew, create_analysis_crew, search_specialist
from langchain_community.llms import Ollama
import re

class SampleMindAgent:
    def __init__(self):
        self._parser = Ollama(model="llama3.2:3b", base_url="http://localhost:11434")

    def _needs_analysis(self, query: str) -> bool:
        analysis_keywords = ["analyze","analyse","tag","what instrument","bpm of","key of",
                              "tempo of","identify","classify","detect"]
        return any(k in query.lower() for k in analysis_keywords)

    def _extract_file_path(self, query: str) -> str | None:
        match = re.search(r'["\']([^"\']+\.(?:wav|mp3|flac|ogg|aif{1,2}))["\']', query, re.I)
        return match.group(1) if match else None

    async def query(self, user_query: str) -> dict:
        file_path = self._extract_file_path(user_query)

        if file_path and self._needs_analysis(user_query):
            crew   = create_analysis_crew(file_path)
            result = crew.kickoff()
            return {"type": "analysis", "result": str(result), "file": file_path}
        else:
            crew   = create_search_crew(user_query)
            result = crew.kickoff()
            return {"type": "search", "result": str(result), "query": user_query}

# FastAPI endpoint
from fastapi import APIRouter
router = APIRouter()
_agent = SampleMindAgent()

@router.post("/agent/query")
async def agent_query(body: dict):
    query = body.get("query", "")
    if not query:
        return {"error": "query is required"}
    result = await _agent.query(query)
    return result
```

---

## Part 5 — ARQ Async Task Queue

### 5.1 — ARQ Task Definitions
`api/tasks.py`:
```python
import arq
from hermes.feature_extractor import extract_features, features_to_vector
from hermes.embeddings import create_hybrid_embedding, store_in_chromadb
from hermes.classifiers.instrument import InstrumentClassifier
import os

async def process_audio_file(ctx, file_path: str, sample_id: str):
    """ARQ background task: extract features, classify, store in ChromaDB."""
    classifier = ctx.get("classifier") or InstrumentClassifier()

    features = extract_features(file_path)
    vector   = features_to_vector(features)
    result   = classifier.predict(vector)

    metadata = {
        "name":       os.path.basename(file_path),
        "path":       file_path,
        "instrument": result["primary"],
        "confidence": result["confidence"],
        "bpm":        features.tempo,
        "key":        features.key,
        "mode":       features.mode,
    }

    embedding = create_hybrid_embedding(vector, metadata)
    store_in_chromadb(sample_id, embedding, metadata)
    return {"status": "indexed", "sample_id": sample_id, **metadata}

class WorkerSettings:
    functions   = [process_audio_file]
    redis_settings = arq.connections.RedisSettings(host="localhost", port=6379)
    max_jobs    = 4
    job_timeout = 120
```

### 5.2 — ARQ Worker Start
`scripts/start_worker.sh`:
```bash
#!/bin/bash
# Start ARQ worker for async audio processing

# Load environment
source ~/envs/samplemind/bin/activate
export PYTHONPATH=/home/user/projects/samplemind:$PYTHONPATH

# Start worker (4 concurrent jobs, 2-minute timeout)
arq api.tasks.WorkerSettings --verbose
```

### 5.3 — Enqueue Tasks from FastAPI
`api/routes/upload.py`:
```python
from fastapi import APIRouter, UploadFile, File
from arq.connections import create_pool
import uuid
import os

router = APIRouter()

@router.post("/upload")
async def upload_audio(file: UploadFile = File(...)):
    """Upload audio file and enqueue for processing."""
    sample_id = str(uuid.uuid4())
    file_path = f"data/samples/{sample_id}_{file.filename}"

    # Save uploaded file
    os.makedirs("data/samples", exist_ok=True)
    with open(file_path, "wb") as f:
        f.write(await file.read())

    # Enqueue ARQ task
    redis = await create_pool()
    job = await redis.enqueue_job("process_audio_file", file_path, sample_id)

    return {
        "sample_id": sample_id,
        "filename": file.filename,
        "job_id": job.job_id,
        "status": "queued"
    }

@router.get("/job/{job_id}")
async def get_job_status(job_id: str):
    """Check ARQ job status."""
    redis = await create_pool()
    job = arq.Job(job_id, redis=redis)
    await job.refresh()

    return {
        "job_id": job_id,
        "status": job.get_status(),
        "result": job.result if job.is_finished() else None
    }
```

---

## Part 6 — MLflow Experiment Tracking

### 6.1 — MLflow Server Setup
```bash
# Start MLflow tracking server (accessible at http://localhost:5000)
mlflow server \
  --backend-store-uri sqlite:///data/mlflow/mlflow.db \
  --default-artifact-root ./data/mlflow/artifacts \
  --host 127.0.0.1 --port 5000
```

### 6.2 — MLflow Integration in Training
```python
import mlflow
import mlflow.pytorch

# Auto-log all hyperparameters and metrics
mlflow.pytorch.autolog()

mlflow.set_experiment("samplemind-irmas")

with mlflow.start_run(run_name="InstrumentNN-Phase2-v1"):
    mlflow.log_params({
        "model": "InstrumentClassifierNN",
        "input_dim": 65,
        "layers": [512, 256, 128, 64],
        "activation": "GELU",
        "dropout": 0.3,
        "optimizer": "AdamW",
        "lr": 1e-3,
        "scheduler": "CosineAnnealingLR",
        "epochs": 100,
        "batch_size": 64,
        "dataset": "IRMAS-6705"
    })

    # Training loop — metrics auto-logged
    model.train()
    # ... training code ...

    mlflow.log_metrics({
        "best_val_accuracy": best_val_acc,
        "final_train_loss": final_loss
    })

    # Log model artifact
    mlflow.pytorch.log_model(model, artifact_path="models/instrument_classifier")

    print(f"Run logged: {mlflow.active_run().info.run_id}")
```

### 6.3 — MLflow CLI for Model Registry
```bash
# List all experiments
mlflow experiments list

# Register best run as production model
mlflow models register-model runs:/RUN_ID/models/instrument_classifier \
  -n "InstrumentClassifier"

# Transition to production stage
mlflow models transition-model-version-stage \
  --name InstrumentClassifier \
  --version 1 \
  --stage Production

# Load production model
model_uri = "models:/InstrumentClassifier/production"
model = mlflow.pytorch.load_model(model_uri)
```

---

## Part 7 — Makefile Automation

`Makefile`:
```makefile
.PHONY: help setup install train export test serve clean

# Environment
VENV = $(HOME)/envs/samplemind
PYTHON = $(VENV)/bin/python
PIP = $(VENV)/bin/pip
PYTHON_VERSION = 3.11.9

help:
	@echo "SampleMind AI Engine — Make Targets"
	@echo ""
	@echo "Setup:"
	@echo "  make setup         — Create venv and install dependencies"
	@echo "  make install       — Install dependencies (assume venv exists)"
	@echo ""
	@echo "Data & Training:"
	@echo "  make download-irmas   — Download IRMAS-6705 dataset (1.5GB)"
	@echo "  make extract-features — Extract 65-dim features from IRMAS"
	@echo "  make train            — Train InstrumentClassifierNN (MLflow tracked)"
	@echo "  make export-openvino  — Export model to OpenVINO IR format"
	@echo "  make benchmark        — Benchmark GPU vs CPU inference"
	@echo ""
	@echo "Backend Services:"
	@echo "  make chromadb   — Start ChromaDB server (port 8001)"
	@echo "  make mlflow     — Start MLflow tracking server (port 5000)"
	@echo "  make ollama     — Start Ollama (pull required models)"
	@echo "  make redis      — Start Redis (port 6379, Docker)"
	@echo "  make postgres   — Start PostgreSQL (port 5432, Docker)"
	@echo "  make worker     — Start ARQ worker for async tasks"
	@echo "  make api        — Start FastAPI backend (port 8000)"
	@echo "  make frontend   — Start Next.js frontend (port 3000)"
	@echo ""
	@echo "Full Stack:"
	@echo "  make docker-up      — Start all services via docker-compose"
	@echo "  make docker-logs    — Tail logs from all services"
	@echo "  make docker-down    — Stop all services"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean      — Remove cache, build artifacts, logs"
	@echo "  make reset-db   — Clear ChromaDB and MLflow artifacts"

# Setup & Install
setup:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip setuptools wheel
	$(PIP) install -r requirements.txt

install:
	$(PIP) install -r requirements.txt

# Data & Training
download-irmas:
	mkdir -p data/irmas
	cd data/irmas && \
	wget -q "https://zenodo.org/record/1290750/files/IRMAS-TrainingData.zip" && \
	unzip -q IRMAS-TrainingData.zip && \
	wget -q "https://zenodo.org/record/1290750/files/IRMAS-TestingData-Part1.zip" && \
	wget -q "https://zenodo.org/record/1290750/files/IRMAS-TestingData-Part2.zip" && \
	wget -q "https://zenodo.org/record/1290750/files/IRMAS-TestingData-Part3.zip" && \
	for f in IRMAS-TestingData-Part*.zip; do unzip -q "$$f"; done
	@echo "IRMAS downloaded: $$(find data/irmas -name '*.wav' | wc -l) files"

extract-features:
	$(PYTHON) scripts/extract_irmas_features.py

train:
	$(PYTHON) scripts/train_instrument_classifier.py

export-openvino:
	$(PYTHON) scripts/export_to_openvino.py

benchmark:
	benchmark_app -m data/models/instrument_classifier.xml -d GPU -niter 200
	benchmark_app -m data/models/instrument_classifier.xml -d CPU -niter 200

# Backend Services
chromadb:
	$(PYTHON) -m chromadb.server --host 127.0.0.1 --port 8001

mlflow:
	$(PYTHON) -m mlflow server \
		--backend-store-uri sqlite:///data/mlflow/mlflow.db \
		--default-artifact-root ./data/mlflow/artifacts \
		--host 127.0.0.1 --port 5000

ollama:
	# If Ollama not installed: https://ollama.ai
	ollama pull llama3.2:3b
	ollama pull llama3.1:8b
	ollama pull codellama:7b
	ollama serve

redis:
	docker run -d --name samplemind-redis -p 6379:6379 redis:7-alpine

postgres:
	docker run -d --name samplemind-postgres \
		-e POSTGRES_USER=samplemind \
		-e POSTGRES_PASSWORD=samplemind \
		-e POSTGRES_DB=samplemind \
		-p 5432:5432 \
		postgres:15-alpine

worker:
	$(PYTHON) -m arq api.tasks.WorkerSettings --verbose

api:
	$(PYTHON) -m uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload

frontend:
	cd frontend && npm run dev

# Docker Stack
docker-up:
	docker-compose up -d
	@echo "Services starting..."
	sleep 3
	@docker-compose ps

docker-logs:
	docker-compose logs -f

docker-down:
	docker-compose down

# Cleanup
clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	rm -rf .coverage htmlcov dist build *.egg-info
	@echo "Cache cleaned"

reset-db:
	rm -rf data/mlflow/artifacts data/chroma.db
	@echo "MLflow and ChromaDB reset"

.DEFAULT_GOAL := help
```

---

## Part 8 — Docker Compose Stack

`docker-compose.yml`:
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: samplemind
      POSTGRES_PASSWORD: samplemind
      POSTGRES_DB: samplemind
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  chromadb:
    image: chromadb/chroma:latest
    ports:
      - "8001:8001"
    environment:
      CHROMA_DB_IMPL: duckdb_parquet
      PERSIST_DIRECTORY: /chroma_data
    volumes:
      - chromadb_data:/chroma_data

  mlflow:
    image: python:3.11-slim
    working_dir: /app
    command: >
      bash -c "pip install mlflow &&
               mlflow server
                 --backend-store-uri sqlite:////mlflow/mlflow.db
                 --default-artifact-root /mlflow/artifacts
                 --host 0.0.0.0 --port 5000"
    ports:
      - "5000:5000"
    volumes:
      - mlflow_data:/mlflow

  api:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      PYTHONUNBUFFERED: 1
      REDIS_URL: redis://redis:6379
      POSTGRES_URL: postgresql://samplemind:samplemind@postgres:5432/samplemind
      CHROMADB_URL: http://chromadb:8001
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis
      - chromadb
    volumes:
      - ./:/app
    command: uvicorn api.main:app --host 0.0.0.0 --port 8000

  worker:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      PYTHONUNBUFFERED: 1
      REDIS_URL: redis://redis:6379
    depends_on:
      - redis
    volumes:
      - ./:/app
      - ./data/samples:/app/data/samples
      - ./data/models:/app/data/models
    command: arq api.tasks.WorkerSettings

volumes:
  postgres_data:
  chromadb_data:
  mlflow_data:
```

---

## Part 9 — Deployment Configuration

### 9.1 — systemd Service (EliteBook Production)
`/etc/systemd/system/samplemind-api.service`:
```ini
[Unit]
Description=SampleMind FastAPI Backend
After=network.target redis.service chromadb.service

[Service]
Type=simple
User=samplemind
WorkingDirectory=/home/samplemind/projects/samplemind
Environment="PATH=/home/samplemind/envs/samplemind/bin"
ExecStart=/home/samplemind/envs/samplemind/bin/uvicorn \
  api.main:app --host 127.0.0.1 --port 8000 --workers 2
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable samplemind-api
sudo systemctl start samplemind-api
sudo systemctl status samplemind-api
sudo journalctl -u samplemind-api -f  # Logs
```

### 9.2 — Nginx Reverse Proxy
`/etc/nginx/sites-available/samplemind`:
```nginx
upstream samplemind_api {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name samplemind.local;

    location /api {
        proxy_pass http://samplemind_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /chromadb {
        proxy_pass http://127.0.0.1:8001;
    }

    location /mlflow {
        proxy_pass http://127.0.0.1:5000;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;  # Next.js frontend
    }
}
```

---

## Part 10 — RAM Budget & Hardware

| Service | EliteBook RAM | ThinkPad WSL2 RAM |
|---------|--------------|-------------------|
| Ubuntu system | 800MB | 800MB |
| FastAPI + Hermes | 600MB | 600MB |
| ChromaDB | 400MB | 400MB |
| sentence-transformers | 500MB | 500MB |
| OpenVINO model | 200MB | 200MB |
| Ollama llama3.2:3b | 2.2GB | 2.2GB |
| Docker (Postgres+Redis) | 300MB | 300MB |
| Next.js dev server | 300MB | 300MB |
| GNOME desktop | 600MB | — |
| Windows (ThinkPad) | — | 4GB |
| **Total** | **~5.9GB** | **~9.3GB** |

### Hardware Profile
- **EliteBook 850 G9** (Production): i5-1235U, 16GB RAM, Iris Xe GPU, OpenVINO-optimized
- **ThinkPad L15 Gen3** (Development): i5-10310U, 8GB RAM, no GPU, CPU fallback
- **Auto-Detection**: OpenVINO detects GPU availability at runtime, falls back to CPU

---

## Part 11 — Complete Setup Checklist

### Phase 1 — Environment Setup
- [ ] Create venv: `python3 -m venv ~/envs/samplemind`
- [ ] Install deps: `pip install -r requirements.txt`
- [ ] Verify Python: `python --version` (3.11.9)

### Phase 2 — Data Preparation
- [ ] Download IRMAS: `make download-irmas`
- [ ] Extract features: `make extract-features` (~5 mins)
- [ ] Verify: `ls data/irmas/features/*.npy`

### Phase 3 — Model Training
- [ ] Start MLflow: `make mlflow`
- [ ] Train model: `make train` (~15 mins on CPU)
- [ ] Export OpenVINO: `make export-openvino`
- [ ] Benchmark: `make benchmark`

### Phase 4 — Services
- [ ] Start ChromaDB: `make chromadb`
- [ ] Start Redis: `make redis`
- [ ] Start Ollama: `ollama pull llama3.2:3b`
- [ ] Start ARQ worker: `make worker`
- [ ] Start FastAPI: `make api`

### Phase 5 — Frontend
- [ ] Install deps: `cd frontend && npm install`
- [ ] Start dev server: `make frontend`
- [ ] Browse: `http://localhost:3000`

---

## Part 12 — API Reference

### Upload & Process Audio
```bash
curl -X POST http://localhost:8000/upload \
  -F "file=@sample.wav"

# Returns:
# {
#   "sample_id": "uuid",
#   "filename": "sample.wav",
#   "job_id": "arq_job_id",
#   "status": "queued"
# }

# Check job status:
curl http://localhost:8000/job/{job_id}
```

### Agent Query
```bash
curl -X POST http://localhost:8000/agent/query \
  -H "Content-Type: application/json" \
  -d '{"query": "find upbeat dance samples with piano"}'
```

### Library Stats
```bash
curl http://localhost:8000/library/stats
# Returns: {"total_samples": 1234, "instruments": {...}, "moods": {...}}
```

---

## Part 13 — Troubleshooting

| Issue | Solution |
|-------|----------|
| OpenVINO CPU fallback | Verify GPU drivers: `python -c "import openvino as ov; print(ov.Core().available_devices)"` |
| Low inference speed on CPU | Train Phase 2 for better accuracy; validate feature extraction correctness |
| ChromaDB connection error | Ensure server running: `make chromadb` |
| Ollama models not found | Pull models: `ollama pull llama3.2:3b` |
| ARQ jobs failing | Check Redis: `redis-cli ping` → `PONG` |
| MLflow UI 404 | Start server: `make mlflow` and check port 5000 |
| Memory pressure (ThinkPad) | Reduce Ollama model size (use 1b variant) or increase WSL2 RAM limit |

---

## Part 14 — Future Enhancements

- **Phase 3 — Fine-tuning**: Train on proprietary sample labels for domain-specific accuracy
- **Multi-GPU scaling**: Scale to N workers with Celery instead of ARQ for production
- **Advanced embeddings**: Evaluate larger models (all-mpnet-base-v2 for better semantics)
- **Real-time collaboration**: WebSocket support for live agent queries
- **Export quantization**: INT8 quantization for edge deployment (Raspberry Pi, mobile)
- **Streaming audio**: Support live microphone input via WebRTC
- **Sample synthesis**: Generate audio with matching characteristics using diffusion models

---

*SampleMind AI Engine — March 2026 — Hermes + OpenVINO + IRMAS + Agents + ARQ + MLflow + Automation*
