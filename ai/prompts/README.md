# ai/prompts/ — System Prompt Library

Reusable system prompts for Ollama agents and custom modelfiles.
Each prompt is a `.md` file that can be loaded with `--system` or embedded in Modelfiles.

---

## Prompt Library

| File | Role | Best Model |
|------|------|-----------|
| `code-reviewer.md` | Code review expert — bugs, security, performance, ARM64 notes | `qwen2.5-coder:7b` |
| `linux-admin.md` | Linux/ARM64 sysadmin on Snapdragon 855 — chroot-aware | `qwen2.5-coder:7b` |
| `go-developer.md` | Go 1.26+ expert — idiomatic, ARM64 optimized, testable | `qwen2.5-coder:7b` |
| `rust-developer.md` | Rust 1.94 systems programming on aarch64 | `qwen2.5-coder:7b` |
| `android-kernel.md` | Android kernel 4.14 CAF / SM8150 / Magisk expert | `qwen2.5-coder:7b` |
| `devops-engineer.md` | Docker, k3s, Terraform, Helm on ARM64 | `llama3.2:3b` |
| `ai-engineer.md` | Local LLM, Ollama, LangChain, RAG, MCP expert | `qwen2.5-coder:7b` |

---

## Usage

```bash
# Use a prompt file with an agent
ai-chat --system "$(cat ~/ai/prompts/code-reviewer.md)"
ai-chat --system "$(cat ~/ai/prompts/go-developer.md)"
ai-chat --system "$(cat ~/ai/prompts/android-kernel.md)"

# Use with review
review --system "$(cat ~/ai/prompts/code-reviewer.md)" src/main.go

# Pipe context to chat
cat Dockerfile | ai-chat --system "$(cat ~/ai/prompts/devops-engineer.md)"
```

---

## Embed in Ollama Modelfile

```bash
# Create a custom model with a baked-in system prompt:
cat > ~/ai/models/modelfiles/go-expert.Modelfile << EOF
FROM qwen2.5-coder:7b
SYSTEM """$(cat ~/ai/prompts/go-developer.md)"""
PARAMETER temperature 0.2
PARAMETER num_ctx 8192
EOF

ollama create go-expert -f ~/ai/models/modelfiles/go-expert.Modelfile
ollama run go-expert
```

---

## Prompt Naming Convention

```
DOMAIN-ROLE.md         e.g. code-reviewer.md, linux-admin.md
```

---

## Adding New Prompts

1. Create `ai/prompts/my-domain.md`
2. Write system prompt as plain text (no markdown headers needed)
3. Start with: "You are an expert in..."
4. Include relevant context for this device/environment
5. Specify output format if needed
6. Update this README table

