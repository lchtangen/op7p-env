# ai/agents/ — Ollama CLI Agents

Shell scripts wrapping Ollama for common developer workflows.
All agents use the local Ollama API at `127.0.0.1:11434` — no internet required.

---

## Agents

| Script | Shell Alias | Model Default | Purpose |
|--------|------------|--------------|---------|
| `ai-chat.sh` | `ai-chat` | `qwen2.5-coder:7b` | Interactive multi-model chat launcher |
| `ai-review.sh` | `review` | `qwen2.5-coder:7b` | Code review — bugs, security, style, score |
| `ai-explain.sh` | `explain` | `qwen2.5-coder:7b` | Explain files, output, or concepts |

---

## Usage

### ai-chat.sh — Chat Launcher

```bash
ai-chat                            # qwen2.5-coder:7b (default)
ai-chat code                       # qwen2.5-coder:7b (code focus)
ai-chat chat                       # llama3.2:3b (general)
ai-chat fast                       # smollm2:135m (instant)
ai-chat --model llama3.2:3b        # explicit model
ai-chat --system "Act as a Go expert"   # custom system prompt
```

### ai-review.sh — Code Review

```bash
review main.go                     # review a file
review src/api/handler.py          # with path
cat myfile.rs | review             # pipe via stdin
git diff HEAD | review             # review uncommitted changes
```

Output format: **ISSUES** (bugs, security) | **SUGGESTIONS** | **QUALITY SCORE (1–10)**

### ai-explain.sh — Explain

```bash
explain Dockerfile                 # explain a config file
explain src/scheduler.c            # explain C code
dmesg | tail -20 | explain         # explain kernel output
explain "what is WALT scheduler"   # explain a concept
```

---

## Adding New Agents

Create `ai-NAME.sh` in this directory following the pattern:

```bash
#!/bin/bash
# ai-NAME.sh — description
MODEL="qwen2.5-coder:7b"
SYSTEM="Your system prompt here."

if [ -n "$1" ] && [ -f "$1" ]; then
    echo "Your task: $(cat "$1")" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
elif [ ! -t 0 ]; then
    echo "Your task: $(cat)" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
elif [ -n "$1" ]; then
    echo "$*" | ollama run "$MODEL" --system "$SYSTEM" --nowordwrap
fi
```

Then add alias to `~/.zshrc`:
```bash
alias name='bash $AI_HOME/agents/ai-NAME.sh'
```
