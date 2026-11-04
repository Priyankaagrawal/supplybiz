#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: tools/bootstrap.sh [--skip-fvm] [--skip-native-check]

Sets up workspace dependencies for SupplyBiz:
  1) fvm install
  2) corepack enable + pnpm install
pnpm --filter @supplybiz/api prisma:generate
  3) melos bootstrap
  4) native PostgreSQL/PostGIS + persistent files check (configure apps/api/.env first)
EOF
}

skip_fvm=false
skip_native_check=false

for arg in "$@"; do
  case "$arg" in
    --skip-fvm) skip_fvm=true ;;
    --skip-native-check) skip_native_check=true ;;
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

echo "==> Bootstrapping the pinned Dart workspace"
if command -v fvm >/dev/null 2>&1; then
  fvm flutter pub get --enforce-lockfile
  fvm dart run melos bootstrap
else
  require_cmd flutter
  require_cmd dart
  flutter pub get --enforce-lockfile
  dart run melos bootstrap
fi

if [ "$skip_native_check" = false ]; then
  echo "==> Checking native PostgreSQL/PostGIS and persistent uploads"
  pnpm --filter @supplybiz/api infra:check
fi

echo "Bootstrap complete."
