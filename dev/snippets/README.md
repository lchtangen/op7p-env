# dev/snippets/ — Code Snippets

Reusable code snippets for common tasks on this device.

---

## Naming Convention

```
LANGUAGE-description.ext     e.g. go-http-server.go, py-ollama-chat.py, sh-battery-watch.sh
```

---

## Index

*(Add snippets as needed)*

### Shell
- `sh-tmux-session.sh` — create named tmux session with split panes
- `sh-ollama-stream.sh` — stream Ollama API response via curl

### Python
- `py-ollama-chat.py` — minimal Ollama chat loop with history
- `py-chromadb-rag.py` — simple RAG with ChromaDB and Ollama

### Go
- `go-arm64-info.go` — print SM8150 CPU/memory info via procfs

---

## Quick Use

```bash
# Copy snippet to workspace:
cp ~/dev/snippets/py-ollama-chat.py ~/workspace/

# Or source directly:
source ~/dev/snippets/sh-tmux-session.sh
```
