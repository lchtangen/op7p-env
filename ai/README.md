# ai/ — Artificial Intelligence Environment

Local AI inference via Ollama on SM8150 (Snapdragon 855, aarch64).
CPU-only — no discrete GPU compute. Runs on MID + PRIME cores (4–7, 2.4–2.84 GHz).

---

## Directory Structure

```
ai/
├── README.md           This file — Ollama setup, models, agent usage
├── agents/             CLI shell agents wrapping Ollama
│   ├── README.md       Agent index, usage examples, model routing
│   ├── ai-chat.sh      Interactive model selector and chat launcher
│   ├── ai-review.sh    Code review: bugs, security, performance, style
│   └── ai-explain.sh   Explain code, terminal output, or concepts
├── models/             Model configs, size/speed reference, benchmark results
└── prompts/            Reusable system prompt library (markdown)
```

---

## Ollama Runtime

| Setting | Value | Config |
|---------|-------|--------|
| API host | `127.0.0.1:11434` | `~/.config/ollama/env` |
| CPU affinity | Cores 4–7 (MID + PRIME) | `~/.config/ollama/env` |
| Parallel requests | 1 | `OLLAMA_NUM_PARALLEL=1` |
| Max loaded models | 1 | `OLLAMA_MAX_LOADED_MODELS=1` |
| Model keep-alive | 10 minutes | `OLLAMA_KEEP_ALIVE=10m` |

```bash
ollama list                        # show installed models + sizes
ollama serve                       # start server (auto-started on login)
ollama run qwen2.5-coder:7b        # interactive session
ollama pull llama3.1:8b            # download additional model
ollama ps                          # show loaded model
```

---

## Installed Models

| Model | Size | Context | Speed (SM8150) | Best For |
|-------|------|---------|---------------|---------|
| `qwen2.5-coder:7b` | 4.7 GB | 4096 tok | ~5–8 t/s | Code gen, review, debug — **primary** |
| `llama3.2:3b` | 2.0 GB | 4096 tok | ~12–18 t/s | Chat, reasoning, general Q&A |
| `smollm2:135m` | 270 MB | 2048 tok | ~40–60 t/s | Fast completions, testing, low-memory |

**RAM budget:** ~7 GB available (12 GB total − ~5 GB for OS + services)
Only 1 model loaded at a time (`OLLAMA_MAX_LOADED_MODELS=1`).

---

## Agents

```bash
ai-chat                            # default: qwen2.5-coder:7b interactive chat
ai-chat fast                       # smollm2:135m (instant, low RAM)
ai-chat chat                       # llama3.2:3b (general purpose)
ai-chat --model llama3.2:3b        # explicit model selection

review src/main.go                 # AI code review of a file
cat error.log | review             # pipe code/output into reviewer
explain src/parser.py              # explain a file's logic
cat stacktrace.txt | explain       # explain terminal output
explain "what is a goroutine"      # explain a concept
```

---

## Performance Benchmark

```bash
bash ~/dev/scripts/linux/ollama-config.sh --bench
```

---

## Optimization (requires root from Termux)

CPU affinity is already written to `~/.config/ollama/env`.
To apply systemd `CPUAffinity` and `Nice=-10`:
```bash
# In Termux with Magisk su:
su -c "bash /storage/emulated/0/dev/scripts/linux/ollama-config.sh --apply"
```

Full environment docs: `~/docs/android/op7p-environment.md`
