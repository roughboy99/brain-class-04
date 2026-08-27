# Class 4 — do this before the hour

**Time: about 10 minutes. Cost: nothing, and no card.**

Class 4 gives your brain ears and a voice: you send a voice note from your phone, and it
answers out loud from your own documents.

To do that it needs a Telegram bot of your own. Making one is the only thing you have to
set up in advance, and it is genuinely quick — but there is one ordering trap in it that
will waste your afternoon if you hit it blind, so read to the end before you start.

> **This is the full ten-minute version.** `BUILD-THE-BOT.md` in this pack is the complete
> reference — every BotFather command, every diagnostic URL, and the whole workflow node by
> node. You do not need it before the hour. You will want it afterwards.

---

## Already running Content Mate? Make a SECOND bot.

If you run Content Mate you already have a Telegram bot that tells you when a post went out.
**Do not reuse it here.** Make a new one.

n8n prints the reason on the trigger node itself: *"Due to Telegram API limitations, you
can use just one Telegram trigger for each bot at a time."* Telegram delivers each message
once, to one place. Point two workflows at one bot and messages start vanishing — with no
error, no failed execution and nothing in any log.

| | **Brain bot** (this class) | **Content Mate bot** |
|---|---|---|
| What it does | **Listens** — you talk to it | **Speaks** — it notifies you |
| Registers a webhook | **Yes** | No |
| Reads your documents | **Yes** | No |

Two bots, two tokens, and **two n8n credentials with different names** — call this one
`Brain Bot (Telegram)`. n8n links credentials by name when you import a workflow, so two
called `Telegram account` will eventually attach the wrong token to the wrong workflow and
look like it worked.

---

## Before you begin

| You need | Check |
|---|---|
| The starter pack done | `bash verify.sh` says **Ready** |
| Class 3 working | Your dashboard's **Ask** tab answers a question about your documents |
| Telegram installed | On your phone. The desktop app alone is not enough — you need to record voice notes. |

If the Ask tab does not answer, fix that first. Class 4 does not build a new brain; it
plugs a phone into the one you already have. If that one is not answering, this cannot.

---

## Step 1 — Create your bot

In Telegram, search for **@BotFather** and open it. It is the official bot that makes bots;
the blue check mark is on the account.

1. Send `/newbot`
2. It asks for a **name** — what humans see. Anything: `My Brain`
3. It asks for a **username** — must be unique across all of Telegram and must end in
   `bot`. Try `yourname_brain_bot`. Expect a couple of rejections before one is free.
4. It replies with a line like:

   ```
   Use this token to access the HTTP API:
   8114247238:AAF...........................
   ```

**That token is a password.** Anyone who has it controls your bot completely.

- Do not paste it in a chat, a screen share, a prompt, or the class thread
- Do not type it into a workflow node — in n8n it goes into a **credential**, so that
  exported workflows carry the credential's *name* and never its value
- If you ever leak it, send `/revoke` to BotFather and get a new one

Keep it where you keep the OpenRouter key from the starter pack.

---

## Step 2 — Send your bot a message

Search for the username you just made, open it, and press **Start**. Then send it anything
— `hello` is fine.

Nothing will answer. That is correct: there is no workflow behind it yet. What matters is
that the conversation now exists, which is what Step 3 needs.

**Do it from the phone you will use in class.**

---

## Step 3 — Find your chat id, and do it NOW

Your chat id is the number Telegram uses for *you*. Class 4 needs it, for the reason in
Step 4.

Open this in a browser, with your token pasted in place of `YOUR_TOKEN`:

```
https://api.telegram.org/botYOUR_TOKEN/getUpdates
```

Find `"chat":{"id":123456789,` — that number is yours. Write it down.

> ### The trap: do this before you build the workflow
>
> Once n8n's Telegram Trigger is active, it registers a **webhook** on your bot, and from
> that moment `getUpdates` stops working forever:
>
> ```
> 409  Conflict: can't use getUpdates method while webhook is active
> ```
>
> This is not a broken bot and not a broken token. Telegram simply will not deliver
> messages two ways at once. If you already hit it, you have two options: message
> **@userinfobot**, which just replies with your numeric id and never touches your bot; or
> read the id off the first execution in n8n once the workflow runs.
>
> Easiest by far is to do it now, in this order.

---

## Step 4 — Understand what you are about to connect

This is the part I would rather say plainly than have you discover.

**A Telegram bot is public.** Its username is searchable by anyone on Telegram. Nothing
stops a stranger finding yours and sending it a message.

In Class 4, that bot is wired to a brain that has read your insurance policy, your lease,
your invoices — whatever you fed it in Class 3. A bot that answers *anyone* is a bot that
reads your documents to *anyone*.

**So the workflow checks who is asking.** The first thing it does with an incoming message
is compare the sender's chat id against yours, and it refuses anything else. That is why
Step 3 exists, and it is not optional — it is the difference between a private assistant
and a public leak.

We will build that check together and I will show you what it looks like when it refuses.

If you would rather not put business documents behind a public username at all, that is a
completely reasonable position and there is a path for you: `docs/UPGRADE-mic.md` in the
pack does the same thing through your dashboard instead. It needs HTTPS and it is more
work. Bring the question to the hour.

---

## What to have ready on the day

- [ ] Bot created, token saved somewhere safe
- [ ] You pressed **Start** and sent it a message
- [ ] Your chat id written down
- [ ] Class 3's Ask tab answering questions
- [ ] Telegram on your phone, signed in
- [ ] One question you actually want to ask your documents out loud

That last one is the point of the hour. Bring a real one.

---

## If something goes wrong

| What you see | What it means |
|---|---|
| BotFather: *"Sorry, this username is already taken"* | Someone has it. Try another; it must end in `bot`. |
| `getUpdates` shows `{"ok":true,"result":[]}` | You have not messaged the bot yet, or it was more than 24 hours ago. Telegram only keeps updates for a day. Send it another message. |
| `409 Conflict ... webhook is active` | See the trap in Step 3. Use **@userinfobot** instead. |
| `401 Unauthorized` | The **token** is wrong — a dropped or extra character, or it was revoked. |
| `404 Not Found` | The **URL** is wrong, not the token. Almost always the word `bot` missing in front of it: it is `/bot<TOKEN>/getUpdates`, all one string, no space. |
| The bot never answers anything | Expected until we build the workflow in class. |

> Those two look alike and are not. **401 means Telegram read your token and rejected it.
> 404 means Telegram never found the endpoint to check it against.** If you go hunting for
> a bad character on a 404 you will not find one, because the token was never the problem.

Post the exact error text in the thread if you are stuck — the wording is the diagnosis.
Never post the token itself.

---

*The Brain That Runs a Company — Class 4. Orbix Automation Solutions.*
