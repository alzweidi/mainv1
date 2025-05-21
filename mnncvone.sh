#!/bin/bash

set -euo pipefail  # Safer bash options

### CONFIG
REPO_URL="https://github.com/zorp-corp/nockchain"
PROJECT_DIR="$HOME/nockchain"
PUBKEY="3MXohQ9ExcSQa1qttFgj15yZi3Xptwh2R99FoAgU5MxZYhFMN9bKhAPRWNmrUfXPy3WJoocvkHicCRfm7WV3BLXx7CHKJTnEPJMpdvdNF5rPRfowUBM6HB7LFgorcp6z464V"
ENV_FILE="$PROJECT_DIR/.env"
TMUX_SESSION="nock-miner"

echo ""
echo "[+] Nockchain MainNet Bootstrap Starting..."
echo "-------------------------------------------"

### 1. Install Rust Toolchain
echo "[1/7] Installing Rust toolchain..."
if ! command -v cargo &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

### 2. Install System Dependencies
echo "[2/7] Installing system dependencies..."
sudo apt update && sudo apt install -y \
  git \
  make \
  build-essential \
  clang \
  llvm-dev \
  libclang-dev \
  tmux

### 3. Clone Repo & Pull Latest
echo "[3/7] Cloning or updating Nockchain repo..."
if [ ! -d "$PROJECT_DIR" ]; then
  git clone "$REPO_URL" "$PROJECT_DIR"
else
  cd "$PROJECT_DIR"
  git reset --hard HEAD && git pull origin main
fi
cd "$PROJECT_DIR"

### 4. Clone Repo & Pull Latest
echo "[4/7] Cloning or updating Nockchain repo..."
if [ ! -d "$PROJECT_DIR" ]; then
  git clone "$REPO_URL" "$PROJECT_DIR"
else
  cd "$PROJECT_DIR"
  git reset --hard HEAD && git pull origin main
fi
cd "$PROJECT_DIR"

### 5. Setup .env BEFORE building (fixes make error)
echo "[5/7] Creating .env file..."
cp -f .env_example .env
sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$PUBKEY|" "$ENV_FILE"
grep "MINING_PUBKEY" "$ENV_FILE"

### 6. Build Nockchain
echo "[6/7] Building Nockchain..."
make install-hoonc
make build
make install-nockchain
make install-nockchain-wallet


### 7. Start Miner
echo "[7/7] Launching miner in tmux..."
tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
tmux new-session -d -s "$TMUX_SESSION" "cd $PROJECT_DIR && make run-nockchain | tee -a miner.log"

echo ""
echo "✅ Nockchain MainNet Miner launched successfully!"
echo "   - To view miner logs: tmux attach -t $TMUX_SESSION"
echo "   - Wallet PubKey: $PUBKEY"
echo ""
