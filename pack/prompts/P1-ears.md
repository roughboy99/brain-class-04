# P1 — Give it ears

**What it builds:** a Telegram bot that refuses strangers, takes a voice note from your
phone, and repeats your own words back to you as text.

**Before you run it:** `PREWORK.md` and `N8N-TELEGRAM-FIRST.md` are done — bot created,
private setup complete, Telegram Trigger already on the canvas, and the credential named
`Brain Bot (Telegram)` has tested successfully. The workflow is still inactive.

**Milestone:** you speak into your phone, and text comes back. That is already useful. If
the rest of the hour goes badly, you still have this.

> **The guard is node two, not a footnote.** Your bot's username is public. Before this
> workflow transcribes anything, it checks who is asking. Build it in that order and you
> will never have a window where it is wired to your documents and open to the world.

---

## The prompt

```text
I have n8n on port 5678, self-hosted in Docker, with ffmpeg available inside the
container. I have a Telegram bot token and my own numeric chat id.

Continue my existing inactive n8n workflow called `09 - Voice ask`. It already contains
a Telegram Trigger with Trigger On = Message and the tested credential
`Brain Bot (Telegram)`. Do not create a second workflow or credential. In this first pass
it goes as far as transcribing a voice note and replying with the transcript as text. Shape:

  Telegram Trigger -> Code (Is this you?) -> Telegram (download the voice note)
    -> Read/Write File (write) -> Execute Command (ffmpeg) -> Read/Write File (read)
    -> Code (to base64) -> HTTP Request (transcribe) -> Code (read the transcript)
    -> Telegram (send the transcript back)

1. Telegram Trigger node:
   - Updates: `message` only. Not `*`. Every other update type produces executions
     that do nothing and make the execution list unreadable.
   - Reuse the existing `Brain Bot (Telegram)` credential. Do NOT type the token into
     any node parameter and do not create a duplicate credential.

2. Code node called `Is this you?`. This runs FIRST, before anything is downloaded.
   - Read the owner id from an environment variable, not from a literal:
     const owner = String($env.BRAIN_OWNER_ID || '').trim();
   - const msg = $input.first().json.message;
   - If String(msg.from.id) !== owner OR String(msg.chat.id) !== owner, return []
     - an empty array. Returning no items stops the branch: nothing downstream runs,
     nothing is transcribed, and the stranger gets no reply at all. Silence is the
     correct response - an error message would confirm the bot is live.
     Before returning [], console.log the sender's id and username so the refusal is
     visible in the execution log.
   - If msg.voice is missing, the member sent text rather than a voice note. Pass it
     through on a second output (or set a flag) so we can reply "send me a voice note"
     rather than silently ignoring them. A stranger gets silence; the owner never does.
   - Otherwise return the item unchanged.
   Put the reason for the empty-array refusal in the node's notes, not just in chat.

3. Telegram node, resource `File`, operation `Get`:
   - File ID: the voice file id from the trigger message.
   - Turn ON the option that downloads the file, so the audio comes back as binary.
   - Same `Brain Bot (Telegram)` credential. Downloading is native; the token stays in
     the credential.

4. Read/Write File node, operation `Write`:
   - File Name: /tmp/voice-{{ $execution.id }}.ogg
   - Use the execution id in EVERY temp filename in this workflow. A fixed name like
     /tmp/voice.ogg breaks the first time two voice notes arrive close together: the
     second execution overwrites the first one's audio mid-flight. It does not error.
     It sends the wrong answer.

5. Execute Command node called `ogg to mp3`:

   ffmpeg -y -hide_banner -loglevel error -i /tmp/voice-{{ $execution.id }}.ogg \
     -ar 16000 -ac 1 -b:a 48k /tmp/voice-{{ $execution.id }}.mp3

   A Telegram voice note is ogg/opus. We convert it to 16 kHz mono mp3 before
   transcribing. Explain in the node notes that this is deliberate: mp3 is the format
   this path was actually measured on, and ffmpeg is already in the container, so the
   conversion is free and removes a guess.

6. Read/Write File node, operation `Read`, on the .mp3 you just produced.

7. Code node `To base64`:
   - const buf = await this.helpers.getBinaryDataBuffer(0, 'data');
   - return [{ json: { audio: buf.toString('base64'),
                       chatId: <the chat id carried down from the trigger> } }];
   - Carry the chat id forward explicitly. Do not reach back to the trigger node from
     the last node in the chain - when you add branches later it stops resolving.

8. HTTP Request node `Transcribe`:
   - POST https://openrouter.ai/api/v1/chat/completions
   - Authentication: Generic -> Header Auth -> the existing `OpenRouter` credential
     from Class 1. Never put the key in a node parameter.
   - JSON body:
     {
       "model": "google/gemini-2.5-flash",
       "messages": [{
         "role": "user",
         "content": [
           { "type": "text",
             "text": "Transcribe this audio verbatim. Output only the transcript, with no commentary." },
           { "type": "input_audio",
             "input_audio": { "data": "<the base64 from step 7>", "format": "mp3" } }
         ]
       }]
     }
   - Timeout 120000.

9. Code node `Read the transcript`:
   - Pull choices[0].message.content and trim it.
   - If it is empty, or shorter than two characters, return a transcript of
     "" and a flag heard: false. An empty transcript must not be passed on as a
     question - downstream it becomes an empty query that retrieves noise.

10. Telegram node, `Send Message`:
    - Chat ID: the one carried down, not a literal.
    - Text: the transcript if heard, otherwise "I couldn't make that out - try again?"
    - For the text-message branch from step 2: "Send me a voice note and I'll answer
      out loud."

Save it. Before activation, confirm `Is this you?` is directly after Telegram Trigger,
private setup `--status` passes, and n8n has the intended public HTTPS webhook URL. Then
activate it. A Telegram Trigger only registers its webhook with Telegram when the
workflow is Active - inactive, your bot will appear completely dead.

Then tell me exactly what to send from my phone to test it, and what I should see in
the execution list for each of: my own voice note, my own text message, and a message
from someone who is not me.
```

---

## Before you run it: private setup must be complete

The guard reads your chat id from the environment so it never appears in an exported
workflow. Run the pack's private setup in a terminal that is not being shared:

```bash
bash setup-telegram-private.sh --stack ~/brain
```

The script loads the value through a Compose override and recreates n8n. Appending a key
to the Class 2 `.env` alone does not inject it into the service, and a plain Compose
restart does not apply environment changes. If `$env.BRAIN_OWNER_ID` is empty, the guard
compares your id against `''`, refuses **you**, and your bot looks broken.

That failure is silent by design. Check it deliberately:

```bash
bash setup-telegram-private.sh --stack ~/brain --status
```

If that reports missing, rerun private setup.

---

## What correct looks like

**Send your bot a voice note saying "testing one two three".**

Within about three seconds, the bot replies:

```
testing one two three
```

In n8n's execution list: one execution, all green.

**Send your bot a text message.**

```
Send me a voice note and I'll answer out loud.
```

**Have someone else message your bot** — or use a second Telegram account.

Nothing comes back. In the execution list there is an execution, it is green, and it
stops at `Is this you?`. Open it: the Code node's log shows the id that was refused, and
no node after it ran.

> **That green execution that does nothing is the whole security model.** It is worth
> looking at once, on purpose, so you know what it looks like.

---

## Why the refusal is silence

An error message back to a stranger tells them there is something live behind the
username. Silence tells them nothing. A bot that has never been messaged and a bot that
refused them look identical from outside.

That is not paranoia about a hobby project — it is the same reason your Class 3 brain says
*"I don't have that in your documents"* instead of guessing. The system's behaviour at the
edges is the part you have to be able to trust.

---

## If it goes wrong

| What you see | What it means |
|---|---|
| Nothing happens at all, and no execution appears | The workflow is **not Active**. The trigger's webhook is only registered on activation. |
| `409 Conflict: can't use getUpdates` in a browser | Correct and expected once the trigger is live. Telegram will not deliver two ways at once. Your chat id comes from `PREWORK.md`, or from `@userinfobot`. |
| The bot refuses **you** | `BRAIN_OWNER_ID` is empty in the container. Run private setup again and check `--status`. |
| `401 Unauthorized` from Telegram | The **token** is wrong or was revoked. |
| `404 Not Found` from Telegram | The **URL** is wrong, not the token — the token was never read. In n8n's own Telegram node this almost always means the credential is empty. |
| Execute Command node: `command not found` | ffmpeg is not in your n8n image. Check with `docker compose exec n8n ffmpeg -version`. The starter pack's image includes it. |
| ffmpeg: `No such file or directory` | The Write node and the Execute Command node disagree about the filename. Both must use `{{ $execution.id }}`, and both must be `/tmp`. |
| Read/Write File: an **access error** on `/tmp` | Your n8n restricts which paths that node may touch (`N8N_RESTRICT_FILE_ACCESS_TO`). Move every file path in the workflow under `/home/node/` — the Write nodes, the Read nodes and both ffmpeg commands, or they will disagree. |
| Transcript comes back as a description of the audio | The model was asked to *describe* rather than transcribe. Check the text part of the message — it must say *transcribe verbatim, output only the transcript*. |
| `404` from OpenRouter | The model slug is retired. This has happened to `google/gemini-2.0-flash-001` already. Check the current slug on OpenRouter's models page. |
| The transcript is empty every time | The audio never made it. Open the execution, look at the Read node's binary output — if it is 0 bytes, ffmpeg wrote nothing and its stderr will say why. |

## The fallback

`demo/09-voice-ask.json` — import it, set both credentials, add both `.env` lines, restart,
activate.
