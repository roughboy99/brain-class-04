# Read this first -- one file is missing on purpose

**There is no `demo/` folder in this pack, and five other files tell you there is.**

That is not a corrupt download. Everything in this zip is real, current and was built
from the same sources as the live class. What is absent is one file:

    demo/09-voice-ask.json

It is the finished workflow, exported from n8n -- the *fallback*, the thing you import
when a prompt goes sideways and you want the working version in front of you instead of
debugging under time pressure.

## Why it is not here

The workflow is built live, in the hour, with you. Exporting a copy in advance means
building it first against a throwaway bot. While an n8n Telegram Trigger webhook is
active, `getUpdates` returns `409`; removing the webhook restores polling. That live
end-to-end run has not been done yet, so no honest finished copy exists to ship.

Shipping the pack without it, clearly labelled, beats shipping a workflow nobody has run.

## Where you will hit the dead reference

Five files point at it. When you reach one of these lines, this note is the answer:

| File | What it says |
|---|---|
| `README.md` section 3 | lists `demo/09-voice-ask.json` in the contents table |
| `prompts/P1-ears.md` | "import it, set both credentials, add both `.env` lines, restart" |
| `prompts/P2-ask.md` | "contains the whole finished workflow, P1 through P3" |
| `prompts/P3-voice.md` | "the whole workflow. Import, set both credentials..." |
| `BUILD-THE-BOT.md` | import instructions, and the node-by-node comparison |

**`BUILD-THE-BOT.md` is the fallback in the meantime.** Its node-by-node walkthrough
describes the same workflow the JSON would have contained -- it is slower to follow than
an import, and it is complete.

## What this does not affect

Nothing else in the pack depends on that file. `P1`, `P2` and `P3` each build their part
from scratch and each end at something you can see on your own phone. `verify.sh` and
`VERIFY.md` test what you built, not what you imported.

The export lands in an updated pack after the class, and the link you already have will
carry it.
