#!/usr/bin/env bash
set -euo pipefail

# Private Class 4 setup. Secret values are never printed, even when the caller
# accidentally enabled shell tracing before invoking this script.
case $- in *x*) set +x ;; esac
umask 077

PRIVATE_FILE=".class-04-private.env"
OVERRIDE_FILE="docker-compose.class-04.yml"
MODE="setup"
STACK_DIR="${BRAIN_STACK_DIR:-$HOME/brain}"
PUBLIC_URL="${CLASS04_PUBLIC_URL:-}"

usage() {
  cat <<'EOF'
Usage:
  bash setup-telegram-private.sh [--stack PATH] [--public-url HTTPS_URL]
  bash setup-telegram-private.sh --stack PATH --copy-token
  bash setup-telegram-private.sh --stack PATH --copy-owner
  bash setup-telegram-private.sh --stack PATH --clear-clipboard
  bash setup-telegram-private.sh --stack PATH --status

The default setup reads the Telegram token and owner ID with input hidden,
stores them in an ignored mode-600 file, adds a Compose override, and recreates
n8n. It never prints a secret value.
EOF
}

while (($#)); do
  case "$1" in
    --stack) STACK_DIR="${2:?--stack needs a path}"; shift 2 ;;
    --public-url) PUBLIC_URL="${2:?--public-url needs an HTTPS URL}"; shift 2 ;;
    --copy-token) MODE="copy-token"; shift ;;
    --copy-owner) MODE="copy-owner"; shift ;;
    --clear-clipboard) MODE="clear-clipboard"; shift ;;
    --status) MODE="status"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

cd "$STACK_DIR" 2>/dev/null || {
  printf 'Stack directory not found: %s\n' "$STACK_DIR" >&2
  exit 1
}

copy_clipboard() {
  if command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$1" | clip.exe
  elif command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$1" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$1" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$1" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$1" | xsel --clipboard --input
  else
    printf 'No supported clipboard command found (clip.exe, pbcopy, wl-copy, xclip, xsel).\n' >&2
    return 1
  fi
}

read_field() {
  [ -f "$PRIVATE_FILE" ] || {
    printf 'Private setup has not been run in %s.\n' "$STACK_DIR" >&2
    exit 1
  }
  awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$PRIVATE_FILE"
}

case "$MODE" in
  copy-token)
    value="$(read_field BRAIN_BOT_TOKEN)"
    [ -n "$value" ] || { printf 'Token is missing.\n' >&2; exit 1; }
    copy_clipboard "$value"
    unset value
    printf 'Telegram token copied to the clipboard; no value was displayed.\n'
    exit 0
    ;;
  copy-owner)
    value="$(read_field BRAIN_OWNER_ID)"
    [ -n "$value" ] || { printf 'Owner ID is missing.\n' >&2; exit 1; }
    copy_clipboard "$value"
    unset value
    printf 'Telegram owner ID copied to the clipboard; no value was displayed.\n'
    exit 0
    ;;
  clear-clipboard)
    copy_clipboard ""
    printf 'Clipboard cleared.\n'
    exit 0
    ;;
  status)
    token="$(read_field BRAIN_BOT_TOKEN)"
    owner="$(read_field BRAIN_OWNER_ID)"
    printf 'BRAIN_BOT_TOKEN: %s\n' "$([ -n "$token" ] && printf 'set (%s chars)' "${#token}" || printf 'missing')"
    printf 'BRAIN_OWNER_ID:  %s\n' "$([ -n "$owner" ] && printf 'set (%s chars)' "${#owner}" || printf 'missing')"
    unset token owner
    exit 0
    ;;
esac

[ -f .env ] || { printf 'Missing %s/.env; point --stack at the Class 2 stack.\n' "$STACK_DIR" >&2; exit 1; }

if [ -z "$PUBLIC_URL" ]; then
  printf 'Public HTTPS URL for n8n (input hidden): ' >&2
  IFS= read -r -s PUBLIC_URL
  printf '\n' >&2
fi
PUBLIC_URL="${PUBLIC_URL%/}/"
case "$PUBLIC_URL" in
  https://localhost/*|https://127.*|https://0.0.0.0/*)
    printf 'Telegram cannot reach a localhost URL. Supply the public HTTPS URL of your n8n proxy or tunnel.\n' >&2
    exit 1
    ;;
  https://*.*/*) ;;
  *) printf 'Expected a public HTTPS URL, for example https://n8n.example.com/.\n' >&2; exit 1 ;;
esac

printf 'Paste BotFather token (input hidden): ' >&2
IFS= read -r -s BOT_TOKEN
printf '\nPaste your numeric Telegram owner ID (input hidden): ' >&2
IFS= read -r -s OWNER_ID
printf '\n' >&2

if ! [[ "$BOT_TOKEN" =~ ^[0-9]{8,12}:[A-Za-z0-9_-]{30,60}$ ]]; then
  printf 'The hidden token did not match Telegram Bot API token format. Nothing was written.\n' >&2
  exit 1
fi
if ! [[ "$OWNER_ID" =~ ^[1-9][0-9]{4,19}$ ]]; then
  printf 'The hidden owner ID must be a positive numeric private-chat ID. Nothing was written.\n' >&2
  exit 1
fi

printf 'BRAIN_BOT_TOKEN=%s\nBRAIN_OWNER_ID=%s\n' "$BOT_TOKEN" "$OWNER_ID" > "$PRIVATE_FILE"
chmod 600 "$PRIVATE_FILE" 2>/dev/null || true

if ! grep -qxF "$PRIVATE_FILE" .gitignore 2>/dev/null; then
  printf '\n# Class 4 private Telegram values\n%s\n' "$PRIVATE_FILE" >> .gitignore
fi

cat > "$OVERRIDE_FILE" <<'YAML'
services:
  n8n:
    env_file:
      - .class-04-private.env
    environment:
      N8N_WEBHOOK_URL: ${CLASS04_PUBLIC_URL}
      N8N_PROXY_HOPS: "1"
YAML
chmod 600 "$OVERRIDE_FILE" 2>/dev/null || true

upsert_env() {
  key="$1"
  value="$2"
  tmp=".env.class04.$$"
  awk -v key="$key" -v value="$value" '
    BEGIN { done = 0 }
    index($0, key "=") == 1 { if (!done) print key "=" value; done = 1; next }
    { print }
    END { if (!done) print key "=" value }
  ' .env > "$tmp"
  chmod --reference=.env "$tmp" 2>/dev/null || chmod 600 "$tmp" 2>/dev/null || true
  mv "$tmp" .env
}

base=""
for candidate in compose.yaml compose.yml docker-compose.yaml docker-compose.yml; do
  if [ -f "$candidate" ]; then base="$candidate"; break; fi
done
[ -n "$base" ] || { printf 'No Compose file found in %s.\n' "$STACK_DIR" >&2; exit 1; }

compose_files="$base"
for candidate in compose.override.yaml compose.override.yml docker-compose.override.yaml docker-compose.override.yml; do
  [ -f "$candidate" ] && compose_files="${compose_files}:$candidate"
done
compose_files="${compose_files}:$OVERRIDE_FILE"

upsert_env CLASS04_PUBLIC_URL "$PUBLIC_URL"
upsert_env COMPOSE_PATH_SEPARATOR ":"
upsert_env COMPOSE_FILE "$compose_files"

copy_clipboard "$BOT_TOKEN"
printf 'Private values saved; the bot token is now on your clipboard for the n8n credential.\n'
unset BOT_TOKEN OWNER_ID

if [ "${CLASS04_SKIP_DOCKER:-0}" = "1" ]; then
  printf 'Docker recreation skipped by CLASS04_SKIP_DOCKER.\n'
  exit 0
fi

command -v docker >/dev/null 2>&1 || { printf 'Docker is not installed or not on PATH.\n' >&2; exit 1; }
docker compose config --quiet
docker compose up -d --force-recreate n8n
docker compose exec -T n8n node -e '
for (const key of ["BRAIN_BOT_TOKEN", "BRAIN_OWNER_ID", "N8N_WEBHOOK_URL"]) {
  const value = process.env[key] || "";
  console.log(`${key}: ${value ? `set (${value.length} chars)` : "MISSING"}`);
}
'
printf '\nReady. Paste the clipboard into the n8n credential, save it, then clear it with:\n'
printf '  bash %q --stack %q --clear-clipboard\n' "$0" "$STACK_DIR"
