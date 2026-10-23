#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: tools/codegen.sh [--ts-only]

Generates:
  - TypeScript types into packages/ts-client
  - Dart client into packages/api_client (unless --ts-only)
EOF
}

OPENAPI_SPEC="contracts/openapi.yaml"
TS_OUT="packages/ts-client/src/generated/openapi.ts"
DART_OUT="packages/api_client"
ts_only=false

for arg in "$@"; do
  case "$arg" in
    --ts-only) ts_only=true ;;
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

if [ ! -f "$OPENAPI_SPEC" ]; then
  echo "OpenAPI spec not found at $OPENAPI_SPEC" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "Missing required command: pnpm" >&2
  exit 1
fi

mkdir -p "$(dirname "$TS_OUT")"

echo "==> Generating OpenAPI contract from API source"
pnpm --filter api openapi:generate

echo "==> Generating TypeScript client types"
pnpm exec openapi-typescript "$OPENAPI_SPEC" -o "$TS_OUT"

if [ "$ts_only" = false ]; then
  if ! command -v java >/dev/null 2>&1 || ! java -version >/dev/null 2>&1; then
    echo "Missing required command: java (needed for OpenAPI Dart client generation)." >&2
    echo "Install a JRE/JDK (Java 17+) or run tools/codegen.sh --ts-only." >&2
    exit 1
  fi

  echo "==> Generating Dart API client"
  pnpm exec openapi-generator-cli generate \
    -g dart-dio \
    -i "$OPENAPI_SPEC" \
    -o "$DART_OUT" \
    --skip-validate-spec \
    --additional-properties=pubName=supplybiz_api_client,pubVersion=0.1.0,serializationLibrary=json_serializable
fi

echo "Code generation complete."
