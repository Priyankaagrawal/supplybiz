#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: tools/bootstrap.sh [--skip-fvm] [--skip-docker]

Sets up workspace dependencies for SupplyBiz:
  1) fvm install
  2) corepack enable + pnpm install
  3) melos bootstrap
  4) docker compose up -d (local infra)
EOF
}

skip_fvm=false
skip_docker=false

for arg in "$@"; do
  case "$arg" in
    --skip-fvm) skip_fvm=true ;;
    --skip-docker) skip_docker=true ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
}

if [ "$skip_fvm" = false ]; then
  require_cmd fvm
  echo "==> Installing Flutter version from .fvmrc"
  fvm install
fi

if command -v corepack >/dev/null 2>&1; then
  echo "==> Enabling corepack"
  corepack enable
elif ! command -v pnpm >/dev/null 2>&1; then
  echo "corepack is not installed and pnpm was not found on PATH." >&2
  echo "Install pnpm manually or install a Node distribution with corepack." >&2
  exit 1
fi

require_cmd pnpm
echo "==> Installing Node workspace dependencies"
pnpm install

if command -v melos >/dev/null 2>&1; then
  echo "==> Bootstrapping Dart workspace with melos"
  melos bootstrap
else
  echo "==> melos not found on PATH, using dart pub global activate melos"
  if command -v dart >/dev/null 2>&1; then
    dart pub global activate melos
  elif command -v fvm >/dev/null 2>&1; then
    fvm dart pub global activate melos
  else
    echo "Neither dart nor fvm is available to install melos." >&2
    exit 1
  fi
  if ! command -v melos >/dev/null 2>&1; then
    export PATH="$PATH:$HOME/.pub-cache/bin"
  fi
  require_cmd melos
  melos bootstrap
fi

if [ "$skip_docker" = false ]; then
  require_cmd docker
  echo "==> Starting local infra with docker compose"
  docker compose -f infra/docker/docker-compose.yml up -d
fi

echo "Bootstrap complete."
