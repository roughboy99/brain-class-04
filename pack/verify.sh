#!/usr/bin/env bash
# The Brain That Runs a Company -- Class 4 check (ears and a voice).
#
# Read this before you run it. That is the rule for every script in this series,
# including mine.
#
# What it touches, honestly:
#   - your own machine on localhost (n8n's health endpoint, your Class 3 /ask webhook)
#   - your n8n container, to ask what ffmpeg it has and whether two environment
#     variables are set. It checks that they are NON-EMPTY. It never prints them.
#   - openrouter.ai/api/v1/models -- a public list, no key sent
#   - api.telegram.org/getMe -- this one DOES send your bot token, to Telegram and
#     nowhere else, and it is run from inside the container so the token never enters
#     your shell history or this terminal's scrollback. Skip it with: NO_TELEGRAM=1
#
# Run it, then paste the WHOLE output in the class thread -- green or red.
#
#   bash verify.sh
#
# Exit code is 0 if everything passed, 1 if anything failed.

VERSION="0.1.0"

PASS=0
FAIL=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; B=$'\033[1m'; Z=$'\033[0m'
else
  G=''; R=''; Y=''; B=''; Z=''
fi

ok()   { PASS=$((PASS+1)); printf '  %sPASS%s  %-34s %s\n' "$G" "$Z" "$1" "$2"; }
bad()  { FAIL=$((FAIL+1)); printf '  %sFAIL%s  %-34s %s\n' "$R" "$Z" "$1" "$2"; }
warn() {                   printf '  %s -- %s  %-34s %s\n' "$Y" "$Z" "$1" "$2"; }
head_() { printf '\n%s== %s%s\n' "$B" "$1" "$Z"; }

# A check that cannot fail is not a check. Everything below runs the real thing and
# reads the real answer.

head_ "Part 1 - the stack is up"

CODE="$(curl -s -m 8 -o /dev/null -w '%{http_code}' http://localhost:5678/healthz 2>/dev/null)"
case "$CODE" in
  200) ok "n8n /healthz" "HTTP 200" ;;
  000) bad "n8n /healthz" "no answer - is the stack running? first boot takes 60-90s" ;;
  *)   bad "n8n /healthz" "HTTP $CODE" ;;
esac

N8N="$(docker ps --format '{{.Names}}' 2>/dev/null | grep -i n8n | head -1)"
if [ -n "$N8N" ]; then
  ok "n8n container" "$N8N"
else
  bad "n8n container" "nothing running with 'n8n' in its name"
fi

head_ "Part 2 - Class 3 still answers"

# This class does not build a brain, it plugs a phone into the one you have. If /ask
# is not answering, nothing below this line can work and the fault is in Class 3.
ASK="$(curl -s -m 20 -X POST http://localhost:5678/webhook/ask \
        -H 'Content-Type: application/json' \
        -d '{"question":"What is my dog'"'"'s name?"}' 2>/dev/null)"

case "$ASK" in
  "")
    bad "/webhook/ask" "no response - is the Class 3 workflow Active?" ;;
  *'"answered"'*)
    # The refusal is the check. A brain that answers this one has a broken threshold.
    case "$ASK" in
      *'"answered":false'*|*'"answered": false'*)
        ok "/webhook/ask refuses" "said it does not have that in your documents" ;;
      *)
        bad "/webhook/ask refuses" "it ANSWERED a question your documents cannot answer - fix Class 3 first" ;;
    esac ;;
  *'404'*|*'not registered'*)
    bad "/webhook/ask" "404 - the Class 3 workflow is saved but not Active" ;;
  *)
    bad "/webhook/ask" "unexpected response: $(printf '%s' "$ASK" | head -c 120)" ;;
esac

head_ "Part 3 - ffmpeg, inside the container"

if [ -n "$N8N" ]; then
  FFV="$(docker exec "$N8N" ffmpeg -version 2>/dev/null | head -1)"
  if [ -n "$FFV" ]; then
    ok "ffmpeg" "$(printf '%s' "$FFV" | cut -c1-48)"
  else
    bad "ffmpeg" "not in the container - Telegram voice notes cannot be produced"
  fi

  # ffmpeg being present is not the same as ffmpeg being able to make an opus file,
  # and a build without libopus fails only at the last step of the last prompt.
  if docker exec "$N8N" ffmpeg -hide_banner -encoders 2>/dev/null | grep -q libopus; then
    ok "libopus encoder" "present"
  else
    bad "libopus encoder" "ffmpeg is there but cannot encode opus"
  fi

  if docker exec "$N8N" sh -c 'touch /tmp/.c4probe && rm -f /tmp/.c4probe' 2>/dev/null; then
    ok "/tmp writable" "yes"
  else
    bad "/tmp writable" "the audio has nowhere to land"
  fi
else
  warn "ffmpeg" "skipped - no n8n container"
fi

head_ "Part 4 - the two environment variables"

# Set is not the same as visible to a node, and neither is the same as non-empty.
# n8n reads the environment when the container STARTS. Editing .env without a restart
# leaves these blank, and the failure downstream looks like a broken URL.
if [ -n "$N8N" ]; then
  for var in BRAIN_BOT_TOKEN BRAIN_OWNER_ID; do
    VAL="$(docker exec "$N8N" printenv "$var" 2>/dev/null | tr -d '\r\n')"
    if [ -n "$VAL" ]; then
      ok "$var" "set, ${#VAL} characters (value not shown)"
    else
      bad "$var" "empty in the container - add it to .env and RESTART n8n"
    fi
  done

  BLOCK="$(docker exec "$N8N" printenv N8N_BLOCK_ENV_ACCESS_IN_NODE 2>/dev/null | tr -d '\r\n')"
  case "$BLOCK" in
    false|"") ok "env access in nodes" "allowed${BLOCK:+ (explicitly false)}" ;;
    *)        bad "env access in nodes" "N8N_BLOCK_ENV_ACCESS_IN_NODE=$BLOCK - sendVoice cannot read the token" ;;
  esac
else
  warn "environment" "skipped - no n8n container"
fi

head_ "Part 5 - the models still exist"

# A retired slug fails as a broken workflow rather than as a bad name. This has
# already happened once in this series: google/gemini-2.0-flash-001 returned 404.
# The models list is public - no key leaves your machine here.
MODELS="$(curl -s -m 15 https://openrouter.ai/api/v1/models 2>/dev/null)"
if [ -z "$MODELS" ]; then
  warn "openrouter models" "could not reach openrouter.ai - check again before class"
else
  for slug in "google/gemini-2.5-flash" "openai/gpt-audio-mini"; do
    if printf '%s' "$MODELS" | grep -q "\"$slug\""; then
      ok "model: $slug" "listed"
    else
      bad "model: $slug" "NOT in the current model list - it may have been retired"
    fi
  done
fi

head_ "Part 6 - your bot"

if [ -n "${NO_TELEGRAM:-}" ]; then
  warn "telegram getMe" "skipped (NO_TELEGRAM is set)"
elif [ -n "$N8N" ]; then
  # Run from inside the container so the token is never interpolated into a command
  # line on your machine. Only the bot's username comes back out.
  BOT="$(docker exec "$N8N" node -e '
    const t = process.env.BRAIN_BOT_TOKEN;
    if (!t) { console.log("NOTOKEN"); process.exit(0); }
    fetch("https://api.telegram.org/bot" + t + "/getMe")
      .then(r => r.json())
      .then(j => console.log(j.ok ? "OK @" + j.result.username : "ERR " + j.error_code + " " + j.description))
      .catch(e => console.log("ERR " + e.message));
  ' 2>/dev/null | tr -d '\r')"
  case "$BOT" in
    OK*)      ok "telegram getMe" "${BOT#OK }" ;;
    NOTOKEN)  bad "telegram getMe" "no token in the container - see Part 4" ;;
    "ERR 401"*) bad "telegram getMe" "401 - the TOKEN is wrong or was revoked" ;;
    "ERR 404"*) bad "telegram getMe" "404 - the URL is wrong, not the token" ;;
    ERR*)     bad "telegram getMe" "${BOT#ERR }" ;;
    *)        bad "telegram getMe" "no answer from the container" ;;
  esac
else
  warn "telegram getMe" "skipped - no n8n container"
fi

head_ "Result"

printf '\n  class-04-voice %s\n' "$VERSION"
printf '  %s passed, %s failed\n\n' "$PASS" "$FAIL"

if [ "$FAIL" -eq 0 ]; then
  printf '  %sReady.%s Paste this output in the class thread.\n' "$G" "$Z"
  printf '  This does not prove the workflow works - send yourself a voice note for that.\n'
  printf '  See VERIFY.md for the test that actually proves the audio is speech.\n\n'
  exit 0
else
  printf '  %sNot ready.%s Paste this output in the class thread -- all of it,\n' "$R" "$Z"
  printf '  including the failures. That is what gets it fixed before the hour.\n\n'
  exit 1
fi
