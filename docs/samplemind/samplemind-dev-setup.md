# SampleMind AI — Complete Development Environment Setup
### Ubuntu 24.04.4 LTS · WSL2 Compatible · All Bugs Corrected

---

**Works on:** HP EliteBook 840 G9 (native Ubuntu) · ThinkPad X1 Carbon G8 (WSL2)
**Python:** 3.11.9 via pyenv · **Venv:** `~/envs/samplemind`

---

## Phase 1 — System Foundation

### 1.1 — System Update + Essential Packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  build-essential git curl wget unzip zip \
  software-properties-common apt-transport-https \
  ca-certificates gnupg lsb-release \
  libssl-dev libffi-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev \
  libncursesw5-dev xz-utils tk-dev libxml2-dev \
  libxmlsec1-dev liblzma-dev \
  ffmpeg libsndfile1-dev libportaudio2 \
  portaudio19-dev libasound2-dev \
  htop btop ncdu jq tree
```

### 1.2 — Zsh + Oh My Zsh + Powerlevel10k

```bash
sudo apt install -y zsh
chsh -s $(which zsh)

# Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

# Update ~/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z docker)/' ~/.zshrc

exec zsh   # restart shell
# p10k configure   ← interactive theme setup
```

### 1.3 — Git Configuration

```bash
git config --global user.name "$USERNAME"
git config --global user.email "$GIT_EMAIL"
git config --global core.editor "nano"
git config --global init.defaultBranch "main"
git config --global pull.rebase true
git config --global core.autocrlf input   # important for WSL2
```

---

## Phase 2 — Python via pyenv

### 2.1 — Install pyenv

```bash
curl https://pyenv.run | bash

# Add to ~/.zshrc (or ~/.bashrc if using bash)
cat >> ~/.zshrc <<'EOF'
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
source ~/.zshrc
```

### 2.2 — Install Python 3.11.9

```bash
pyenv install 3.11.9
pyenv global 3.11.9
python --version    # should output: Python 3.11.9
pip install --upgrade pip setuptools wheel
```

### 2.3 — SampleMind Virtual Environment

```bash
mkdir -p ~/envs
python -m venv ~/envs/samplemind
source ~/envs/samplemind/bin/activate
pip install --upgrade pip

# Add activation alias to ~/.zshrc
echo 'alias activate="source ~/envs/samplemind/bin/activate"' >> ~/.zshrc
echo 'alias sm="cd ~/projects/samplemind && source ~/envs/samplemind/bin/activate"' >> ~/.zshrc
```

### 2.4 — Core SampleMind Python Dependencies

```bash
source ~/envs/samplemind/bin/activate

# Audio processing
pip install \
  librosa==0.10.1 \
  soundfile==0.12.1 \
  audioread==3.0.1 \
  pydub==0.25.1 \
  numpy==1.26.4 \
  scipy==1.13.0

# Machine learning + AI
pip install \
  torch==2.3.0 \
  torchaudio==2.3.0 \
  scikit-learn==1.5.0 \
  onnx==1.16.0 \
  onnxruntime==1.18.0

# ✅ Bug 2 FIXED — sentence-transformers was missing from original guide
# Required by hermes/embeddings.py: from sentence_transformers import SentenceTransformer
pip install \
  sentence-transformers==3.0.1 \
  transformers==4.41.0

# Vector database + embeddings
pip install \
  chromadb==0.5.0 \
  openai==1.30.0

# FastAPI backend
pip install \
  fastapi==0.111.0 \
  uvicorn[standard]==0.29.0 \
  pydantic==2.7.1 \
  python-multipart==0.0.9 \
  aiofiles==23.2.1 \
  httpx==0.27.0

# Database + caching
pip install \
  sqlalchemy==2.0.30 \
  alembic==1.13.1 \
  asyncpg==0.29.0 \
  redis==5.0.4 \
  arq==0.25.0

# AI agents
pip install \
  langchain==0.2.1 \
  langchain-community==0.2.1 \
  crewai==0.30.0 \
  ollama==0.2.0

# Experiment tracking
pip install mlflow==2.13.0

# Dev tools
pip install \
  pytest==8.2.0 \
  pytest-asyncio==0.23.6 \
  black==24.4.2 \
  ruff==0.4.4 \
  pre-commit==3.7.1

# Export requirements
pip freeze > ~/projects/samplemind/requirements.txt
```

---

## Phase 3 — VS Code Setup

### 3.1 — Install VS Code

```bash
# Ubuntu native (EliteBook)
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
  sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update && sudo apt install -y code
```

### 3.2 — VS Code Extensions

```bash
# Install all extensions
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.black-formatter
code --install-extension charliermarsh.ruff
code --install-extension ms-toolsai.jupyter
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension bradlc.vscode-tailwindcss
code --install-extension dsznajder.es7-react-js-snippets
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension enkia.tokyo-night           # Tokyo Night theme
code --install-extension PKief.material-icon-theme
code --install-extension eamodio.gitlens
code --install-extension mhutchie.git-graph
code --install-extension ms-azuretools.vscode-docker
code --install-extension mongodb.mongodb-vscode
code --install-extension mtxr.sqltools
code --install-extension humao.rest-client
code --install-extension formulahendry.code-runner
```

### 3.3 — VS Code Settings

Create `~/.config/Code/User/settings.json` (or `%APPDATA%\Code\User\settings.json` on Windows for WSL2):

```json
{
  "workbench.colorTheme": "Tokyo Night",
  "workbench.iconTheme": "material-icon-theme",
  "editor.fontFamily": "'JetBrains Mono', 'Cascadia Code', Consolas, monospace",
  "editor.fontSize": 14,
  "editor.lineHeight": 1.6,
  "editor.fontLigatures": true,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.formatOnSave": true
  },
  "python.defaultInterpreterPath": "~/envs/samplemind/bin/python",
  "python.linting.enabled": true,
  "editor.tabSize": 2,
  "editor.rulers": [88, 120],
  "editor.minimap.enabled": false,
  "editor.bracketPairColorization.enabled": true,
  "terminal.integrated.fontFamily": "'JetBrains Mono'",
  "terminal.integrated.fontSize": 13,
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.venv/**": true,
    "**/__pycache__/**": true,
    "**/.git/**": true
  },
  "explorer.confirmDelete": false,
  "git.autofetch": true
}
```

---

## Phase 4 — Node.js + Frontend Tools

### 4.1 — NVM + Node.js 20 LTS

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Add to ~/.zshrc (installer does this automatically but verify)
cat >> ~/.zshrc <<'EOF'
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
source ~/.zshrc

nvm install 20
nvm use 20
nvm alias default 20
node --version  # Should output: v20.x.x

# Global npm tools
npm install -g pnpm typescript ts-node @biomejs/biome
```

---

## Phase 5 — Docker + Services Stack

### 5.1 — Install Docker

```bash
# Remove old versions
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null

# Docker official repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Run Docker without sudo
sudo usermod -aG docker $USER
newgrp docker

# Start Docker (on WSL2 with systemd=true this is automatic)
sudo systemctl enable docker
sudo systemctl start docker
```

### 5.2 — SampleMind Docker Compose Stack

Create `~/projects/samplemind/docker-compose.yml`:

```yaml
version: '3.9'

services:
  chromadb:
    image: chromadb/chroma:0.5.0
    container_name: samplemind-chromadb
    ports: ["8001:8000"]
    volumes:
      - chroma_data:/chroma/chroma
    environment:
      CHROMA_SERVER_AUTH_CREDENTIALS_PROVIDER: ""
      CHROMA_SERVER_AUTH_PROVIDER: ""
    restart: unless-stopped

  postgres:
    image: postgres:16-alpine
    container_name: samplemind-postgres
    environment:
      POSTGRES_DB: samplemind
      POSTGRES_USER: $USERNAME
      POSTGRES_PASSWORD: samplemind_dev
    ports: ["5432:5432"]
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    container_name: samplemind-redis
    ports: ["6379:6379"]
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  chroma_data:
  postgres_data:
  redis_data:
```

```bash
cd ~/projects/samplemind
docker compose up -d      # Start all services
docker compose ps         # Verify all running
docker compose logs -f    # Watch logs
```

---

## Phase 6 — Ollama + Language Models

### 6.1 — Install Ollama

```bash
curl -fsSL https://ollama.ai/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama

# Verify
ollama --version
```

### 6.2 — Pull All 4 Required Models

```bash
# Fast query parser + audio tagging (2.2GB) — primary model
ollama pull llama3.2:3b

# Better music analysis + reasoning (4.7GB) — for complex queries
ollama pull llama3.1:8b

# Code generation + debugging (3.8GB)
ollama pull codellama:7b

# Lightweight embeddings (274MB) — ChromaDB alternative to sentence-transformers
ollama pull nomic-embed-text

# Verify all pulled
ollama list
```

RAM usage when all active: ~11GB total. Run one at a time unless on 32GB system.
Typical usage: llama3.2:3b for real-time tagging, llama3.1:8b for analysis tasks.

---

## Phase 7 — OpenVINO 2024.4 + Intel GPU

### 7.1 — Install OpenVINO

```bash
source ~/envs/samplemind/bin/activate

# OpenVINO Python package (includes ovc CLI tool)
pip install openvino==2024.4.0 openvino-dev==2024.4.0

# Verify installation
python -c "import openvino as ov; print(ov.__version__)"
# Expected: 2024.4.0

# ovc CLI tool verification (replaces deprecated mo command)
ovc --help
```

### 7.2 — Intel GPU Compute Runtime (EliteBook only)

```bash
# Intel oneAPI base toolkit for Iris Xe OpenCL/Level Zero support
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
  gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] \
  https://apt.repos.intel.com/oneapi all main" | \
  sudo tee /etc/apt/sources.list.d/oneAPI.list
sudo apt update

# Intel GPU compute runtime (required for OpenVINO GPU device)
sudo apt install -y \
  intel-opencl-icd \
  intel-level-zero-gpu \
  level-zero \
  intel-media-va-driver-non-free

# Add user to render group
sudo usermod -aG render,video $USER
newgrp render

# Intel oneAPI MKL (accelerated numpy/librosa FFT)
sudo apt install -y intel-oneapi-mkl intel-oneapi-mkl-devel
source /opt/intel/oneapi/setvars.sh

# Verify GPU is available to OpenVINO
python -c "
import openvino as ov
core = ov.Core()
print('Available devices:', core.available_devices)
# Expected on EliteBook: ['CPU', 'GPU']
# Expected on ThinkPad WSL2: ['CPU']
"
```

### 7.3 — ✅ Bug 3 FIXED — Correct OpenVINO Model Conversion

The original guide used `from openvino.tools import mo` which was **removed in OpenVINO 2024.x**.

**Wrong (deprecated — causes ImportError):**

```python
# DO NOT USE — removed in 2024.x
from openvino.tools import mo
model = mo.convert_model("model.onnx")
```

**Correct Python API:**

```python
import openvino as ov

core = ov.Core()
# Convert ONNX → OpenVINO IR (FP16 for GPU efficiency)
ov_model = ov.convert_model("instrument_classifier.onnx")
ov.save_model(ov_model, "instrument_classifier.xml")

# Compile for target device
device = "GPU" if "GPU" in core.available_devices else "CPU"
compiled_model = core.compile_model("instrument_classifier.xml", device)
```

**Correct CLI (ovc — replaces mo):**

```bash
# Convert ONNX to OpenVINO IR
ovc instrument_classifier.onnx --output_model instrument_classifier.xml --compress_to_fp16

# Benchmark
benchmark_app -m instrument_classifier.xml -d GPU -niter 100
```

---

## Phase 8 — SampleMind Project Structure

### 8.1 — Project Init

```bash
mkdir -p ~/projects/samplemind
cd ~/projects/samplemind

git init
git remote add origin https://github.com/$USERNAME/samplemind.git  # if exists

# Create core structure
mkdir -p {api,hermes/{models,classifiers},frontend,tests,scripts,data/{samples,models}}
```

### 8.2 — Makefile (Dev Automation)

Create `~/projects/samplemind/Makefile`:

```makefile
.PHONY: dev backend frontend docker ollama clean test lint train-phase2

# Activate venv shortcut
VENV = source ~/envs/samplemind/bin/activate

dev: docker
	@echo "Starting SampleMind dev stack..."
	$(VENV) && uvicorn api.main:app --reload --host 0.0.0.0 --port 8000 &
	cd frontend && npm run dev &
	@echo "Backend: http://localhost:8000 | Frontend: http://localhost:3000"

backend:
	$(VENV) && uvicorn api.main:app --reload --host 0.0.0.0 --port 8000

frontend:
	cd frontend && npm run dev

docker:
	docker compose up -d
	@echo "ChromaDB: :8001 | Postgres: :5432 | Redis: :6379"

ollama:
	ollama pull llama3.2:3b
	ollama pull llama3.1:8b
	ollama pull codellama:7b
	ollama pull nomic-embed-text

train-phase2:
	$(VENV) && python scripts/extract_irmas_features.py
	$(VENV) && python scripts/train_instrument_classifier.py
	$(VENV) && python scripts/export_to_openvino.py

test:
	$(VENV) && pytest tests/ -v --tb=short

lint:
	$(VENV) && ruff check . --fix
	$(VENV) && black .

clean:
	docker compose down
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null; true
	find . -name "*.pyc" -delete 2>/dev/null; true
```

### 8.3 — Dev Aliases

```bash
cat >> ~/.zshrc <<'EOF'
# SampleMind shortcuts
alias sm="cd ~/projects/samplemind && source ~/envs/samplemind/bin/activate"
alias smdev="cd ~/projects/samplemind && make dev"
alias smtest="cd ~/projects/samplemind && make test"
alias smlogs="cd ~/projects/samplemind && docker compose logs -f"
alias ollama-list="ollama list"
alias gpu-check="glxinfo | grep renderer 2>/dev/null || echo 'No glxinfo (WSL2?)'"
EOF
source ~/.zshrc
```

### 8.4 — Pre-commit Hooks

```bash
cd ~/projects/samplemind
source ~/envs/samplemind/bin/activate

cat > .pre-commit-config.yaml <<'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: debug-statements
  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks:
      - id: black
        language_version: python3.11
  - repo: https://github.com/charliermarsh/ruff-pre-commit
    rev: v0.4.4
    hooks:
      - id: ruff
        args: ["--fix"]
EOF

pre-commit install
pre-commit run --all-files   # test run
```

---

## Phase 9 — Verification Checklist

```bash
# Run all checks
source ~/envs/samplemind/bin/activate

echo "=== Python ===" && python --version
echo "=== PyTorch ===" && python -c "import torch; print(torch.__version__)"
echo "=== Librosa ===" && python -c "import librosa; print(librosa.__version__)"
echo "=== SentenceTransformers ===" && python -c "from sentence_transformers import SentenceTransformer; print('OK')"
echo "=== ChromaDB ===" && python -c "import chromadb; print(chromadb.__version__)"
echo "=== FastAPI ===" && python -c "import fastapi; print(fastapi.__version__)"
echo "=== OpenVINO ===" && python -c "import openvino as ov; print(ov.__version__)"
echo "=== Docker ===" && docker compose ps
echo "=== Ollama ===" && ollama list
echo "=== Node.js ===" && node --version
echo "=== npm ===" && npm --version
echo "=== OpenVINO devices ===" && python -c "import openvino as ov; print(ov.Core().available_devices)"
```

All checks passing = environment ready for SampleMind development.

---

## Bug Corrections Summary

### Bug 1: CPU Type Comment (hermes/embeddings.py)
**Original error:** Comment referenced `i5-10310U` processor
**Correction:** Updated to `i5-1235U` to match actual EliteBook 840 G9 specification

### Bug 2: Missing sentence-transformers Dependency
**Original error:** `sentence-transformers==3.0.1` was not included in pip install list
**Impact:** Code using `from sentence_transformers import SentenceTransformer` would fail with ImportError
**Correction:** Added `sentence-transformers==3.0.1` to Phase 2.4 dependencies

### Bug 3: Deprecated OpenVINO mo Tool
**Original error:** Guide used `from openvino.tools import mo` which was removed in OpenVINO 2024.x
**Impact:** Model conversion code would raise ImportError
**Correction:**
- Replaced with `ovc` CLI tool for command-line conversion
- Updated Python API to use `ov.convert_model()` and `ov.save_model()` methods
- Both approaches documented in Phase 7.3

---

*SampleMind Dev Environment — Ubuntu 24.04.4 / WSL2 — March 2026*
*Bugs corrected: CPU reference fixed (Bug 1), sentence-transformers added (Bug 2), ovc CLI replaces deprecated mo (Bug 3)*
