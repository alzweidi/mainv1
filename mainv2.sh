#!/bin/bash

set -euo pipefail

### CONFIG
PUBKEY="3MXohQ9ExcSQa1qttFgj15yZi3Xptwh2R99FoAgU5MxZYhFMN9bKhAPRWNmrUfXPy3WJoocvkHicCRfm7WV3BLXx7CHKJTnEPJMpdvdNF5rPRfowUBM6HB7LFgorcp6z464V"
PEERS=(
  "/ip4/95.216.102.60/udp/3006/quic-v1"
  "/ip4/65.108.123.225/udp/3006/quic-v1"
  "/ip4/65.109.156.108/udp/3006/quic-v1"
  "/ip4/65.21.67.175/udp/3006/quic-v1"
  "/ip4/65.109.156.172/udp/3006/quic-v1"
  "/ip4/34.174.22.166/udp/3006/quic-v1"
  "/ip4/34.95.155.151/udp/30000/quic-v1"
  "/ip4/34.18.98.38/udp/30000/quic-v1"
)

echo ""
echo "[+] Installing dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev libclang-dev llvm-dev

### Rust install
if ! command -v cargo &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

### Clean any previous install
rm -rf nockchain .nockapp

### Clone & build
git clone https://github.com/zorp-corp/nockchain
cd nockchain

cp .env_example .env
sed -i "s|^MINING_PUBKEY=.*|MINING_PUBKEY=$PUBKEY|" .env

make install-hoonc
make build
make install-nockchain-wallet
make install-nockchain

### Set path to binaries
export PATH="$PATH:$(pwd)/target/release"

### OPTIONAL: open ports if using UFW firewall
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 3005/tcp
sudo ufw allow 3006/tcp
sudo ufw --force enable

### Start mining in a screen session
echo "[+] Starting miner..."
screen -S miner -dm bash -c "nockchain --mining-pubkey $PUBKEY --mine $(printf ' --peer %s' "${PEERS[@]}")"

echo ""
echo "✅ Miner started in screen session named 'miner'"
echo "   - To view: screen -r miner"
echo "   - To detach: Ctrl+A then D"
echo "   - To kill: screen -XS miner quit"
echo ""
