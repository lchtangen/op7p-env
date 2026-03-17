# docs/samplemind/ — SampleMind AI Project

SampleMind is an AI-powered audio sample analysis and generation platform.
Runs on: HP EliteBook 840 G9 (Ubuntu, Intel OpenVINO), ThinkPad X1 (WSL2), OnePlus 7 Pro (ARM64, CPU inference).

---

## Documents

| File | Description |
|------|-------------|
| `samplemind-dev-setup.md` | Complete dev environment: Python, Node, Go, PostgreSQL, Redis |
| `samplemind-ai-engine.md` | Hermes AI + OpenVINO + IRMAS neural network + AI agents |
| `samplemind-frontend.md` | Next.js web app + Tauri desktop + PWA |
| `samplemind-openvino.md` | Intel OpenVINO optimization and ARM64 build notes |
| `samplemind-hermes.md` | Hermes AI framework architecture |

---

## Stack

```
Backend:   Python (FastAPI, LangChain, Hermes)
Frontend:  Next.js 14, Tauri desktop, PWA
AI:        Ollama (local), OpenVINO (Intel GPU acceleration)
Database:  PostgreSQL 16, Redis
Repo:      github.com/lchtangen/samplemind-ai
```

---

## Quick Start

```bash
# Clone repo (requires gh auth — run git-setup.sh first)
gh repo clone lchtangen/samplemind-ai ~/projects/samplemind-ai
cd ~/projects/samplemind-ai

# Start full stack
make dev

# Ollama models for SampleMind
ollama pull qwen2.5-coder:7b
```

---

## Execution Order (fresh machine)

```
1. OS install      → docs/linux/elitebook-dualboot.md
2. Post-install    → dev/scripts/linux/ubuntu-post-install.sh
3. Dev environment → samplemind-dev-setup.md
4. AI engine       → samplemind-ai-engine.md
5. Frontend        → samplemind-frontend.md
```
