# Build the brain's Telegram bot — every step, every command

This is the full build. `PREWORK.md` is the ten-minute version you do before the hour;
this is the complete reference, including the parts we do together in class and every
command you might need afterwards.

Work through it in order. **Section 1 first** — it decides which bot you are building, and
getting that wrong is the one mistake here that is annoying to undo.

---

## 1. You need TWO bots, and this is the one that listens

If you are also running **Content Mate**, you already have a Telegram bot. **Do
not reuse it.** Make a second one.

This is not tidiness. It is a hard limit, and n8n prints it on the trigger node itself:

> *Due to Telegram API limitations, you can use just one Telegram trigger for each bot at
> a time.*

| | **Brain bot** (Class 4 — this one) | **Content Mate bot** |
|---|---|---|
| What it does | **Listens.** You talk to it, it answers | **Speaks only.** Tells you a post went out |
| n8n node | **Telegram Trigger** — receives | Telegram `sendMessage` — sends |
| Who starts the conversation | You | The workflow |
| Registers a webhook on the bot | **Yes** | No |
| Reads your documents | **Yes** | No |

### What breaks if you use one bot for both

| | |
|---|---|
| **A second trigger silently loses updates** | Telegram delivers each update once, to one webhook. Two triggers on one bot means messages vanish — no error, no failed execution, nothing in a log. |
| **Notifications and questions land in the same thread** | Content Mate's "posted to TikTok" messages arrive in the middle of your conversation with your brain. |
| **Your guard fights your notifier** | The brain bot refuses anyone who is not you. That is correct for a brain and pointless for a notifier. One bot cannot sensibly do both. |
| **One revoked token breaks two systems** | `/revoke` on a shared bot takes down your publishing pipeline and your assistant at the same time. |

**Two bots. Two tokens. Two n8n credentials with two different names.** Five extra minutes
now.

### The names to use

Use these exactly. Every prompt, script and error message in this pack assumes them.

| | Brain bot | Content Mate bot |
|---|---|---|
| BotFather name | `My Brain` | `Content Mate` |
| BotFather username | `<yourname>_brain_bot` | `<yourname>_contentmate_bot` |
| n8n credential | **`Brain Bot (Telegram)`** | `Content Mate (Telegram)` |
| `.env` token variable | **`BRAIN_BOT_TOKEN`** | (Content Mate keeps its token in the credential) |
| `.env` owner variable | **`BRAIN_OWNER_ID`** | — |

> **n8n links credentials by NAME when you import a workflow.** If both of yours are called
> the default `Telegram account`, importing one workflow can attach the other bot's token —
> and it will look like it worked. Name them, now, before you have two.

---

## 2. Create the bot with BotFather

Open Telegram. Search **@BotFather** — the official one has a blue check on the account.
Press **Start**.

### 2.1 Make it

Send:

```
/newbot
```

It asks two things, in this order:

| It asks for | You send | Notes |
|---|---|---|
| **name** | `My Brain` | What humans see. Anything. Changeable later. |
| **username** | `yourname_brain_bot` | Unique across all of Telegram, **must end in `bot`**. Expect two or three rejections before one is free. Hard to change later. |

It replies with:

```
Done! Congratulations on your new bot...

Use this token to access the HTTP API:
<a long string that looks like 123456789:AAF...>

Keep your token secure and store it safely.
```

**Copy that token now** and put it where you keep your OpenRouter key from the starter
pack. You can always get it again with `/mybots`, but do it now.

### 2.2 Lock it down while you are here

Four commands. All optional, all worth the ninety seconds — they shrink what a stranger
who finds your bot can do with it.

```
/setjoingroups
```
Choose your bot → **Disable**. Nobody can add your brain to a group chat. There is no
reason for it to be in one, and a bot in a group sees that group's messages.

```
/setprivacy
```
Choose your bot → **Enable**. Belt and braces: even if it somehow ends up in a group, it
only sees messages addressed to it.

```
/setdescription
```
Choose your bot → send something like *"Answers questions about my own documents."* This is
what a stranger sees before they press Start. Say nothing about what documents.

```
/setcommands
```
Choose your bot → send:

```
help - What this bot does
```

Optional, but it makes the bot look finished rather than abandoned.

### 2.3 The BotFather commands worth knowing

| Command | What it does |
|---|---|
| `/newbot` | Create a bot |
| `/mybots` | List yours, and get to every setting including the token |
| `/token` | Show a bot's token again |
| `/revoke` | **Invalidate the token and issue a new one.** Use the moment you think it leaked |
| `/setname` | Change the display name |
| `/setdescription` | The text a stranger sees before pressing Start |
| `/setabouttext` | The short text on the bot's profile |
| `/setjoingroups` | Allow or block adding the bot to groups |
| `/setprivacy` | Whether it sees all group messages or only ones addressed to it |
| `/setuserpic` | Profile picture |
| `/deletebot` | Delete it permanently |

---

## 3. Message your own bot

Search for the username you just made. Open it. Press **Start**. Send it anything —
`hello`.

**Nothing will answer.** That is correct; there is no workflow behind it yet. What matters
is that the conversation now exists, because step 4 reads it.

**Do this from the phone you will actually use.**

---

## 4. Find your chat id — and do it NOW

Your chat id is the number Telegram uses for you. The guard compares against it.

Paste your token into this URL and open it in a browser:

```
https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
```

Note there is no space and no slash between `bot` and the token — it is one string.

Find this in the response:

```json
"chat": { "id": 123456789, "first_name": "...", "type": "private" }
```

**That number is yours.** Write it down.

### The trap: this stops working the moment the workflow goes live

> When n8n's Telegram Trigger activates, it registers a **webhook** on your bot. While that
> webhook is active, `getUpdates` returns:
>
> ```
> 409  Conflict: can't use getUpdates method while webhook is active;
>      use deleteWebhook to delete the webhook first
> ```
>
> **This is not a broken bot and not a bad token.** Telegram will not deliver messages two
> ways at once. It is the correct response, and it means your workflow is working.
>
> Deactivating the trigger normally removes its webhook. Calling Telegram's
> `deleteWebhook` method also removes it and restores `getUpdates`. Two other ways to get
> the id without changing the webhook are:
> - Message **@userinfobot** — it replies with your numeric id and never touches your bot
> - Read the id off the first execution in n8n once the workflow has run

Easiest by far is to do it now, in this order. That is the whole reason `PREWORK.md` puts
this step before anything is built.

---

## 5. Configure the public webhook and private values off camera

A Telegram Trigger needs a **public HTTPS URL**. Telegram cannot call
`http://localhost:5678`, even when n8n works perfectly in your browser. Have a reverse
proxy or tunnel URL ready that reaches this n8n instance.

Keep the Telegram slide deck on the shared screen. In a terminal that is not being
captured, run the script from this pack:

```bash
bash setup-telegram-private.sh --stack ~/brain
```

It reads the public URL, token and owner ID with echo disabled. It stores private values
in `.class-04-private.env` with mode `600`, adds the file to `.gitignore`, creates a
Compose override, and runs `docker compose up -d --force-recreate n8n`.

This override matters. The Class 2 Compose service does not map arbitrary keys from
`.env` into the container, so appending `BRAIN_BOT_TOKEN=...` by itself does **nothing**.
Also, `docker compose restart` does not apply changed Compose configuration.

Check status without printing either value:

```bash
bash setup-telegram-private.sh --stack ~/brain --status
```

The failures caused by a missing value are the two most confusing ones in this class:
>
> | Empty variable | What you see | What it looks like |
> |---|---|---|
> | `BRAIN_OWNER_ID` | The bot ignores **you** | A broken guard |
> | `BRAIN_BOT_TOKEN` | `404 Not Found` from Telegram | A broken URL, or a bad token |
>
> Neither says "the variable is empty". That is why the setup script verifies set/missing
> state and character counts without revealing the values.

### Why the token goes here and not in the workflow

n8n's Telegram node has no `sendVoice` operation — the final reply has to be a plain HTTP
call, and Telegram HTTP calls carry the token **in the URL**. Since you will export and
share this workflow, the URL reads `{{ $env.BRAIN_BOT_TOKEN }}` instead, and the exported
JSON carries the variable's *name*. Same reasoning for your chat id.

---

## 6. Step 0: add the trigger and create its credential

Do this before any audio or AI nodes, and before class if you can; it is also the first
thing built live in the hour. `N8N-TELEGRAM-FIRST.md` is the click-by-click version. In n8n:

1. Create a workflow named **`09 - Voice ask`**.
2. Add a **Telegram Trigger** node.
3. Set **Trigger On** to **Message** only.
4. In **Credential to connect with**, select **Create New Credential**.
5. Choose **Telegram API** if n8n asks for the type.

The setup script has placed the token on your clipboard without printing it. Name the
credential `Brain Bot (Telegram)`, leave Base URL at `https://api.telegram.org`, paste the
token in **Access Token**, and save. Then clear the clipboard:

```bash
bash setup-telegram-private.sh --stack ~/brain --clear-clipboard
```

| Field | Value |
|---|---|
| **Name** | `Brain Bot (Telegram)` — exactly this |
| **Access Token** | Your token |

Save. n8n immediately tests it; a green tick means Telegram accepted it.

Attach the saved credential to Telegram Trigger and save the workflow. **Leave the
workflow inactive.** Activating now would register a public webhook before the owner
guard exists. P1 adds `Is this you?` immediately after the trigger; activation comes only
after that protection and public HTTPS are verified.

This credential does the **trigger** and the **file download**. Only the final `sendVoice`
uses the environment variable.

> The credential cannot do that last call for you. n8n's `TelegramApi` credential defines a
> `test` block and no `authenticate` block — so attaching it to an HTTP Request node as a
> "Predefined Credential Type" injects nothing at all, and the call goes out unauthenticated.
> That was checked by reading n8n's own source, not by guessing.

---

## 7. Build the workflow

Two routes. **Do them in this order if you can** — the prompts teach you what each node is
for, and the import is the safety net.

### Route A — build it with Claude Code (what we do in class)

Run the three prompts in order. Each ends at a milestone you can see on your phone:

| | Prompt | You should be able to |
|---|---|---|
| 1 | `prompts/P1-ears.md` | Send a voice note, get your own words back as text |
| 2 | `prompts/P2-ask.md` | Send a voice note, get the answer as text with its source |
| 3 | `prompts/P3-voice.md` | Send a voice note, **hear** the answer |

**Stop and test after each one.** A broken P1 that you only discover during P3 is three
times harder to find.

### Route B — import the finished workflow

n8n → **Workflows → Import from File** → `demo/09-voice-ask.json`.

Then, before activating:

1. Open the **Telegram Trigger** and attach `Brain Bot (Telegram)`
2. Open the **Telegram** download node and attach the same credential
3. Open both **OpenRouter** HTTP nodes and attach your `OpenRouter` Header Auth credential
4. Check the `Ask the brain` node points at `http://localhost:5678/webhook/ask`

The import carries **no credentials and no ids**. It cannot: they were stripped before it
was packaged.

---

## 8. Activate, and understand what activation does

Toggle the workflow **Active** in the top right.

**That toggle is what tells Telegram where to send your messages.** Until you flip it, your
bot is completely dead — no reply, no error, no execution, nothing in any log.

Confirm Telegram agrees:

```
https://api.telegram.org/bot<YOUR_TOKEN>/getWebhookInfo
```

```json
{ "ok": true, "result": { "url": "https://.../webhook/...", "pending_update_count": 0 } }
```

| What `url` says | Meaning |
|---|---|
| A URL ending in your n8n webhook path | Correct. Telegram is delivering to n8n. |
| `""` (empty) | No webhook registered — the workflow is not Active. |
| Someone else's URL | This bot is wired to a different n8n. `deleteWebhook`, then re-activate. |

A rising `pending_update_count` means Telegram is trying to deliver and failing — your n8n
is not reachable at that URL.

---

## 9. Test it, in this order

| # | Send | Expect |
|---|---|---|
| 1 | A voice note, from you | The answer as text, then a **voice note** |
| 2 | A text message, from you | *"Send me a voice note and I'll answer out loud."* |
| 3 | Anything, **from a second account** | **Nothing at all.** One green execution that stops at `Is this you?` |
| 4 | *"What is my dog's name?"*, out loud | *"I don't have that in your documents."* |

**Test 3 is not optional.** Your bot's username is public and searchable, and it is wired
to a brain that has read your lease and your invoices. Until you have watched it refuse
someone, you do not know that it does.

Then run the preflight and the real acceptance test:

```bash
bash verify.sh
```

`VERIFY.md` has the check that actually proves the audio is speech and not a
plausibly-sized file full of static.

---

## 10. Command reference

Everything in one place.

### Telegram API — paste in a browser, or `curl`

Replace `<YOUR_TOKEN>` with your token. There is no space and no slash after `bot`.

| Purpose | URL |
|---|---|
| Is the token valid? | `https://api.telegram.org/bot<YOUR_TOKEN>/getMe` |
| Find your chat id | `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates` |
| Is a webhook registered, and where? | `https://api.telegram.org/bot<YOUR_TOKEN>/getWebhookInfo` |
| Remove the webhook (unblocks `getUpdates`) | `https://api.telegram.org/bot<YOUR_TOKEN>/deleteWebhook` |
| Send yourself a test message | `https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage?chat_id=<YOUR_ID>&text=hello` |

> **`deleteWebhook` un-registers your live workflow.** `getUpdates` starts working again and
> your bot stops answering. Re-activate the workflow in n8n to put it back. Use it to get
> unstuck, not as a habit.

### Docker — run from your stack folder

| Purpose | Command |
|---|---|
| Apply private setup and recreate n8n | `bash setup-telegram-private.sh --stack ~/brain` |
| Verify token and owner state without values | `bash setup-telegram-private.sh --stack ~/brain --status` |
| Copy token without displaying it | `bash setup-telegram-private.sh --stack ~/brain --copy-token` |
| Clear copied token | `bash setup-telegram-private.sh --stack ~/brain --clear-clipboard` |
| Is env access allowed in nodes? | `docker compose exec n8n printenv N8N_BLOCK_ENV_ACCESS_IN_NODE` |
| Does the container have ffmpeg? | `docker compose exec n8n ffmpeg -version` |
| Can it encode opus? | `docker compose exec n8n ffmpeg -hide_banner -encoders \| grep opus` |
| Can it reach Telegram? | `docker compose exec n8n node -e "fetch('https://api.telegram.org').then(r=>console.log(r.status))"` |
| Watch it work in real time | `docker compose logs -f n8n` |
| Is n8n healthy? | `curl http://localhost:5678/healthz` |
| Is Class 3 still answering? | `curl -X POST http://localhost:5678/webhook/ask -H 'Content-Type: application/json' -d '{"question":"test"}'` |

`N8N_BLOCK_ENV_ACCESS_IN_NODE` must be `false` or unset. The starter pack's installer sets
it. If it is `true`, `{{ $env.BRAIN_BOT_TOKEN }}` renders as an empty string and the
`sendVoice` URL becomes `/bot/sendVoice` — a `404` that has nothing to do with your token.

### The workflow, node by node

What `demo/09-voice-ask.json` contains, so you can check yours against it:

| # | Node | Type | Does |
|---|---|---|---|
| 1 | `Telegram Trigger` | `telegramTrigger` | Receives. **`Trigger On: message` only** |
| 2 | `Is this you?` | `code` | Compares sender against `$env.BRAIN_OWNER_ID`. Returns `[]` for anyone else |
| 3 | `Get the voice note` | `telegram` | `resource: file`, `operation: get`, `download: true` |
| 4 | `Save the ogg` | `readWriteFile` | Writes `/tmp/voice-{{ $execution.id }}.ogg` |
| 5 | `ogg to mp3` | `executeCommand` | ffmpeg, 16 kHz mono |
| 6 | `Read the mp3` | `readWriteFile` | Reads it back as binary |
| 7 | `To base64` | `code` | `getBinaryDataBuffer` → base64 |
| 8 | `Transcribe` | `httpRequest` | OpenRouter `input_audio`, `format: mp3` |
| 9 | `Read the transcript` | `code` | Pulls the text, flags an empty one |
| 10 | `Ask the brain` | `httpRequest` | **Class 3's `/webhook/ask`, untouched** |
| 11 | `Shape the reply` | `code` | Splits answer / sources / combined text |
| 12 | `Speak it` | `httpRequest` | `pcm16` + `stream: true`, **Response Format: text** |
| 13 | `Reassemble the audio` | `code` | Parses SSE, concatenates base64, decodes **once** |
| 14 | `Save the pcm` | `readWriteFile` | `/tmp/answer-{{ $execution.id }}.pcm` |
| 15 | `To a voice note` | `executeCommand` | ffmpeg `-f s16le -ar 24000 -ac 1` → ogg/opus |
| 16 | `Read the ogg` | `readWriteFile` | Reads it back |
| 17 | `Send the text` | `telegram` | `sendMessage` — the answer and its source |
| 18 | `sendVoice` | `httpRequest` | `api.telegram.org/bot{{ $env.BRAIN_BOT_TOKEN }}/sendVoice`, multipart |
| 19 | `Clean up` | `executeCommand` | `rm -f` both temp files |

---

## 11. Optional: the trigger can filter for you too

The Telegram Trigger has **Additional Fields → Restrict to Chat IDs**. Put your id there
and Telegram updates from anyone else never create an execution at all.

Worth doing as a second layer — but know the trade:

| | Code guard (`Is this you?`) | Trigger's Restrict to Chat IDs |
|---|---|---|
| Where the id lives | `$env.BRAIN_OWNER_ID` | **Typed into the workflow** |
| Survives export/sharing | Yes — the JSON carries the variable name | **No — your id ships with the file** |
| Refusal visible in the execution log | Yes | No execution is created |

Use both if you like. **The Code node stays the primary**, because it is the one that keeps
your chat id out of a file you are going to share. If you fill in Restrict to Chat IDs,
clear it before you export the workflow for anyone.

---

## 12. When it goes wrong

| What you see | What it means | Fix |
|---|---|---|
| BotFather: *"Sorry, this username is already taken"* | Someone has it | Try another. Must end in `bot` |
| `getUpdates` → `{"ok":true,"result":[]}` | You have not messaged the bot, or it was over 24 h ago | Telegram keeps updates one day. Message it again |
| `409 Conflict ... webhook is active` | **Correct.** Your workflow is live | Use `@userinfobot`, or read the id from an execution |
| `401 Unauthorized` | The **token** is wrong or revoked | Check it with `/mybots`. `/revoke` if it leaked |
| `404 Not Found` from `api.telegram.org` | The **URL** — the token was never read | Missing `bot` prefix, **or an empty `BRAIN_BOT_TOKEN`** |
| Bot never answers, no execution in n8n | Not **Active** | Toggle it. Confirm with `getWebhookInfo` |
| Bot ignores **you** | `BRAIN_OWNER_ID` empty in the container | Run private setup and check `--status` |
| A **stranger** gets a reply | The guard is not first, or is comparing wrong | Stop and fix before anything else |
| Messages vanish, no error anywhere | Two Telegram Triggers on one bot | Section 1. Give Content Mate its own bot |
| `getWebhookInfo` shows a URL you do not recognise | The bot is wired to another n8n | `deleteWebhook`, then re-activate here |
| `pending_update_count` climbing | Telegram cannot reach your n8n | Check the tunnel or the webhook URL n8n registered |
| Voice note arrives as a music player | The Telegram node's `sendAudio` was used | There is no `sendVoice` operation — it must be the HTTP Request node |

Post the **exact error text** in the class thread — the wording is the diagnosis. **Never
post your token.** If you already did, `/revoke` immediately; it takes ten seconds and the
old token dies instantly.

---

## 13. If you ever need to start over

| To | Do |
|---|---|
| Get a new token, keep the bot | BotFather → `/revoke`. Update `.env` **and** the n8n credential, restart |
| Unhook it from n8n | `getWebhookInfo` to see it, `deleteWebhook` to clear it, or deactivate the workflow |
| Move it to a different n8n | Deactivate on the old one first, or the two fight over the same updates |
| Delete it entirely | BotFather → `/deletebot`. Permanent. The username is not released for reuse |

---

*The Brain That Runs a Company — Class 4. Orbix Automation Solutions.*
