# P2 — Hand it to the brain

**What it builds:** the transcript from P1 goes to your Class 3 `/ask` webhook, and the
answer comes back to your phone as text, with the document it came from.

**Before you run it:** P1 works — you speak, and your words come back as text.

**Milestone:** you ask a question out loud and get a real answer from your own documents.
Still text, but the brain is now doing the thinking.

> **Nothing in Class 3 gets opened.** You are calling the `/ask` webhook exactly the way
> your dashboard already calls it. If this step fails, the very first question is *"does
> the Ask tab still work?"* — and that answer tells you which half to look in.

---

## The prompt

```text
Continue the `09 - Voice ask` workflow. It currently transcribes a voice note and
replies with the transcript. Now put the Class 3 brain in the middle.

I already have a Class 3 workflow with a Webhook node on path `ask`, active, which
takes { "question": "..." } and returns:

  { "answered": true|false, "answer": "...", "sources": ["file.md"] }

Insert between `Read the transcript` and the Telegram send:

  Code (Read the transcript) -> IF (did we hear anything?)
       -> HTTP Request (Ask the brain) -> Code (Shape the reply) -> Telegram

1. IF node `Did we hear anything?`:
   - If the transcript is empty or the heard flag is false, go straight to the Telegram
     send with "I couldn't make that out - try again?" and never call the brain.
     An empty question is not a cheap query, it is a meaningless one: it retrieves
     whatever is nearest to nothing and the model answers it confidently.

2. HTTP Request node `Ask the brain`:
   - POST http://localhost:5678/webhook/ask
   - JSON body:
     {
       "question": {{ JSON.stringify(String($json.transcript ?? '')) }}
     }
     Do not put quotes around the expression. `JSON.stringify` supplies the quotes and
     safely escapes spoken quotation marks, newlines and backslashes. Raw interpolation
     breaks the request as soon as a transcript contains one of those characters.
   - Timeout 60000.
   - No credential. This is your own stack talking to itself.

   Use `localhost`, not your machine's LAN address and not the box's hostname. This
   node runs INSIDE the n8n container, where localhost:5678 is n8n itself. A LAN
   address may work today and stops working the moment the stack moves, and it drags
   the request out onto the network and back for no reason.

   Use /webhook/ask and NOT /webhook-test/ask. The test URL only exists while you have
   the Class 3 editor open with "Listen for test event" running. It works while you are
   watching and fails the moment you close the tab, which is the worst possible failure
   mode to debug.

3. Code node `Shape the reply`:
   - Pass the answer through UNCHANGED when answered is false. Class 3's refusal
     sentence is "I don't have that in your documents." Do not rewrite it, do not
     soften it, do not add "but I could look it up". The refusal is the feature; a
     reply that apologises its way around it is a reply that has started guessing.
   - When answered is true, build the text as the answer followed by the source
     filenames on their own line, e.g.:
       The security deposit is $7,700, equal to two months of base rent.
       (warehouse-lease.md)
   - Keep the answer itself and the source list as separate fields as well as the
     combined text. P3 speaks the answer and must not read the filename out loud.

4. Telegram Send Message: send the combined text.

Then tell me how to confirm, from the phone, that a question my documents CANNOT
answer comes back as the refusal and not as an invention.
```

---

## What correct looks like

**Ask something your documents answer.** Say out loud:

> *"How much is the security deposit on the warehouse?"*

```
The security deposit is $7,700, equal to two months of base rent.
(warehouse-lease.md)
```

**Ask something they do not.** Say out loud:

> *"What is my dog's name?"*

```
I don't have that in your documents.
```

**If the second one comes back with a name in it, stop.** Something is wrong in Class 3 —
your threshold or your system message — and every answer it has given you is now suspect.
It is not a Class 4 problem and no amount of work here will fix it.

---

## Why the answer and the source stay separate

P3 turns the answer into speech. Hearing *"the security deposit is seven thousand seven
hundred dollars"* is the point. Hearing *"open paren warehouse dash lease dot em dee close
paren"* is not.

So `Shape the reply` produces three things: the answer, the sources, and the combined text
for the message bubble. P3 speaks the first and shows the third. Splitting it now costs
nothing; splitting it later means unpicking a string.

---

## If it goes wrong

| What you see | What it means |
|---|---|
| `404` from `Ask the brain` | The Class 3 workflow is saved but not **Active**. The production webhook does not exist until it is. |
| It worked in testing, then stopped | You used `/webhook-test/ask`. That URL only lives while the Class 3 editor is listening. Change it to `/webhook/ask`. |
| `ECONNREFUSED` on localhost:5678 | You are pointing at something other than n8n, or n8n is not on 5678 inside the container. `docker compose exec n8n printenv N8N_PORT`. |
| The answer is always the refusal | Class 3's retrieval is not finding anything. Test the Ask tab directly with the same question — if it also refuses, the problem is there. |
| The answer is right but no source | Class 3 returned `sources: []`. That happens on a refusal, and it happens if the Parse node did not carry them. Check the raw response in the execution. |
| Very long answers | Class 3's system message caps it at two sentences. If yours does not, cap it before P3 — you pay for every second of speech, and nobody wants a ninety-second voice note. |

## The fallback

`demo/09-voice-ask.json` contains the whole finished workflow, P1 through P3.
