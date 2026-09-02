# Read this first — one file is missing on purpose

**Five files in this pack tell you to import `demo/09-voice-ask.json`. There is no
`demo/` folder.**

That is not a corrupt download. Everything in this zip is real, current and built from
the same sources as the live class. One file is absent, deliberately:

    demo/09-voice-ask.json

That would be the *finished* workflow, exported from n8n after a successful end-to-end
run — the fallback you import when a prompt goes sideways and you want the working
version in front of you instead of debugging under time pressure.

## Why it is not here

The workflow is built live, in the hour, with you. Exporting a finished copy in advance
means building it first against a throwaway bot, and that live end-to-end run has not
happened yet. No honest finished copy exists, so none ships.

Shipping the pack without it, clearly labelled, beats shipping a workflow nobody has run.

## What you have instead

| Instead of the missing file | Use | What it is |
|---|---|---|
| The import | `BUILD-THE-BOT.md` | The node-by-node walkthrough of the same workflow. Slower than an import. Complete. |
| The node comparison | `workflow/09-voice-ask.UNVERIFIED.json` | A generated, structurally tested study copy. Read it, import it **inactive** if you like. It has never been run against Telegram — that is what `UNVERIFIED` means, and why `CLAIMS-AUDIT.md` keeps it behind a release gate. |

**Do not activate the study workflow before the class.** Its owner guard has not been
tested against a second account. An active Telegram Trigger with an untested guard is
exactly the failure this class teaches you to avoid.

## Where you will hit the dead reference

When you reach one of these lines, this note is the answer:

| File | What it says |
|---|---|
| `BUILD-THE-BOT.md` (import step) | "Workflows → Import from File → `demo/09-voice-ask.json`" |
| `BUILD-THE-BOT.md` (node table) | "What `demo/09-voice-ask.json` contains, so you can check yours against it" |
| `prompts/P1-ears.md` | "import it, set both credentials, add both `.env` lines, restart" |
| `prompts/P2-ask.md` | "contains the whole finished workflow, P1 through P3" |
| `prompts/P3-voice.md` | "the whole workflow. Import, set both credentials..." |

## What this does not affect

Nothing else depends on that file. `P1`, `P2` and `P3` each build their part from
scratch and each end at something you can see on your own phone. `verify.sh` and
`VERIFY.md` test what you built, not what you imported. The prework, the slides and the
Telegram setup are unaffected.

The verified export lands in an updated pack after the class, and the link you already
have will carry it.
