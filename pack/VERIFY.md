# Class 4 — does it actually work?

Five checks, in order. Each one only makes sense if the one before it passed, so do not
skip ahead — a failure at level 2 that you meet at level 4 is much harder to read.

The last one is the only one that proves the thing this class claims.

---

## What a green check is worth

`verify.sh` tells you the parts are present. It does **not** tell you the workflow works,
and it cannot: it never sends a voice note.

That distinction matters more here than in any other class in this series, because the
output is audio. **A corrupted audio stream produces a file of an entirely plausible size
that plays as static.** Every byte count looks right. Every node is green. You find out on
camera, or in front of someone you were showing it to.

So the last check does not look at the audio. It listens to it — with the transcriber you
already built.

---

## Level 0 — the parts are there

```bash
bash verify.sh
```

Expect **Ready**. If not, it names what is missing. Two of its checks catch things that
are otherwise invisible until the last node of the last prompt:

- **libopus** — ffmpeg can be present and still not be able to encode opus
- **`BRAIN_BOT_TOKEN` non-empty inside the container** — the single most common
  Class 4 failure, and it presents as `404 Not Found`, which everyone reads as a bad
  token

It also checks that `google/gemini-2.5-flash` and `openai/gpt-audio-mini` are still in
OpenRouter's live model list. A retired slug fails as a broken workflow rather than as a
bad name — that has already happened once in this series.

---

## Level 1 — it refuses a stranger

**Do this before anything else, and do it deliberately.**

Message your bot from a **second Telegram account** — a friend's phone, a second account
of your own, anything that is not you.

| What should happen | |
|---|---|
| On the stranger's phone | **Nothing.** No reply, no error, no typing indicator. |
| In n8n's execution list | One execution, **green**, that stops at `Is this you?` |
| Inside that execution | The Code node's log shows the refused id. No node after it ran. |

Open that execution and look at it. A green execution that does nothing is not a bug — it
is the entire security model of this class, and you should know what it looks like.

> **If a stranger gets a reply, stop here.** Your bot's username is public and it is wired
> to a brain that has read your lease, your invoices and your insurance policy. Nothing
> below this line matters until this passes.

**If it refuses *you*:** `BRAIN_OWNER_ID` is empty inside the container. The guard is
comparing your id against `''`. Run `setup-telegram-private.sh --status`; if it reports
missing, rerun private setup so Compose recreates n8n.

---

## Level 2 — it hears you

Send your bot a voice note saying, clearly:

> *"testing one two three"*

Expected back, as text, within about three seconds:

```
testing one two three
```

| If instead you get | Look at |
|---|---|
| Nothing at all, no execution | The workflow is not **Active**. A Telegram Trigger registers its webhook on activation. |
| An empty transcript, every time | The Read node's binary output. 0 bytes means ffmpeg wrote nothing — its stderr says why. |
| A *description* of the audio | The text part of the transcription message. It has to say *transcribe verbatim, output only the transcript*. |
| `404` from OpenRouter | The model slug is retired. Level 0 checks this. |

---

## Level 3 — the brain is doing the thinking

Two questions, and the second is the important one.

**Ask something your documents answer.** Out loud:

> *"How much is the security deposit on the warehouse?"*

```
The security deposit is $7,700, equal to two months of base rent.
(warehouse-lease.md)
```

The source filename in brackets is the proof. Without it you cannot tell an answer from
your documents apart from an answer the model happened to know.

**Ask something they do not.** Out loud:

> *"What is my dog's name?"*

```
I don't have that in your documents.
```

**If a name comes back, stop.** That is a Class 3 fault — your similarity threshold or
your system message — and it means every answer it has ever given you is now suspect.
Nothing in Class 4 can fix it and no amount of work here should try.

---

## Level 4 — it speaks, and the speech is real

Ask the warehouse question again. Now you should get **two** messages: the text, then a
**voice note** — the round waveform bubble with a play button and a duration, not a
rectangular music-player card.

Play it. It should say the answer.

### And now the check that actually proves it

Playing it yourself proves it to you, once, on that phone. **Prove it mechanically:**

> **Forward the bot's own voice note back to the bot.**

It is a voice note, so P1 treats it like any other: it downloads it, converts it,
transcribes it and replies with the text. If what comes back is the sentence it just spoke,
then every step between the model and your ear is sound — the SSE parse, the base64
concatenation, the PCM flags, the opus encode, and the upload.

This is exactly how the path was proved during the build, on 2026-08-25:

> **asked for:** *"The warehouse lease renews on March first and the deductible is two
> thousand five hundred dollars."*
> **came back:** *"The warehouse lease renews on March 1st and the deductible is $2,500."*

The punctuation and the `$2,500` are the transcriber tidying up. The words are the words.

**If the transcript comes back empty or as nonsense**, the audio is garbage even though
the file size looks fine. Go to the table below.

---

## Reference numbers

Measured on the live stack on 2026-08-25 for the processing path. Telegram transfer,
webhook transit, phone playback and cold starts were outside this probe. Treat the values
as observations, not an end-to-end promise.

| Step | Measured |
|---|---|
| Transcription, `google/gemini-2.5-flash` | 200 · 1.7 s · verbatim |
| Speech, `openai/gpt-audio-mini` | 200 · 1.3 s · 24 kHz PCM |
| SSE buffered by the HTTP node | 221,987 characters, whole |
| SSE parsed | 22 `data:` lines → **9 audio frames** |
| Reassembled PCM | 266,400 bytes = 5.55 s |
| ffmpeg → ogg/opus | 22,297 bytes, 5.56 s, `exitCode 0`, empty stderr |
| Processing-path observation in that probe | **about 2 seconds** |

Your `Reassemble the audio` node reports `audioFrames`, `pcmBytes` and `seconds` for
exactly this reason. **Zero frames means stop** — everything after it will build a
plausible file out of nothing.

---

## Reading a bad voice note

The symptom tells you which step broke. This is the table worth keeping.

| It sounds like | The cause |
|---|---|
| **Static / white noise** | The base64 was decoded per frame and the bytes joined. Concatenate the base64 first, decode once. |
| **Chipmunk / too fast** | ffmpeg's input sample rate is too low. It must be `-ar 24000` **before** `-i`. |
| **Slow / deep** | Input sample rate too high. Same flag. |
| **Doubled, echoing, half speed** | `-ac 1`. The stream is mono; telling ffmpeg it is stereo halves the rate. |
| **Silence, correct duration** | The PCM was all zeros — the model streamed no audio deltas but the request still succeeded. Read the raw text; an error object streams back the same way a success does. |
| **The first second, then cut off** | Only one frame was recovered. The `[DONE]` break is firing too early, or the parse is throwing on a keepalive frame instead of skipping it. |
| **The right words, the wrong answer** | Two executions collided on a fixed temp filename. Every path needs `{{ $execution.id }}`. |
| **It reads the filename out loud** | You are speaking the combined text instead of the answer field. |

---

## What this does *not* verify

Say it plainly, because a checklist that implies more than it checked is worse than none.

- **Nothing here tests Spanish.** Every measurement in this class was taken in English.
  Both models handle Spanish and a Spanish voice note will very likely work — that is a
  property of the tools, not a promise this class makes. Nobody has run it.
- **Nothing here tests a long answer.** Class 3 caps its answers at two sentences. If you
  removed that cap, you are streaming an unbounded amount of audio through a node with a
  120-second timeout, and this has not been measured.
- **Nothing here tests concurrency beyond two.** The `{{ $execution.id }}` filenames are
  the right fix, but the only collision anyone has actually provoked is two.
- **`verify.sh` does not send a voice note.** It never has and it never will. Level 4 is
  the test; the script is the preflight.
