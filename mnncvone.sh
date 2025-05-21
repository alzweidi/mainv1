
#!/bin/bash

set -e

### CONFIG
REPO_URL="https://github.com/zorp-corp/nockchain"
PROJECT_DIR="$HOME/nockchain"
PUBKEY="3MXohQ9ExcSQa1qttFgj15yZi3Xptwh2R99FoAgU5MxZYhFMN9bKhAPRWNmrUfXPy3WJoocvkHicCRfm7WV3BLXx7CHKJTnEPJMpdvdNF5rPRfowUBM6HB7LFgorcp6z464V"  # Replace this with your real one
ENV_FILE="$PROJECT_DIR/.env"

echo ""
echo "[+] Nockchain MainNet Bootstrap Starting..."
echo "-------------------------------------------"

### 1. Install Rust Toolchain
echo "[1/6] Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"

# Verify Rust installed
if ! command -v cargo &> /dev/null; then
  echo "❌ Rust install failed. Aborting."
  exit 1
fi

### 2. Install System Dependencies
echo "[2/6] Installing system dependencies..."
sudo apt update && sudo apt install -y \
  git \
  make \
  build-essential \
  clang \
  llvm-dev \
  libclang-dev \
  tmux

### 3. Clone Repo & Pull Latest
echo "[3/6] Cloning Nockchain repo..."
if [ ! -d "$PROJECT_DIR" ]; then
  git clone "$REPO_URL" "$PROJECT_DIR"
else
  echo "    Repo already exists. Pulling latest..."
  cd "$PROJECT_DIR"
  git pull origin main
fi
cd "$PROJECT_DIR"

### 4. Install Hoon Compiler (still required)
echo "[4/6] Installing Hoon Compiler (hoonc)..."
make install-hoonc

### 5. Build Binaries
echo "[5/6] Building Nockchain binaries..."
make build
make install-nockchain
make install-nockchain-wallet

### 6. Inject PubKey into .env
echo "[6/6] Setting up pubkey environment..."
cp .env_example .env
sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$PUBKEY|" "$ENV_FILE"
grep "MINING_PUBKEY" "$ENV_FILE"

### 7. Launch Miner in tmux
echo "[7/7] Launching Nockchain Miner..."
tmux kill-session -t nock-miner 2>/dev/null || true
tmux new-session -d -s nock-miner "cd $PROJECT_DIR && make run-nockchain | tee -a miner.log"

echo ""
echo "✅ Nockchain MainNet Miner launched successfully."
echo "   - tmux attach -t nock-miner"
echo "   - Log output: $PROJECT_DIR/miner.log"
echo "   - Wallet PubKey: $PUBKEY"
echo ""
