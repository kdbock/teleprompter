#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env.local ]]; then
  echo "Missing .env.local. Copy .env.local.example and set OPENAI_API_KEY." >&2
  exit 1
fi

set -a
source .env.local
set +a

if [[ -z "${OPENAI_API_KEY:-}" ]]; then
  echo "OPENAI_API_KEY is not set in .env.local" >&2
  exit 1
fi

flutter run --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" "$@"
