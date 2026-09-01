# Private Telegram setup

Keep the slide deck on the shared screen. Run this in a terminal that is **not**
being captured. The token and owner ID are read with echo disabled and are never
printed by the script.

```bash
bash setup-telegram-private.sh --stack ~/brain
```

The script asks for:

1. Your n8n **public HTTPS URL**. `localhost` cannot receive Telegram webhooks.
2. The token from BotFather.
3. Your numeric private-chat owner ID.

It writes `.class-04-private.env` in the stack, gives it mode `600`, adds it to
`.gitignore`, creates a Compose override, and recreates n8n. It does not replace
the stack’s `.env` or its encryption key.

The token is placed on the clipboard without being displayed. Paste it into the
n8n credential named `Brain Bot (Telegram)`, save, then clear the clipboard:

```bash
bash setup-telegram-private.sh --stack ~/brain --clear-clipboard
```

Later, copy either value without printing it:

```bash
bash setup-telegram-private.sh --stack ~/brain --copy-token
bash setup-telegram-private.sh --stack ~/brain --copy-owner
```

Check only set/missing status and character counts:

```bash
bash setup-telegram-private.sh --stack ~/brain --status
```

Never run this file with `bash -x`, paste the token into a command-line argument,
or show the private terminal in a recording. If a token appears on screen or in a
chat, use BotFather `/revoke`, rerun setup, and replace the n8n credential.

