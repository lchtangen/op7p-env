# dev/templates/ — Project Templates

Starter templates for new projects on this device.

---

## Available Templates

```
templates/
├── go-cli/             Go CLI application (cobra + slog + ARM64 Makefile)
├── go-api/             Go REST API (net/http, JSON, chi router)
├── py-fastapi/         Python FastAPI service with Ollama integration
├── py-agent/           LangChain agent with local Ollama tools
└── docker-arm64/       Multi-stage ARM64 Dockerfile templates
```

---

## Usage

```bash
# Copy template to projects:
cp -r ~/dev/templates/go-cli ~/projects/my-new-tool
cd ~/projects/my-new-tool
# Edit go.mod, cmd/main.go, then:
go mod tidy && go build ./...
```

---

## Create from Scratch with AI

```bash
# Generate a new project scaffold
explain "scaffold a Go CLI tool with cobra for ARM64 Linux that reads /proc/cpuinfo"
# Or with template:
echo "Create a FastAPI app with Ollama integration for ARM64 Ubuntu" | ai-chat code
```

*(Templates will be added as projects are built)*
