# Step 0 — Telegram Trigger and its credential, in n8n

**Do this before class, right after the private setup.** It is also the first thing built
live at the top of the hour, so anyone who arrives without it catches up in five minutes.
Its job is narrow: prove that n8n accepts your bot token, and leave the token where an
exported workflow cannot carry it. No audio, no AI, nothing active.

Video 0 in the pinned post shows every click below, on a throwaway bot.

## Why a credential and not a node field

n8n stores credentials encrypted, separately from workflows. A workflow export carries the
credential's **name**, never its value. Type the token into a node parameter instead and it
ships inside the JSON the first time you export, share, or paste the workflow into the
community asking for help.

The name matters because n8n links credentials **by name** when a workflow is imported.
The prompts and the study workflow all look for exactly `Brain Bot (Telegram)`. A second
credential called `Telegram account` will look right and attach the wrong token.

## 1. Create the workflow shell

1. In n8n, open **Overview** and select **Create Workflow**.
2. Click the name at the top left and rename it **`09 - Voice ask`**.
3. Click **+** (or the **Add first step** tile), search **Telegram Trigger**, select it.
4. Set **Trigger On** to **Message** only.

Do **not** activate the workflow. Activation registers a public webhook on your bot, and the
owner guard does not exist yet. The toggle stays **Inactive** until P1 has built
`Is this you?` and public HTTPS is verified.

## 2. Create the credential from inside the node

Still inside **Telegram Trigger**:

1. Open the **Credential to connect with** dropdown.
2. Select **Create New Credential**. n8n opens the **Telegram API** form.
3. Click the name at the top of the panel and set it to exactly **`Brain Bot (Telegram)`**.
4. Leave **Base URL** at `https://api.telegram.org`.
5. Put the token on the clipboard from a terminal that is **not** on any shared screen:

   ```bash
   bash setup-telegram-private.sh --stack ~/brain --copy-token
   ```

6. Click into **Access Token** and paste. The field is a password field: you see dots, not
   the token. Do not click the eye icon that reveals it.
7. Select **Save**. n8n calls Telegram's `getMe` with the token and shows
   **Connection tested successfully** in green.
8. Close the credential panel, then clear the clipboard:

   ```bash
   bash setup-telegram-private.sh --stack ~/brain --clear-clipboard
   ```

The credential is now attached to the trigger. Select **Save** on the workflow.

### If the test fails

| n8n reports | It means | Do |
|---|---|---|
| `401 Unauthorized` | Telegram read the token and rejected it: wrong, truncated, or revoked | Rerun private setup with the token BotFather shows now, copy again, paste again |
| `404 Not Found` | The token was empty or malformed, so there was no bot endpoint to check | The clipboard was empty or already cleared: copy again, then paste |
| A network or timeout error | n8n cannot reach `api.telegram.org` | Fix the container's outbound access; the token is not the problem |
| A credential with this name already exists | You made one earlier | Open **Credentials** in the left menu and reuse or delete it; never keep two with this name |

Never retype a token by hand on a shared screen, and never paste it into a chat to ask for
help. If it has been seen anywhere, BotFather `/revoke`, rerun private setup, and replace
the value in this credential.

## 3. What the canvas looks like

```text
Telegram Trigger
  Trigger On: Message
  Credential: Brain Bot (Telegram)
```

One node. Saved. **Inactive.**

## Checkpoint

- [ ] Workflow is named `09 - Voice ask`
- [ ] Telegram Trigger exists and Trigger On is `Message`
- [ ] Credential is named exactly `Brain Bot (Telegram)`
- [ ] Save showed **Connection tested successfully**
- [ ] The credential panel is closed and the clipboard was cleared
- [ ] The workflow toggle still says **Inactive**

P1 starts from this canvas and reuses this credential. It will not create a second one.

Official reference: [n8n Telegram credentials](https://docs.n8n.io/integrations/builtin/credentials/telegram/).
The password-type field and the `getMe` test are declared in n8n's own source,
`packages/nodes-base/credentials/TelegramApi.credentials.ts`.
