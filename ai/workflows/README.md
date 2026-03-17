# ai/workflows/ — Agentic Workflow Patterns

Multi-step AI workflows and automation patterns using local Ollama models
on the OnePlus 7 Pro development environment.

---

## Overview

Workflows chain multiple AI agents or Ollama calls to accomplish complex tasks
that require more than a single model interaction.

```
User request
    ↓
Agent orchestrator (shell / Python)
    ↓
Step 1: ai-explain (understand)  →  Step 2: ai-review (analyze)  →  Step 3: ai-fix (patch)
    ↓
Result output / file modification
```

---

## Workflow: Code Review Pipeline

Full automated code review workflow — understand, review, and optionally fix.

```bash
#!/bin/bash
# workflow-code-review.sh — Full review pipeline for a file
FILE="${1:-}"
[ -z "$FILE" ] && { echo "Usage: $0 <file>"; exit 1; }

echo "=== Step 1: Understand ==="
bash ~/ai/agents/ai-explain.sh "$FILE"

echo ""
echo "=== Step 2: Review ==="
bash ~/ai/agents/ai-review.sh "$FILE"

echo ""
read -rp "Apply AI fixes? (y/N): " APPLY
[ "$APPLY" = "y" ] && bash ~/ai/agents/ai-fix.sh "$FILE" --apply
```

---

## Workflow: Git Commit Flow

Automated staged diff review + commit message generation.

```bash
#!/bin/bash
# workflow-smart-commit.sh — Review diff, then commit with AI message

# 1. Show what will be committed
git diff --cached --stat

# 2. Review the diff with AI
git diff --cached | bash ~/ai/agents/ai-review.sh

# 3. Generate commit message and commit
bash ~/ai/agents/ai-commit.sh --staged
```

---

## Workflow: RAG (Retrieval-Augmented Generation)

Local document Q&A pipeline using ChromaDB embeddings + Ollama.

### Requirements
```bash
pip3 install chromadb langchain langchain-community
ollama pull nomic-embed-text    # embedding model
```

### Minimal Python RAG
```python
#!/usr/bin/env python3
"""Simple RAG pipeline: embed docs → query with local LLM."""
import os
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import OllamaEmbeddings
from langchain_community.llms import Ollama
from langchain.chains import RetrievalQA
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import DirectoryLoader, TextLoader

DOCS_DIR = os.path.expanduser("~/docs")
EMBED_MODEL = "nomic-embed-text"
LLM_MODEL = "qwen2.5-coder:7b"

# Load and chunk documents
loader = DirectoryLoader(DOCS_DIR, glob="**/*.md", loader_cls=TextLoader)
docs = loader.load()
splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
chunks = splitter.split_documents(docs)
print(f"Loaded {len(docs)} documents → {len(chunks)} chunks")

# Embed and store
embeddings = OllamaEmbeddings(model=EMBED_MODEL)
vectorstore = Chroma.from_documents(chunks, embeddings, persist_directory="/tmp/chroma_db")

# Query
llm = Ollama(model=LLM_MODEL)
qa = RetrievalQA.from_chain_type(llm=llm, retriever=vectorstore.as_retriever(search_kwargs={"k": 4}))

while True:
    query = input("\nQuestion (q to quit): ").strip()
    if query.lower() == "q":
        break
    answer = qa.invoke(query)
    print(f"\n{answer['result']}")
```

```bash
python3 ~/ai/workflows/rag-docs.py
```

---

## Workflow: Multi-Model Consensus

Get multiple models to review the same code and synthesize results.

```bash
#!/bin/bash
# workflow-consensus.sh — Multi-model code review
FILE="${1:-}"
[ -z "$FILE" ] && { echo "Usage: $0 <file>"; exit 1; }

CODE=$(cat "$FILE")

echo "=== qwen2.5-coder:7b review ==="
echo "Review this code: $CODE" | ollama run qwen2.5-coder:7b --nowordwrap

echo ""
echo "=== llama3.2:3b review ==="
echo "Review this code: $CODE" | ollama run llama3.2:3b --nowordwrap
```

---

## Workflow: Automated Documentation

Generate or update documentation for code.

```bash
# Generate README for a project directory
ls -la ~/projects/myapp/ | \
    cat ~/projects/myapp/main.go - | \
    ollama run qwen2.5-coder:7b --system "Generate a complete README.md for this project. Include: description, installation, usage, examples." --nowordwrap \
    > ~/projects/myapp/README.md
echo "README generated"
```

---

## Coming: LangChain Agent with Tools

A Python agent with tool use (shell execution, file R/W, web search):

```python
# Planned: ~/ai/workflows/agent-tools.py
# Uses: LangChain + Ollama + local tools
# Tools: bash, file_read, file_write, git_status, ollama_list
```

See `ai/agents/README.md` for current shell agent inventory.

---

## Performance Notes

- Each Ollama call loads/unloads model from RAM (~5s load time for 7B)
- Pipeline with 3 steps = 3× load time unless model stays warm (`OLLAMA_KEEP_ALIVE=10m`)
- For multi-step workflows: set `OLLAMA_KEEP_ALIVE=30m` before starting
- smollm2:135m is fast enough for routing/classification steps

---

*Device: GM1913 EU | SoC: SM8150 | RAM: 12GB | Last updated: 2026-03-17*
