# Class 4 student notes: ears and a voice

## What this class adds

The Class 3 `/ask` contract stays unchanged. Class 4 adds a Telegram transport
and two audio conversions around it:

```text
Telegram voice note
  -> owner guard
  -> download ogg/opus
  -> ffmpeg to mp3
  -> OpenRouter transcription
  -> existing /ask webhook
  -> OpenRouter speech stream
  -> parse audio chunks
  -> ffmpeg to ogg/opus
  -> Telegram sendVoice
```

## Four boundaries to remember

1. **Public boundary:** a bot username is public. The owner guard must run before download or AI work.
2. **Secret boundary:** the Telegram token belongs in the n8n credential and the ignored private env file, never in workflow JSON.
3. **Network boundary:** Telegram Trigger needs a public HTTPS URL; it cannot call localhost.
4. **Class boundary:** if the Class 3 Ask tab fails, repair Class 3 before debugging voice.

## Pre-class checklist

- A separate Brain bot exists and has received one message from your phone.
- Your owner ID is recorded privately.
- Your n8n instance has a public HTTPS URL that reaches the same instance.
- `setup-telegram-private.sh` reports all three variables set.
- The n8n credential is named `Brain Bot (Telegram)`.
- The Class 3 Ask tab answers one grounded question and refuses one unsupported question.
- ffmpeg, ffprobe, and the libopus encoder pass `verify.sh`.

## Workflow milestones

| Milestone | Input | Visible result |
|---|---|---|
| P1 — Ears | Voice note | Accurate transcript returned to Telegram |
| P2 — Ask | Voice or text | Grounded text answer, including honest refusal |
| P3 — Voice | Voice or text | Playable Telegram voice-note bubble |

## Telegram lifecycle

Activating the Telegram Trigger registers a webhook. While that webhook is set,
`getUpdates` returns `409 Conflict`. Deactivating the trigger normally removes the
webhook; `deleteWebhook` can remove it explicitly. The conflict is temporary, not
permanent.

## Debug in this order

1. Does the Class 3 Ask tab still work?
2. Does the public URL reach `/healthz`?
3. Does `getWebhookInfo` show the expected public URL and no recent error?
4. Does private status show the token and owner ID as set?
5. Did the owner guard pass?
6. Did Telegram file download return binary data?
7. Did ffmpeg produce a non-empty file?
8. Did OpenRouter return the expected JSON or SSE shape?
9. Did `sendVoice` receive an ogg/opus binary part named `voice`?

## Status of the included workflow

The pre-class pack includes `workflow/09-voice-ask.UNVERIFIED.json` for study and
inactive import. It is structurally generated and tested, but it is not a
production fallback until the live release gate in `CLAIMS-AUDIT.md` passes.

