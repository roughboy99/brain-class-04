# Class 4 session workflow

Use this as the student-side map during the hour. Times are targets, not promises;
do not skip a failed checkpoint to stay on schedule.

| Time | Build | Required checkpoint |
|---|---|---|
| 0:00-0:09 | Contract and threat model | Class 3 Ask answers and refuses; public HTTPS is ready |
| 0:09-0:11 | Pre-work check | The `409` is recognised as correct; chat id in hand |
| 0:11-0:16 | Step 0: Telegram Trigger and credential, on camera | `Brain Bot (Telegram)` tests green; clipboard cleared; workflow remains inactive |
| 0:16-0:27 | P1: Ears | Owner guard exists before activation; `getWebhookInfo` shows the intended URL; owner voice note returns an accurate transcript |
| 0:27-0:33 | Security test | Second account receives silence; no downstream AI node runs |
| 0:33-0:40 | P2: Ask | Grounded text answer and honest refusal both work |
| 0:40-0:50 | P3: Voice | Telegram displays a playable voice-note bubble |
| 0:50-0:55 | The refusal, spoken | The bot says it does not have that in your documents |
| 0:55-0:58 | Export and cleanup | Workflow remains inactive unless the complete release gate passes |

## Stop conditions

- No public HTTPS URL: do not activate Telegram Trigger.
- Class 3 Ask guesses: repair Class 3 before adding voice.
- Owner guard is empty or a stranger gets a reply: deactivate immediately.
- Audio frames or output bytes are zero: stop before encoding or sending.
- Any secret appears in an execution, export, terminal or recording: revoke and replace it.

## What to keep open

1. The Telegram teaching deck on the shared screen.
2. The private terminal only on an unshared display. n8n itself may be shared: the
   credential's Access Token field masks what you paste, and the reveal icon stays untouched.
3. `CLASS-NOTES.md` for the architecture and debugging order.
4. `VERIFY.md` for acceptance tests.
5. `CLAIMS-AUDIT.md` for the exact release boundary.
