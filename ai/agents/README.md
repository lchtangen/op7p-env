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
| `ai-commit.sh` | `ai-commit` | `qwen2.5-coder:7b` | AI-powered git commit message generator |
| `ai-fix.sh` | `ai-fix` | `qwen2.5-coder:7b` | Analyze file and output unified diff of fixes |

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

### ai-commit.sh — Git Commit Messages

```bash
ai-commit                          # generate message for staged changes
ai-commit --all                    # stage all + generate message
ai-commit --amend                  # suggest improved message for last commit
ai-commit --push                   # generate, commit, and push
```

### ai-fix.sh — Code Fixer

```bash
ai-fix src/main.go                 # show diff of AI-suggested fixes
ai-fix src/main.go --apply         # apply fixes directly to the file
cat buggy.py | ai-fix              # (not yet supported — use file path)
```

---

## Using System Prompts

All agents support custom system prompts from `~/ai/prompts/`:

```bash
# Use a specialized prompt
review --system "$(cat ~/ai/prompts/code-reviewer.md)" src/main.go

# Or with ai-chat:
ai-chat --system "$(cat ~/ai/prompts/android-kernel.md)"
ai-chat --system "$(cat ~/ai/prompts/go-developer.md)"
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
alias ai-name='bash $AI_HOME/agents/ai-NAME.sh'
```

---

## Workflow Combinations

See `~/ai/workflows/README.md` for multi-step pipeline patterns that chain these agents.

