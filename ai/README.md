# ai/ — Artificial Intelligence Environment

Local AI inference via Ollama on SM8150 (Snapdragon 855, aarch64).
CPU-only inference — no discrete GPU compute. Runs on MID + PRIME cores (4–7, 2.4–2.84 GHz).

---

## Directory Structure

```
ai/
├── README.md           This file — Ollama setup, models, agent usage, orchestration
├── agents/             CLI shell agents wrapping Ollama
│   ├── README.md       Agent index, usage examples, model routing
│   ├── ai-chat.sh      Interactive model selector and chat launcher
│   ├── ai-review.sh    Code review: bugs, security, performance, style
│   ├── ai-explain.sh   Explain code, terminal output, or concepts
│   ├── ai-commit.sh    AI-generated git commit messages from staged diff
│   ├── ai-debug.sh     Analyze errors, logs, and crash output
│   ├── ai-docs.sh      Generate documentation for code files
│   └── ai-refactor.sh  Code refactoring suggestions
├── datasets/           Training data, test fixtures, benchmark sets
├── models/             Model configs, size/speed reference, Modelfiles
├── notebooks/          JupyterLab notebooks for AI/ML experiments
├── prompts/            Reusable system prompt library (markdown)
└── workflows/          Multi-agent orchestration scripts
```

---

## Ollama Runtime

| Setting | Value | Config |
|---------|-------|--------|
| API host | `127.0.0.1:11434` | `~/.config/ollama/env` |
| CPU affinity | Cores 4–7 (MID + PRIME) | systemd `CPUAffinity` |
| Parallel requests | 1 | `OLLAMA_NUM_PARALLEL=1` |
| Max loaded models | 1 | `OLLAMA_MAX_LOADED_MODELS=1` |
| Model keep-alive | 10 minutes | `OLLAMA_KEEP_ALIVE=10m` |

```bash
ollama list                        # show installed models + sizes
ollama serve                       # start server (auto-started on login)
ollama run qwen2.5-coder:7b        # interactive session
ollama pull llama3.1:8b            # download additional model
ollama ps                          # show loaded model
ollama rm <model>                  # remove model
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

### Additional Recommended Models

| Model | Size | Notes |
|-------|------|-------|
| `llama3.1:8b` | 4.7 GB | Best general-purpose 8b |
| `qwen2.5:7b` | 4.7 GB | Multilingual, strong reasoning |
| `gemma3:4b` | 2.5 GB | Google Gemma 3, efficient |
| `gemma3:12b` | 8.1 GB | High quality (tight fit on 12GB) |
| `mistral:7b` | 4.1 GB | Fast instruction following |
| `phi4:14b` | 8.5 GB | Microsoft Phi-4 (tight fit) |

```bash
# View all recommendations and pull:
bash ~/dev/scripts/linux/ollama-config.sh --models
bash ~/dev/scripts/linux/ai-stack.sh --pull-essential
```

---

## Agents (Quick Reference)

```bash
ai-chat                            # interactive chat (qwen2.5-coder:7b)
ai-chat fast                       # smollm2:135m (instant)
ai-chat chat                       # llama3.2:3b (general)

review src/main.go                 # code review
cat error.log | review

explain src/parser.py              # explain code
cat stacktrace.txt | explain
explain "what is WALT scheduler"

# New agents:
ai-commit                          # generate commit message from staged diff
ai-commit --apply                  # generate + commit

cargo build 2>&1 | ai-debug       # analyze error output
journalctl -u ollama | ai-debug

ai-docs src/handler.go             # generate Markdown docs
ai-docs lib/utils.py --format docstring

ai-refactor messy.sh               # suggest improvements
cat old_code.py | ai-refactor --goal "make it async"
```

Full agent docs: `~/ai/agents/README.md`

---

## AI Stack Management

```bash
# Manage AI stack:
bash ~/dev/scripts/linux/ai-stack.sh --status      # full stack status
bash ~/dev/scripts/linux/ai-stack.sh --start       # start Ollama
bash ~/dev/scripts/linux/ai-stack.sh --stop        # stop Ollama
bash ~/dev/scripts/linux/ai-stack.sh --install     # install Python AI packages
bash ~/dev/scripts/linux/ai-stack.sh --models      # show model catalog
bash ~/dev/scripts/linux/ai-stack.sh --bench       # benchmark installed models

# Ollama configuration:
bash ~/dev/scripts/linux/ollama-config.sh --status
bash ~/dev/scripts/linux/ollama-config.sh --apply  # (requires root — via Termux)
bash ~/dev/scripts/linux/ollama-config.sh --bench
bash ~/dev/scripts/linux/ollama-config.sh --pull gemma3:4b
```

---

## Python AI Stack

```python
# LangChain + Ollama
from langchain_ollama import ChatOllama
from langchain_core.messages import HumanMessage

llm = ChatOllama(model="qwen2.5-coder:7b", base_url="http://127.0.0.1:11434")
response = llm.invoke([HumanMessage(content="Write a Python hello world")])
print(response.content)

# Direct Ollama Python client
import ollama
response = ollama.chat(model='qwen2.5-coder:7b',
    messages=[{'role': 'user', 'content': 'Write a Go hello world'}])
print(response['message']['content'])

# LiteLLM (unified API — works with Ollama + Claude + OpenAI)
import litellm
response = litellm.completion(
    model="ollama/qwen2.5-coder:7b",
    messages=[{"role": "user", "content": "Hello"}],
    api_base="http://127.0.0.1:11434"
)
```

---

## JupyterLab

```bash
jlab        # launch JupyterLab at 0.0.0.0:8888 (alias in ~/.zshrc)
jnb         # launch Jupyter Notebook
```

Connect: `http://device-ip:8888` from any device on the network.

---

## Performance & Optimization

CPU affinity is set in `~/.config/ollama/env`.
For systemd `CPUAffinity=4 5 6 7` (requires root via Termux):

```bash
# In Termux with Magisk su:
su -c "bash /storage/emulated/0/dev/scripts/linux/ollama-config.sh --apply"
```

Benchmark: `bash ~/dev/scripts/linux/ai-stack.sh --bench`

Full environment docs: `~/docs/android/op7p-environment.md`
