# Upgrade — talk to it from the dashboard instead of Telegram

**Who this is for:** you do not want your business documents sitting behind a bot whose
username anyone on Telegram can search for.

That is a reasonable position, not an edge case. This is the path.

**What you give up:** you can only talk to it from a browser on a machine you are at.
Telegram works from anywhere, on a phone, without a VPN.

**What you gain:** nothing is publicly addressable. There is no bot, no username, no
token, and nothing to guard against.

---

## Why this was not the main path

One hard technical fact.

**`getUserMedia` — the browser API that turns on a microphone — only runs in a secure
context.** So does the Web Speech API. A secure context means:

| Origin | Microphone |
|---|---|
| `https://anything` | works |
| `http://localhost:8088` | works — localhost is trusted by definition |
| `http://127.0.0.1:8088` | works |
| `http://192.168.x.x:8088` or any other machine's address | **blocked** |
| `file:///.../dashboard.html` | **unreliable** — treated differently by Chrome, Firefox and Safari; do not build on it |

The class dashboard is reached at the stack's address on your network, which is the row
that fails. And it fails **silently**: the button does nothing, `navigator.mediaDevices`
is simply `undefined`, and there is no error a member can see.

Fixing that means solving HTTPS first — which is a segment about transport security in the
middle of a class about voice. So Telegram carries the class, and this carries the people
who want it.

---

## The one case where you need none of this

**If n8n and Postgres run on the same machine you are sitting at**, open the dashboard at
`http://localhost:8088` rather than at the machine's network address, and the microphone
works with no further setup at all.

Check the address bar before you do anything else in this document. If it says `localhost`
or `127.0.0.1`, skip to section 3.

Most members are in this situation and do not realise it, because they got into the habit
of using the machine's LAN address so their phone could reach it too.

---

## 1. Pick a route to a secure context

Three, cheapest first.

### A. An SSH tunnel — free, nothing installed, nothing exposed

If the stack is on another box you can SSH to, forward its port to your own machine:

```bash
ssh -L 8088:localhost:8088 -L 5678:localhost:5678 you@your-box
```

Now `http://localhost:8088` in your browser reaches the remote dashboard **and counts as
localhost**, because as far as the browser is concerned it is. The microphone works.

Forward `5678` as well or the dashboard's calls to n8n will fail — it will be asking your
own laptop for a webhook that lives on the box.

**Best option for most people.** No certificate, no public address, nothing to renew, and
it stops existing the moment you close the terminal.

### B. A Cloudflare tunnel — real HTTPS, reachable from anywhere

`cloudflared` gives the dashboard a real certificate on a real hostname without opening a
port on your router.

**Put access control in front of it.** A dashboard on the public internet with no
authentication is strictly worse than the Telegram bot you were avoiding — the bot at
least checks a chat id. Cloudflare Access with a one-time PIN to your own email is the
minimum, and it is free.

### C. A self-signed certificate — works, and you will hate it

Generate a certificate, serve the dashboard over TLS, click through the browser warning
every time, and add a permanent exception. Chrome and Firefox will keep reminding you.

It works. It is the option to take when A and B are both impossible.

---

## 2. Add the microphone

Once the dashboard is on a secure origin, the Ask tab needs a record button. This prompt
assumes the Class 3 dashboard.

```text
My dashboard's Ask tab posts { "question": "..." } to
http://localhost:5678/webhook/ask and renders { answered, answer, sources }.

The page is now served from a secure context, so getUserMedia is available.

Add a microphone button beside the question box:

1. On press: navigator.mediaDevices.getUserMedia({ audio: true }), then MediaRecorder.
   Record while held (or toggle - your call, but tell me which you chose and why).

2. On release: stop, collect the Blob, and POST it as base64 to a NEW n8n webhook on
   path `transcribe`, which does exactly what Class 4's P1 does after the download -
   ffmpeg to 16 kHz mono mp3, then OpenRouter input_audio - and returns
   { "transcript": "..." }.

3. Put the transcript in the question box as editable text. Do NOT send it straight to
   /ask. Transcription gets names and numbers wrong, and a question you can see before
   it is asked is a question you can fix. This is the main advantage the dashboard has
   over the phone; do not throw it away for one less click.

4. Then the existing Ask flow runs unchanged.

5. Feature-detect and say so out loud: if navigator.mediaDevices is undefined, hide the
   button and show "Microphone needs https:// or localhost - see docs/UPGRADE-mic.md".
   A dead button with no explanation is the failure this whole document exists because of.

Handle the permission denial explicitly. A user who clicks Block once gets no prompt
ever again, and the promise just rejects.
```

**Do not use the Web Speech API** (`webkitSpeechRecognition`) instead. It is
Chrome-and-Safari only, it ships your audio to the browser vendor rather than to the model
you chose, and its accuracy on names and numbers is worse than the transcription you are
already paying fractions of a cent for.

---

## 3. Hearing the answer back

Two options, and the cheap one is genuinely fine.

**The browser's own voice — free, instant, no API call:**

```js
speechSynthesis.speak(new SpeechSynthesisUtterance(answer));
```

Every desktop browser has this. It sounds like a satnav. It costs nothing, adds no
latency, and for reading two sentences back to yourself it is honestly enough.

**The Class 4 voice — the good one:** reuse `prompts/P3-voice.md` exactly as written, up
to and including the ffmpeg step, but instead of `sendVoice`, return the ogg from a
`Respond to Webhook` node and play it in an `<audio>` element. Both traps in P3 apply
unchanged — `pcm16` with `stream: true`, and concatenate the base64 before decoding.

---

## What is verified here and what is not

**Verified:** the secure-context requirement, and that the class dashboard's origin fails
it. That is why this document exists.

**Not verified:** none of the code in this document has been built and run. The Telegram
path in the main pack was measured end to end against the live stack; this one is a
correct design that nobody has stood up yet.

If you build it, post what broke in the class thread. It becomes the next version of this
file.
