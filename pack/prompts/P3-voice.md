# P3 — Give it a voice

**What it builds:** the answer comes back as a real Telegram voice note, spoken.

**Before you run it:** P2 works — you ask out loud, you get the answer as text.

**Milestone:** voice in, voice out. This is the class.

> **There are two traps in this step and neither is documented anywhere you would look.**
> Both are in the prompt in writing, right next to the line that would otherwise be wrong.
> Read this page before you run it — this is the one step where guessing costs an hour.

---

## First: one line in your `.env`, and a restart

n8n's own Telegram node **cannot send a voice note.** Its operations are `sendMessage`,
`sendVideo`, `sendAudio`, `sendAnimation`, `sendPhoto`, `sendDocument`, `sendSticker`,
`sendLocation`, `sendMediaGroup`, `sendChatAction`. There is no `sendVoice`. (`sendAudio`
works, but it arrives as a music-player bubble, not a voice note.)

So the final call goes out over plain HTTP — and a Telegram HTTP call carries its token
**in the URL**. That is a problem, because you are going to export this workflow.

The fix is that the URL reads the token from your environment:

```
https://api.telegram.org/bot{{ $env.BRAIN_BOT_TOKEN }}/sendVoice
```

The exported JSON then carries the **variable's name**, never its value.

In your stack folder, add to `.env`:

```bash
BRAIN_BOT_TOKEN=paste-the-token-BotFather-gave-you
```

Then restart:

```bash
docker compose restart n8n
docker compose exec n8n printenv BRAIN_BOT_TOKEN
```

If that second command prints nothing, the restart did not take and the next section will
fail with a `404` that looks like a broken URL.

> **This works on every member's stack, not just on mine.** n8n blocks nodes from reading
> environment variables by default. The starter pack's installer sets
> `N8N_BLOCK_ENV_ACCESS_IN_NODE: "false"`, so your stack can do this. Worth knowing that it
> was checked — a design that only works on the teaching box is a design that fails in the
> room.
>
> The Telegram *credential* cannot help here. n8n's `TelegramApi` credential defines a
> `test` block and no `authenticate` block, so attaching it to an HTTP Request node as a
> predefined credential type injects nothing at all. The credential still does the trigger
> and the download; only this one call reads the variable.

---

## The prompt

```text
Finish the `09 - Voice ask` workflow. It currently answers with text. Now speak the
answer back as a real Telegram voice note.

Add after `Shape the reply`:

  HTTP Request (Speak it) -> Code (Reassemble the audio) -> Read/Write File (write PCM)
    -> Execute Command (ffmpeg) -> Read/Write File (read ogg)
    -> HTTP Request (sendVoice) -> Execute Command (clean up)

1. HTTP Request node `Speak it`:
   - POST https://openrouter.ai/api/v1/chat/completions
   - Authentication: Generic -> Header Auth -> the existing `OpenRouter` credential.
   - JSON body:
     {
       "model": "openai/gpt-audio-mini",
       "modalities": ["text", "audio"],
       "audio": { "voice": "alloy", "format": "pcm16" },
       "stream": true,
       "messages": [
         { "role": "user",
           "content": "Read this aloud exactly as written, with no preamble: <the ANSWER field from Shape the reply, not the combined text>" }
       ]
     }

   TRAP ONE - the format and the streaming flag are locked together:
     format "mp3" with no streaming  -> 400 "Audio output requires stream: true"
     format "mp3" with stream: true  -> 400 "does not support 'mp3' when stream=true.
                                             Supported values are: 'pcm16'"
     format "pcm16" with stream: true -> 200
   Both failures are 400s whose message is only in the response body. Do not change
   either of these two values.

   - Options -> Response -> Response Format: **text**. This is mandatory. The reply is
     a Server-Sent Events stream; n8n does not parse SSE, and without this it tries to
     JSON.parse the stream and throws before you ever see the body.
   - Timeout 120000.

   Speak the ANSWER, not the combined text. The combined text ends with the source
   filename and nobody wants to hear "open paren warehouse dash lease dot em dee".

2. Code node `Reassemble the audio`:

   // Concatenate the base64 FIRST, decode ONCE.
   const body = $input.first().json.data;
   if (typeof body !== 'string') throw new Error('Expected raw text, got ' + typeof body);

   const parts = [];
   let frames = 0;
   for (const raw of body.split('\n')) {
     const line = raw.trim();
     if (!line.startsWith('data:')) continue;
     const payload = line.slice(5).trim();
     if (payload === '[DONE]') break;
     try {
       const a = JSON.parse(payload)?.choices?.[0]?.delta?.audio;
       if (a?.data) { parts.push(a.data); frames++; }
     } catch (e) { /* keepalive frame, not JSON */ }
   }

   const pcm = Buffer.from(parts.join(''), 'base64');
   if (pcm.length === 0) throw new Error('no audio frames recovered from the stream');

   return [{
     json: { audioFrames: frames, pcmBytes: pcm.length,
             seconds: +(pcm.length / 48000).toFixed(2) },
     binary: { data: { data: pcm.toString('base64'),
                       mimeType: 'audio/L16', fileName: 'answer.pcm' } },
   }];

   TRAP TWO is that join('') on line 'const pcm ='. Concatenate the base64 strings and
   decode the result once. Decoding each frame separately and joining the BYTES works by
   luck with base64 padding and breaks the first time a frame's length is not a multiple
   of 3. It does not throw when it breaks - it produces audio that plays as static.
   Put that explanation in the node's notes.

   Carry the chat id through this node.

3. Read/Write File, Write: /tmp/answer-{{ $execution.id }}.pcm

4. Execute Command node `To a voice note`:

   ffmpeg -y -hide_banner -loglevel error \
     -f s16le -ar 24000 -ac 1 -i /tmp/answer-{{ $execution.id }}.pcm \
     -c:a libopus -b:a 32k /tmp/answer-{{ $execution.id }}.ogg

   Those three input flags describe raw PCM, which carries no header saying what it is:
   signed 16-bit little-endian, 24 kHz, mono. That is what OpenRouter's pcm16 actually
   is. Get any of the three wrong and ffmpeg still produces a file - it just sounds
   wrong, fast, slow, or like static. There is no error to read.

   Telegram voice notes must be ogg/opus, which is why the image ships libopus.

5. Read/Write File, Read: /tmp/answer-{{ $execution.id }}.ogg

6. HTTP Request node `sendVoice`:
   - POST https://api.telegram.org/bot{{ $env.BRAIN_BOT_TOKEN }}/sendVoice
   - Send Body: ON, Body Content Type: **Form-Data (multipart)**
   - Fields:
       chat_id  = the chat id carried down
       voice    = the binary field from step 5 (n8n Binary File parameter type)
   - No credential attached. The token comes from the environment variable in the URL.

7. Execute Command node `Clean up`, always runs:
     rm -f /tmp/voice-{{ $execution.id }}.* /tmp/answer-{{ $execution.id }}.*
   Every execution leaves four files in the container otherwise, and nothing removes
   them until the container is recreated.

Keep the text Telegram message too - send it before the voice note. Seeing the answer
written down while you listen is better than either alone, and it is what you screenshot
when something is wrong.

Then walk me through testing it end to end from my phone, and tell me how I would know
the difference between "the audio is silent" and "the audio is garbage".
```

---

## What correct looks like

Speak into your phone:

> *"When does the warehouse lease renew?"*

Within a few seconds: a text message with the answer and its source, then a **voice note**
— the round waveform bubble with a play button and a duration, not a rectangular music
player.

Play it. It should say the answer.

### These numbers, measured on the live stack

Taken on 2026-08-25 running the real path, not read from documentation:

| Step | Measured |
|---|---|
| Transcription, `google/gemini-2.5-flash` | 200 · 1.7 s · verbatim |
| Speech, `openai/gpt-audio-mini` | 200 · 1.3 s · 24 kHz PCM |
| SSE buffered by the HTTP node | **221,987 characters, whole** |
| Frames recovered | 22 `data:` lines → 9 audio frames |
| Reassembled PCM | 266,400 bytes = 5.55 s |
| ffmpeg → ogg/opus | 22,297 bytes, 5.56 s, `exitCode 0` |
| End to end inside n8n | **2 seconds** |

If your `Reassemble the audio` node reports zero frames or a `pcmBytes` of 0, stop there.
Everything downstream will produce a plausible-looking file out of nothing.

---

## The test that actually proves it

**A byte count that looks right is not evidence.** A corrupted stream produces a
plausibly-sized file that plays as static, and you find out on camera.

So prove it the way it was proved during the build: **send the generated voice note back
through your own bot.** Forward it to your bot as a voice note. P1 transcribes it. If the
transcript is the sentence it just spoke, the whole path is sound.

That closed loop is the acceptance test in `VERIFY.md`. It is the only check that
distinguishes *"audio arrived"* from *"speech arrived"*.

---

## If it goes wrong

| What you see | What it means |
|---|---|
| `400` — *"Audio output requires stream: true"* | Trap one. `stream` must be `true`. |
| `400` — *"does not support 'mp3' when stream=true"* | Trap one, the other half. `format` must be `pcm16`. |
| A `JSON.parse` error inside the HTTP node itself | Response Format is not set to **text**. n8n is trying to parse an SSE stream. |
| `no audio frames recovered from the stream` | The body arrived but had no audio deltas. Look at the raw text — an error object streams back the same way a success does. |
| The voice note plays as static or noise | Trap two: the base64 was decoded per frame instead of concatenated first. Check the `join('')`. |
| It plays too fast, too slow, or chipmunked | The ffmpeg **input** flags. `-f s16le -ar 24000 -ac 1`, all three, before `-i`. |
| It arrives as a music player, not a voice bubble | You used the Telegram node's `sendAudio`. There is no `sendVoice` operation on that node — this call has to be the HTTP Request. |
| `404 Not Found` from `api.telegram.org` | The URL, not the token. Almost always `BRAIN_BOT_TOKEN` is empty in the container: `docker compose exec n8n printenv BRAIN_BOT_TOKEN`. Empty → the URL became `/bot/sendVoice`. Restart n8n. |
| `401 Unauthorized` from `api.telegram.org` | The token itself. Telegram read it and rejected it. Revoked, or a character dropped. |
| The expression `{{ $env.BRAIN_BOT_TOKEN }}` renders empty in the editor | Your n8n blocks env access in nodes. `N8N_BLOCK_ENV_ACCESS_IN_NODE` must be `"false"`. The starter pack sets it. |
| `Bad Request: VOICE_MESSAGES_FORBIDDEN` | The recipient has voice messages disabled in their Telegram privacy settings. Rare, and it is their setting, not your bug. |
| Two voice notes in a row and one is wrong | Fixed temp filenames. Every path must carry `{{ $execution.id }}`. |
| `/tmp` fills up over weeks | The `Clean up` node is not running, or not set to always run. |

## The fallback

`demo/09-voice-ask.json` — the whole workflow. Import, set both credentials, put both
`.env` lines in, **restart n8n**, activate.
