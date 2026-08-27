# Upgrade — nothing leaves the house

**Who this is for:** you do not want the audio of your own voice, or the contents of your
documents read aloud, going to any outside API — not OpenRouter, not anyone.

**What you replace:** the two hosted calls. Transcription becomes local Whisper. Speech
becomes local Piper. **Everything else in Class 4 stays exactly as it is** — the Telegram
trigger, the guard, the ffmpeg conversion, `sendVoice`, all unchanged.

**What it costs:** RAM, disk, and speed. Read the next section before you start.

---

## Read this before you install anything

**Your machine is the constraint, and it is not close.**

The class stack runs comfortably in about 2 GB. The teaching box has 4 cores, **3.7 GB of
RAM with roughly 1.9 GB free**, and no GPU — and a member on a 1 GB VPS has considerably
less. That is the whole reason this class uses hosted transcription: a local Whisper
container has to fit *alongside* n8n and Postgres, not instead of them.

Rough figures, CPU only, no GPU:

| Piece | Resident RAM | Speed for a 10-second clip |
|---|---|---|
| `faster-whisper` **tiny** | ~200 MB | ~1–2 s. Accuracy noticeably worse on names and numbers. |
| `faster-whisper` **base** | ~350 MB | ~2–4 s |
| `faster-whisper` **small** | ~800 MB | ~5–10 s |
| `faster-whisper` **medium** | ~2 GB | Do not, on this hardware |
| **Piper** (any voice) | ~150 MB | Faster than real time, even on a Pi |

Compare with what you are replacing: **1.7 s to transcribe and 1.3 s to speak**, measured
against the hosted path on 2026-08-25, using no local RAM at all.

**Piper is the easy win. Whisper is the one that will hurt.** If you only do half of this,
do the speech half — it is small, fast, sounds decent, and it removes the API call that
reads your documents out loud.

---

## The honest trade

| | Hosted (the class) | Local (this document) |
|---|---|---|
| Audio of your voice | Leaves your machine | Never leaves |
| Your documents, spoken | Leave your machine | Never leave |
| Round trip | ~2 s | 5–15 s on CPU |
| RAM | none | 350 MB – 1 GB more |
| Cost | fractions of a cent per question | electricity |
| Fails when | OpenRouter is down, or a slug is retired | your box is out of memory |
| Accuracy on names and numbers | very good | noticeably worse below `small` |

Worth naming the thing this does **not** fix: the *answer* still comes from a hosted model,
because Class 3's `/ask` calls one. If the goal is that nothing about your documents ever
reaches an outside company, this document is one third of that job — the other two thirds
are a local embedding model and a local answering model, and both are a bigger fight than
this one.

---

## 1. Replace the ears — faster-whisper

Add a service to the stack's `docker-compose.yml`:

```yaml
  whisper:
    image: fedirz/faster-whisper-server:latest-cpu
    container_name: brain-whisper
    restart: unless-stopped
    environment:
      WHISPER__MODEL: Systran/faster-whisper-base
      WHISPER__TTL: "-1"          # keep the model loaded; first call is slow otherwise
    volumes:
      - whisper-cache:/root/.cache/huggingface
    networks: [ brain ]
```

Put it on the **same network as n8n** and do not publish a port. Nothing outside the stack
needs to reach it, and an unauthenticated transcription endpoint on your LAN is not a thing
you want.

Then in `09 - Voice ask`, replace the `Transcribe` HTTP Request node's URL:

```
http://whisper:8000/v1/audio/transcriptions
```

It speaks the OpenAI transcription shape: `multipart/form-data` with a `file` part and a
`model` part. So the node changes from a JSON body carrying base64 to a **Form-Data** body
carrying the binary — and **the `To base64` Code node disappears entirely**, because you
send the mp3 file itself.

Remove the Header Auth credential from that node. There is no key.

The `ogg to mp3` Execute Command node stays. Whisper handles ogg, but the conversion is
already there, it costs nothing, and keeping both paths on the same format means one less
thing that differs between your setup and everyone else's when you ask for help.

**First call after a container start downloads the model** — a few hundred MB, and it will
time out. Warm it once by hand before you trust it.

---

## 2. Replace the voice — Piper

```yaml
  piper:
    image: rhasspy/wyoming-piper:latest
    container_name: brain-piper
    restart: unless-stopped
    command: --voice en_US-lessac-medium
    volumes:
      - piper-data:/data
    networks: [ brain ]
```

Piper's native protocol is Wyoming, not HTTP, which does not suit an n8n HTTP Request node.
Two ways round it, and the second is better:

**A. Run it as a command.** If you install the `piper` binary into your n8n image, the
whole speech half becomes one Execute Command node:

```bash
echo "<the answer>" | piper --model /data/en_US-lessac-medium.onnx \
  --output_file /tmp/answer-{{ $execution.id }}.wav
```

**B. Put an HTTP wrapper in front of it** — several exist — and keep the node shape you
already have.

Either way, **the entire SSE machinery from P3 disappears.** No streaming, no
`data:` frames, no base64 concatenation, no `pcm16`. Both traps in P3 stop existing,
because Piper hands you a finished wav file. Delete the `Reassemble the audio` node.

The ffmpeg step stays, with the input flags changed — a wav carries its own header, so you
no longer have to describe the format:

```bash
ffmpeg -y -hide_banner -loglevel error \
  -i /tmp/answer-{{ $execution.id }}.wav \
  -c:a libopus -b:a 32k /tmp/answer-{{ $execution.id }}.ogg
```

`sendVoice` is unchanged.

---

## 3. Check it the same way

`VERIFY.md`'s level 4 does not care which engine produced the audio: **forward the bot's
own voice note back to the bot.** If the transcript is the sentence it just spoke, the
local path is sound.

Run that check *before* you decide whether the quality is acceptable. Local speech that
transcribes back correctly but sounds robotic is working. Local speech that comes back as
nonsense is broken, and the two are easy to confuse by ear.

---

## What is verified here and what is not

**Verified:** the RAM and the hardware constraint. Those numbers were measured on the
teaching box, and they are the reason this is an upgrade document rather than the class.

**Not verified:** nothing in this document has been built and run against the class stack.
The image names, the environment variables and the model sizes are all subject to those
projects changing — and both move quickly.

Treat it as a correct direction, not a copy-paste. If you build it, post what actually
worked in the class thread and this file gets better.
