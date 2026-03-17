# ai/models/ — Ollama Model Reference

Performance benchmarks, size constraints, and selection guidance
for running LLMs locally on the OnePlus 7 Pro (SM8150, 12GB RAM, CPU-only).

---

## RAM Budget

```
Total RAM:          12 GB LPDDR4X
OS + services:      ~3.5 GB  (Ubuntu, Docker idle, Redis, zsh, tmux)
Ollama overhead:    ~0.5 GB
Available for model: ~8 GB   (practical ceiling: 7 GB to leave headroom)
```

---

## Installed Models

| Model | Size | Params | Quant | Context | Speed (est.) | Best For |
|-------|------|--------|-------|---------|-------------|---------|
| `qwen2.5-coder:7b` | 4.7 GB | 7B | Q4_K_M | 32k | 5–8 t/s | Code gen, review, debug — **primary** |
| `llama3.2:3b` | 2.0 GB | 3B | Q4_K_M | 128k | 12–18 t/s | Chat, Q&A, reasoning |
| `smollm2:135m` | 270 MB | 135M | Q8_0 | 2048 | 40–60 t/s | Fast completions, testing |

---

## Recommended Additional Models (within 8 GB budget)

| Model | Size | Notes | Pull Command |
|-------|------|-------|-------------|
| `llama3.1:8b` | 4.7 GB | Meta Llama 3.1 8B — better reasoning than 3.2:3b | `ollama pull llama3.1:8b` |
| `mistral:7b` | 4.1 GB | Fast, excellent JSON structured output | `ollama pull mistral:7b` |
| `codellama:7b` | 3.8 GB | Meta code-focused model | `ollama pull codellama:7b` |
| `gemma3:4b` | 3.3 GB | Google Gemma3 4B — efficient, multilingual | `ollama pull gemma3:4b` |
| `phi4-mini:3.8b` | 2.5 GB | Microsoft Phi-4-mini — strong reasoning | `ollama pull phi4-mini:3.8b` |
| `nomic-embed-text` | 274 MB | Embeddings for RAG pipelines | `ollama pull nomic-embed-text` |
| `mxbai-embed-large` | 669 MB | Better quality embeddings | `ollama pull mxbai-embed-large` |

**Recommended additions for this device:**
```bash
ollama pull llama3.1:8b        # Better general reasoning
ollama pull nomic-embed-text   # Enable RAG/vector search pipelines
```

---

## Speed Reference (SM8150, CPU cores 4–7)

| Model Size | Expected Speed | Notes |
|------------|---------------|-------|
| ~135M      | 40–60 t/s | Instant responses |
| ~1–3B      | 15–25 t/s | Fast for chat |
| ~7–8B      | 5–10 t/s | Primary code/reasoning use |
| ~12–14B    | 2–4 t/s | Slow, high memory pressure |

---

## Custom Modelfiles

Create custom model configurations with Ollama Modelfiles:

```bash
mkdir -p ~/ai/models/modelfiles
cat > ~/ai/models/modelfiles/op7p-coder.Modelfile << 'EOF'
FROM qwen2.5-coder:7b

SYSTEM """
You are an expert developer working on the OnePlus 7 Pro (GM1913) development environment.
Context: Ubuntu 24.04.4 LTS ARM64 chroot on Android kernel 4.14.180-perf+.
Constraints: No sudo in chroot. ARM64 only. Docker uses VFS.
Always provide ARM64-compatible commands. Note when root is required.
"""

PARAMETER temperature 0.3
PARAMETER num_ctx 4096
PARAMETER num_predict 2048
EOF

# Build and use:
ollama create op7p-coder -f ~/ai/models/modelfiles/op7p-coder.Modelfile
ollama run op7p-coder
```

---

## Benchmarking

```bash
# Quick benchmark via ollama-config.sh
bash ~/dev/scripts/linux/ollama-config.sh --bench

# Manual timing
time echo "Write a Go HTTP server" | ollama run qwen2.5-coder:7b --nowordwrap

# Compare models
for model in smollm2:135m llama3.2:3b qwen2.5-coder:7b; do
    echo "=== $model ==="
    time echo "Hello, world!" | ollama run "$model" --nowordwrap 2>/dev/null
done
```

---

## Memory Monitoring During Inference

```bash
# Watch memory while model is loaded
watch -n1 'free -h && echo "" && ollama ps'

# Check after inference
free -h && ollama ps
```

---

## Model Management

```bash
ollama list                    # list installed models
ollama ps                      # show loaded model + memory usage
ollama rm <model>              # remove a model
ollama show <model>            # show model metadata + Modelfile
ollama cp <src> <dst>          # duplicate/rename a model

# Pre-warm a model (load without prompt):
echo "" | ollama run qwen2.5-coder:7b --nowordwrap &
```

---

*Device: GM1913 EU | SoC: SM8150 | RAM: 12GB | Last updated: 2026-03-17*
