# Ears and a Voice — Class 4 pack

This is the download for **AI Auto Base Class 4** of *The Brain That Runs a Company*.

You send a voice note from your phone. Your brain answers out loud, from your own
documents.

---

## 1. What this actually does

```text
phone --voice note--> Telegram --> n8n --> ogg to mp3 --> transcribe
                                                             |
                                           webhook /ask  (CLASS 3, UNCHANGED)
                                                             |
                                                        speak the answer
                                                             |
phone <--voice note-- Telegram <-- ffmpeg <-- parse SSE <----+
```

**It does not touch anything you built in Class 3.** No new table, no schema change, no
migration. It calls your existing `/ask` webhook over HTTP — the same one your dashboard's
Ask tab calls — and does something new with the answer.

That has a useful consequence when something breaks: **if your Ask tab still answers
questions, the fault is in this class. If it does not, the fault is in Class 3.** That one
question splits every problem in half.

---

## 2. What you need first

**The starter pack**, done. Node and Claude Code, Docker, n8n and Postgres running. It is
the standing prerequisite for every class in this series and it is a separate, permanent
download — `brain-starter-pack`. Run its `verify.sh` and it will tell you.

**Class 3 working.** Your dashboard's **Ask** tab answers a question about your own
documents. If it does not, fix that before you start here. This class plugs a phone into
the brain you already have; if that brain is not answering, this cannot make it.

**`PREWORK.md`, done before the hour.** One Telegram bot from BotFather, free, two minutes,
no card — plus your numeric chat id. **Read it before you touch anything**, because there
is an ordering trap in it: the moment n8n's Telegram Trigger goes live, the obvious way to
find your chat id returns `409 Conflict` forever.

**One new signup, and it is the free kind.** Everything else here runs on credentials you
already have:

| Piece | What it costs you |
|---|---|
| Transcription | Your **OpenRouter key from Class 1**. No new credential. |
| Speech | The same key. |
| Audio conversion | **ffmpeg is already inside your n8n container.** Nothing to install. |
| Transport | A Telegram bot token. Free. |

---

## 3. What is in here

| File | What it is |
|---|---|
| `PREWORK.md` | **Start here.** Your bot, your chat id, and the trap in the order you do them |
| `BUILD-THE-BOT.md` | The full reference — every BotFather command, every diagnostic URL, every Docker command, and the workflow node by node |
| `prompts/P1-ears.md` | Telegram in, transcript out. Ends with the bot repeating your own words back as text |
| `prompts/P2-ask.md` | Hands the transcript to your Class 3 brain. Ends with a text answer and its source |
| `prompts/P3-voice.md` | Speaks the answer back as a real voice note. The two traps live here |
| `VERIFY.md` | The acceptance test — including the one that proves the audio is speech and not static |
| `verify.sh` | One command. Prints **Ready**, or names exactly what is missing |
| `docs/UPGRADE-mic.md` | Don't want a public bot? Use your dashboard's microphone instead. Needs HTTPS |
| `docs/UPGRADE-local.md` | Want nothing to leave the house? Local Whisper and Piper |
| `demo/09-voice-ask.json` | The finished workflow. The fallback if a prompt goes sideways |

---

## 4. The order that works

1. **`PREWORK.md`** — bot created, `Start` pressed, chat id written down. Do this first
   and do it in that order. **If you run Content Mate, make a second bot** — one Telegram
   bot can only carry one n8n trigger, and sharing one makes messages vanish with no
   error anywhere. `BUILD-THE-BOT.md` section 1 has the whole story.
2. Add one line to your stack's `.env` and restart n8n. `prompts/P3-voice.md` has it, and
   step 3 of this list is why it is here and not there.
3. **Restart the container.** n8n reads environment variables when it starts and never
   again. Adding the line without restarting produces a `404` from Telegram that looks
   like a broken URL and is actually an empty variable.
4. **P1**, then send your bot a voice note. Your words should come back as text.
5. **Send it something from another account** — or ask someone to. It must refuse. Do not
   skip this; see section 6.
6. **P2.** Send a voice note again. The answer comes back as text with the document it
   came from.
7. **P3.** Send it again. Now you hear it.
8. **`bash verify.sh`** and paste the output in the class thread.

Each of P1, P2 and P3 ends somewhere useful. Voice in / text out is already worth having.
If P3 fights you, you have not lost the hour.

---

## 5. What it costs to run

Pennies per question — transcription and the Class 3 answer are both fractions of a cent,
and the spoken reply is the largest of the three. The real measured figure goes in the
show notes after the class, taken off live usage headers rather than estimated.

There is no subscription and no minimum. It costs nothing when you are not talking to it.

---

## 6. Read this part. It is the one that can hurt you.

**A Telegram bot username is public and searchable.** Nothing stops a stranger finding
yours and messaging it.

In this class that bot is wired to a brain that has read your lease, your insurance policy
and your invoices. **A bot that answers anyone is a bot that reads your documents to
anyone.**

So the first thing the workflow does with an incoming message — before transcription,
before anything — is compare the sender's chat id against yours and drop everything else.
That is why `PREWORK.md` makes you find your chat id, and it is not a hardening step to
get around to later. It is the second node.

**Test the refusal yourself.** Message the bot from a second Telegram account and watch
nothing happen. Until you have seen it refuse, you do not know that it does.

If you would rather not put business documents behind a public username at all: that is a
completely reasonable position, and `docs/UPGRADE-mic.md` does the same job through your
dashboard instead. It needs HTTPS and it is more work. Nobody loses the option.

### Your bot token is a password

Anyone holding it controls your bot completely.

- It goes in an n8n **credential**, and in your `.env` — never typed into a node parameter
- Exported workflows then carry the credential's *name* and the variable's *name*, never
  either value
- If you ever leak it, send `/revoke` to BotFather and get a new one

---

## 7. When it goes wrong

The prompts each carry their own troubleshooting table for the step they build. Two that
span the whole thing:

| What you see | What it means |
|---|---|
| The bot does nothing at all, no execution appears in n8n | The workflow is saved but not **Active**. A Telegram Trigger only registers its webhook when the workflow activates. |
| Everything works, then stops after you edit anything | You deactivated and reactivated. Telegram is fine; check the workflow is Active again. |

Post the **exact error text** in the class thread. The wording is the diagnosis. Never post
your token.

---

*The Brain That Runs a Company — Class 4. Orbix Automation Solutions.*
