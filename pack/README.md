# Class 4 pre-class pack

Read `MISSING-FILES.md` first — one file five other files mention is absent on
purpose, and that note says what to use instead. Then read `notes/CLASS-NOTES.md`,
complete `PREWORK.md`, and use the slide deck for the Telegram steps. The pack is
designed to be shared before class and contains no real credential values.

## Start here

1. Read `MISSING-FILES.md` (two minutes).
2. Open `slides/class-04-telegram-integration.pptx` or the PDF copy.
3. Create and message a separate Brain bot.
4. Stop sharing your terminal and run `bash setup-telegram-private.sh`.
5. Follow `N8N-TELEGRAM-FIRST.md` (video 0 shows every click): add Telegram Trigger and
   create its credential. The token goes into a password field; never click the reveal icon.
6. Clear the clipboard and leave the workflow inactive.
7. Run `bash verify.sh` from your Class 2 stack.
8. Keep the included study workflow **inactive** until the live test gate passes.

## Contents

- `MISSING-FILES.md` — the one file that is absent on purpose, and what to use instead
- `notes/CLASS-NOTES.md` — student-safe class notes and debugging order
- `notes/SESSION-WORKFLOW.md` — student-safe timeline, checkpoints and stop conditions
- `PREWORK.md` — readiness checklist
- `BUILD-THE-BOT.md` — full manual build reference
- `prompts/` — P1, P2, and P3 build prompts
- `workflow/09-voice-ask.UNVERIFIED.json` — inactive study workflow
- `setup-telegram-private.sh` — hidden-input secret setup and clipboard helper
- `PRIVATE-TELEGRAM-SETUP.md` — off-camera procedure
- `N8N-TELEGRAM-FIRST.md` — Step 0: trigger + credential, done before class and again live
- `verify.sh` and `VERIFY.md` — runtime checks and acceptance tests
- `CLAIMS-AUDIT.md` — claim evidence, corrections, and release gate
- `slides/` — screen-safe Telegram teaching deck
- `notes/TELEGRAM-SLIDE-NOTES.md` — presenter notes also embedded in the PPTX

## Security rule

Do not post `.class-04-private.env`, a BotFather token, a real owner ID, or an n8n
credential export. If a bot token leaks, use BotFather `/revoke` immediately.
