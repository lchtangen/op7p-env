# ai/prompts/ — System Prompt Library

Reusable system prompts for Ollama agents and custom modelfiles.
Store prompts as `.md` files — use with `--system` flag or in Modelfiles.

---

## Usage

```bash
# Use a prompt file with an agent
PROMPT=$(cat ~/ai/prompts/code-reviewer.md)
ollama run qwen2.5-coder:7b --system "$PROMPT"

# Or via ai-chat
ai-chat --system "$(cat ~/ai/prompts/code-reviewer.md)"
```

---

## Prompt Naming Convention

```
DOMAIN-ROLE.md         e.g. code-reviewer.md, linux-admin.md
```

---

## Suggested Prompts to Create

| File | Role |
|------|------|
| `code-reviewer.md` | Code review expert — bugs, security, style |
| `linux-admin.md` | Linux/ARM64 sysadmin assistant |
| `go-developer.md` | Go language expert |
| `rust-developer.md` | Rust systems programming expert |
| `android-kernel.md` | Android kernel / Qualcomm CAF expert |
| `devops-engineer.md` | Docker, Kubernetes, Terraform expert |
| `ai-engineer.md` | ML/AI, Ollama, LLM integration expert |
