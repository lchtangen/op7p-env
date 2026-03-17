# ai/agents/ — Local AI Agents (Ollama)

Shell scripts wrapping Ollama for common developer workflows.
All agents use the local Ollama API at `127.0.0.1:11434` — no internet required.

---

## Agents

| Script | Shell Alias | Model Default | Purpose |
|--------|------------|--------------|---------|
| `ai-chat.sh` | `ai-chat` | `qwen2.5-coder:7b` | Interactive multi-model chat launcher |
| `ai-review.sh` | `review` | `qwen2.5-coder:7b` | Code review — bugs, security, style, score |
| `ai-explain.sh` | `explain` | `qwen2.5-coder:7b` | Explain files, output, or concepts |
| `ai-commit.sh` | `ai-commit` | `qwen2.5-coder:7b` | Generate git commit messages from diff |
| `ai-debug.sh` | `ai-debug` | `qwen2.5-coder:7b` | Analyze errors, logs, crash output |
| `ai-docs.sh` | `ai-docs` | `qwen2.5-coder:7b` | Generate documentation for code files |
| `ai-refactor.sh` | `ai-refactor` | `qwen2.5-coder:7b` | Code refactoring suggestions |

---

## Usage

### ai-chat.sh — Chat Launcher

```bash
ai-chat                            # qwen2.5-coder:7b (default)
ai-chat code                       # qwen2.5-coder:7b (code focus)
ai-chat chat                       # llama3.2:3b (general)
ai-chat fast                       # smollm2:135m (instant)
ai-chat --model llama3.1:8b        # explicit model
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

### ai-commit.sh — Git Commit Messages

```bash
git add .
ai-commit                          # generate commit message (preview)
ai-commit --apply                  # generate + commit immediately
ai-commit --amend                  # regenerate last commit message
```

### ai-debug.sh — Debug & Error Analysis

```bash
cargo build 2>&1 | ai-debug       # analyze build errors
journalctl -u ollama | ai-debug    # analyze service logs
dmesg | tail -30 | ai-debug        # analyze kernel messages
ai-debug /var/log/syslog           # analyze log file
ai-debug "permission denied: /proc/sys/kernel/sched_boost"
```

### ai-docs.sh — Documentation Generator

```bash
ai-docs src/main.py                # generate Markdown docs (default)
ai-docs api/handler.go --format md     # explicit Markdown
ai-docs lib/utils.rs --format docstring   # inline docstrings
ai-docs config/server.py --format rst     # reStructuredText
```

### ai-refactor.sh — Refactoring

```bash
ai-refactor src/handler.py                          # analyze + suggest
ai-refactor api/routes.go --goal "add error handling"
cat messy_code.sh | ai-refactor                     # pipe
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

---

## Model Selection Guide

| Model | Size | Best For |
|-------|------|----------|
| `smollm2:135m` | 270 MB | Instant completions, always-on |
| `llama3.2:3b` | 2.0 GB | General chat, quick reasoning |
| `qwen2.5-coder:7b` | 4.7 GB | Code (primary) — best quality/speed |
| `llama3.1:8b` | 4.7 GB | Best general-purpose 8b model |
| `gemma3:12b` | 8.1 GB | High-quality reasoning (tight on 12GB) |

See: `bash ~/dev/scripts/linux/ai-stack.sh --models`
