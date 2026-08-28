# Class 4 — Ears and a Voice

**The Brain That Runs a Company, Part 4 of 6.** You send a voice note from your phone.
Your brain answers out loud, from your own documents.

> **Student front door: https://roughboy99.github.io/brain-class-04/**
>
> That page is the show notes. It recaps Classes 1–3, carries the one-line install, and
> is what you follow along with during the hour.

Wednesday 2 September 2026, 11:00 AM ET · Skool live room · [AI Auto Base](https://www.skool.com/ai-automation-base)

---

## The one command

Run it in a folder you do not mind it writing to. It needs Claude Code, which you
installed in Class 1.

**macOS / Linux / WSL**

```bash
curl -fsSL -o install.txt https://roughboy99.github.io/brain-class-04/install.txt && claude "Read install.txt in this folder and follow it exactly, from the top."
```

**Windows PowerShell**

```powershell
Invoke-WebRequest -Uri "https://roughboy99.github.io/brain-class-04/install.txt" -OutFile install.txt; claude "Read install.txt in this folder and follow it exactly, from the top."
```

It downloads the pack, verifies the checksum, proves your Class 3 brain still answers
**and still refuses**, and sets up the two environment variables that must exist before
the hour. **It does not build the bot** — that is built live, in class, from three
prompts.

If it finishes and you do not have a talking bot yet, that is the correct outcome.

### Why it fetches a file instead of pasting the prompt inline

The prompt is 10,566 characters. `cmd.exe` caps a command line at 8,191. The inline form
works on Mac and Linux and silently truncates on Windows — which is exactly where the
beginners are.

---

## What is here

| Path | What it is |
|---|---|
| [`index.html`](index.html) | **The show notes.** Classes 1–3 recap, the install, the run of the hour, the traps, the verification |
| [`install.txt`](install.txt) | What the one command fetches — the install prompt as plain text |
| [`setup-gate.html`](setup-gate.html) | The five browser steps no script can do: BotFather, your chat id, the n8n credential, the restart |
| [`downloads/`](downloads/) | The pack zip and `SHA256SUMS` |
| [`pack/`](pack/) | The pack unzipped — every file readable here without downloading anything |

Both HTML pages work standalone from `file://`. They make **no network requests at all**
and reference no external resources, so they work offline and on a locked-down machine.

---

## What you need before this class

Class 4 does not build a brain. It plugs a phone into the one you already have.

| | How to check |
|---|---|
| **The starter pack** — Node, Claude Code, Docker, n8n, Postgres | `bash verify.sh` from the starter pack says **Ready** |
| **Class 3 working** — your dashboard's Ask tab answers a question about your documents | Ask it something your documents cover. Then ask something they do not — it must **refuse**, not guess |
| **Telegram on your phone** | The desktop app alone is not enough; you need to record voice notes |
| **Pre-work done** | The five steps in [`setup-gate.html`](setup-gate.html). About ten minutes, no card |

New to the series? Start at **[Class 3](https://roughboy99.github.io/brain-class-03/)** —
it covers a machine with nothing installed at all, one path per platform.

**If your Ask tab does not answer, fix that first.** Every symptom will otherwise point at
the wrong class.

---

## One file is missing from the pack, on purpose

The zip is named `class-04-voice-pack-DRAFT.zip` and the word DRAFT is deliberate.

`demo/09-voice-ask.json` — the finished workflow you would import if a build went sideways
— **is not in it.** It does not exist yet, because that workflow is built live in this
class and no honest copy of it exists to ship. Producing one in advance means activating
an n8n Telegram Trigger against a throwaway bot first, since doing so registers a webhook
and makes `getUpdates` return `409` on that bot permanently.

**Five files in the pack refer to it anyway:** `README.md`, all three prompts, and
`BUILD-THE-BOT.md`. `DRAFT.md` at the root of the pack names every one of them, so a
member who hits a dead reference knows in ten seconds that the download is not broken.

`BUILD-THE-BOT.md` walks the same workflow node by node and is complete. It is slower to
follow than an import; it is not missing anything.

The export lands in an updated pack after the class, on this same URL.

---

## The three prompts

Each one ends at a milestone you can see on your own phone. Drop out at any of the three
and you still have something that works.

| | Prompt | What you get |
|---|---|---|
| **P1** | `prompts/P1-ears.md` | Send a voice note → **your own words back as text** |
| **P2** | `prompts/P2-ask.md` | Send a voice note → **the answer as text, with its source** |
| **P3** | `prompts/P3-voice.md` | Send a voice note → **you hear the answer** |

Voice in / text out is already worth having, and it is reached before any of the
streaming-and-PCM machinery exists.

---

## Read this part. It is the one that can hurt you.

**A Telegram bot username is public and searchable.** Nothing stops a stranger finding
yours and messaging it. In this class that bot is wired to a brain that has read your
lease, your insurance policy and your invoices.

**A bot that answers anyone is a bot that reads your documents to anyone.**

So the first thing the workflow does with an incoming message — before transcription,
before anything — is compare the sender's chat id against yours and drop everything else.
That is the second node, not a hardening step for later.

**Test the refusal yourself.** Message the bot from a second Telegram account and watch
nothing happen. Until you have seen it refuse, you do not know that it does.

Would rather not put business documents behind a public username at all? That is a
completely reasonable position. `docs/UPGRADE-mic.md` in the pack does the same job
through your dashboard's microphone instead. It needs HTTPS and it is more work.

### Your bot token is a password

It goes in an n8n **credential** and in your `.env` — never typed into a node parameter.
Exported workflows then carry the credential's *name* and the variable's *name*, never
either value. If you ever leak it, send `/revoke` to BotFather.

---

## Verify

From the pack folder:

```bash
bash verify.sh
```

It prints **Ready**, or names exactly what is missing: libopus inside the n8n container,
both environment variables, the Class 3 refusal, and whether both model slugs still exist
on OpenRouter.

**The test that actually proves it:** forward the bot's own voice note back to the bot. It
transcribes its own reply. If what comes back is the sentence it just said, the audio is
real speech and not a plausibly-sized file full of static.

A green checkmark is not evidence. Listen to the audio.

---

## Checksums

```bash
cd downloads && sha256sum -c SHA256SUMS
```

| File | SHA-256 |
|---|---|
| `class-04-voice-pack-DRAFT.zip` | `d451658da78bd5b3083bec38a8a0edc54019109af82e3867338d264c94cdb640` |

This pack pins its zip timestamps, so the same sources always produce the same hash. A
mismatch means the sources moved, not that the clock did.

---

## The series

| Class | What it adds | Where |
|---|---|---|
| 1 · Install the Brain | Claude Code, Codex, VS Code, twelve skills | Aug 12 |
| 2 · Give It Senses | n8n and Postgres, talking to each other | Aug 19 |
| 3 · Ask Your Brain | Memory it can search, with sources | [brain-class-03](https://roughboy99.github.io/brain-class-03/) |
| **4 · Ears and a Voice** | **Telegram in, spoken answers out** | **here** |
| 5 · Hands and a Clock | The 7am digest, draft-don't-send | [brain-class-05](https://roughboy99.github.io/brain-class-05/) |
| 6 · The Graph | What connects to what | [brain-class-06](https://roughboy99.github.io/brain-class-06/) |
| 7 · A Clock It Can Read | Your real calendar, both directions | [brain-class-07](https://roughboy99.github.io/brain-class-07/) |
| **8 · Make It a Project** | History, versions, and a README | [brain-class-08](https://roughboy99.github.io/brain-class-08/) |
| — · Content Mate | The public voice — optional, in the classroom | [brain-content-mate](https://roughboy99.github.io/brain-content-mate/) |

---

## License

MIT — see [LICENSE](LICENSE). The pack is yours: read it, change it, use it at work.

*Orbix Automation Solutions · [getorbix.com](https://getorbix.com)*
