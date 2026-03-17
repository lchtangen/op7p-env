# ai/prompts/ — System Prompt Library

Reusable system prompts for Ollama agents and custom Modelfiles.
Store prompts as `.md` files — use with `--system` flag or in Modelfiles.

---

## Usage

```bash
# Use a prompt file with an agent
PROMPT=$(cat ~/ai/prompts/code-reviewer.md)
ollama run qwen2.5-coder:7b --system "$PROMPT"

# Or via ai-chat
ai-chat --system "$(cat ~/ai/prompts/code-reviewer.md)"

# With ai-review
review src/main.go   # uses built-in code-reviewer prompt

# With any agent
bash ~/ai/agents/ai-chat.sh --system "$(cat ~/ai/prompts/linux-admin.md)"
```

---

## Prompt Naming Convention

```
DOMAIN-ROLE.md         e.g. code-reviewer.md, linux-admin.md
```

---

## Available Prompts

| File | Role |
|------|------|
| `code-reviewer.md` | Code review expert — bugs, security, style |
| `linux-admin.md` | Linux/ARM64 sysadmin + Android chroot expert |
| `go-developer.md` | Go language expert |
| `rust-developer.md` | Rust systems programming expert |
| `android-kernel.md` | Android kernel / Qualcomm CAF / SM8150 expert |
| `devops-engineer.md` | Docker, Kubernetes, Terraform, Helm expert |
| `ai-engineer.md` | ML/AI, Ollama, LangChain, LLM integration expert |
| `samplemind.md` | SampleMind project assistant |

---

## Creating a Prompt

```markdown
# code-reviewer.md
You are a senior software engineer and security-focused code reviewer.
Analyze code for: bugs, security vulnerabilities, performance issues, 
style violations, and best practices.

Output format:
## ISSUES (if any)
- <severity>: <description>

## SUGGESTIONS
- <improvement>

## QUALITY SCORE: X/10
```

---

## Modelfile Integration

Create a custom Ollama model with a system prompt:

```Dockerfile
# ~/.config/ollama/Modelfile.code-reviewer
FROM qwen2.5-coder:7b
SYSTEM """
You are a senior code reviewer. Analyze code for bugs, security, performance,
and style. Be concise and specific. Score quality 1-10.
"""
```

```bash
ollama create code-reviewer -f ~/.config/ollama/Modelfile.code-reviewer
ollama run code-reviewer
```
