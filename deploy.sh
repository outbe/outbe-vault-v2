#!/usr/bin/env bash
set -euo pipefail

# Deploy Vault using the configuration for the given environment.
# Usage: ./deploy.sh [env_name]
#   env_name defaults to "local-reth"
# Prerequisites: A matching `.<env_name>.env` file must exist with RPC_URL and PRIVATE_KEY.

ENV_NAME="${1:-local-reth}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.${ENV_NAME}.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found"
  exit 1
fi

echo "=== Using environment: $ENV_NAME ==="
source "$ENV_FILE"

# Resolve deployment file from chain id, matching BaseScript.getEnvName().
chain_env_name() {
  case "$1" in
    31337)    echo "anvil" ;;
    424242)   echo "outbe-dev" ;;
    424243)   echo "local-dev" ;;
    97)       echo "bsc-testnet" ;;
    1)        echo "mainnet" ;;
    11155111) echo "sepolia" ;;
    137)      echo "polygon" ;;
    42161)    echo "arbitrum" ;;
    10)       echo "optimism" ;;
    8453)     echo "base" ;;
    512512)   echo "outbe-privnet" ;;
    512215)   echo "local-reth" ;;
    54322345) echo "outbe-peira" ;;
    *)        echo "chain-$1" ;;
  esac
}

CHAIN_ID="$(cast chain-id --rpc-url "$RPC_URL")"
CHAIN_ENV_NAME="$(chain_env_name "$CHAIN_ID")"
DEPLOYMENT_ENV_FILE="$SCRIPT_DIR/.${CHAIN_ENV_NAME}.deployment.env"

if [[ "$CHAIN_ENV_NAME" != "$ENV_NAME" ]]; then
  echo "Note: RPC chain id $CHAIN_ID maps to '$CHAIN_ENV_NAME' — writing to .${CHAIN_ENV_NAME}.deployment.env (env arg was '$ENV_NAME')"
fi

FORGE_COMMON_FLAGS="--rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --gas-estimate-multiplier 300 -vvv"

echo "=== Deploy Vault ==="
forge script script/DeployVault.s.sol $FORGE_COMMON_FLAGS

source "$DEPLOYMENT_ENV_FILE"

echo ""
echo "Vault:       $VAULT_ADDRESS"
echo "VaultSymbol: $VAULT_SYMBOL"

echo ""
echo "=== Deployment complete ==="
echo "All addresses written to $DEPLOYMENT_ENV_FILE"
