# Class 4 claim audit

Verified on **2026-09-01**. “Verified” below means the claim is supported by a
primary source or by a recorded probe in this class folder. It does not mean the
23-node draft workflow has completed a live Telegram end-to-end run; it has not.

| Claim | Verdict | Evidence / correction |
|---|---|---|
| Telegram bots are free to create and use | **Verified** | Telegram describes its Bot Platform as free for users and developers: [Bots introduction](https://core.telegram.org/bots). |
| A bot can use `getUpdates` and a webhook at the same time | **False** | They are mutually exclusive while the webhook is set. `deleteWebhook` restores polling; the conflict is not permanent: [Bot API `getUpdates`](https://core.telegram.org/bots/api#getupdates), [`deleteWebhook`](https://core.telegram.org/bots/api#deletewebhook). |
| A Telegram Trigger works against `http://localhost:5678` | **False** | Telegram must reach a public HTTPS webhook. n8n must be configured with `N8N_WEBHOOK_URL` when it sits behind a proxy: [n8n reverse-proxy webhook configuration](https://github.com/n8n-io/n8n-docs/blob/main/docs/deploy/host-n8n/configure-n8n/basic-configuration/configuration-examples/configure-webhook-urls-with-reverse-proxy.md), [Telegram `setWebhook`](https://core.telegram.org/bots/api#setwebhook). |
| Appending `BRAIN_BOT_TOKEN` to the Class 2 `.env` injects it into n8n | **False** | Compose `.env` supplies interpolation values; the service still has to map or load the variable. The Class 2 Compose file did neither. `setup-telegram-private.sh` now adds an `env_file` override. |
| `docker compose restart n8n` applies changed Compose environment | **False** | Restart does not recreate the container. The corrected setup runs `docker compose up -d --force-recreate n8n`: [Docker Compose `restart`](https://docs.docker.com/reference/cli/docker/compose/restart/). |
| n8n’s Telegram action node sends a Telegram voice note | **Not directly** | The node documents audio operations, but no Send Voice operation. The workflow’s raw Bot API `sendVoice` request is justified: [n8n Telegram node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.telegram/), [Telegram `sendVoice`](https://core.telegram.org/bots/api#sendvoice). |
| One bot can have multiple simultaneous Telegram triggers | **False** | Telegram stores one webhook URL per bot. Use a separate bot for this class: [Telegram `setWebhook`](https://core.telegram.org/bots/api#setwebhook). |
| The owner guard protects the private brain | **Conditionally verified** | The draft compares both `message.from.id` and private `message.chat.id`, fails closed when the environment value is absent, and runs before download/AI nodes. It still requires the live second-account refusal test. |
| ffmpeg and Opus are already present | **Must be verified at runtime** | The Class 2 image tag is `rxchi1d/n8n-ffmpeg:latest`, which moves. The class verifier checks `ffmpeg`, `ffprobe`, and the `libopus` encoder instead of assuming an old image result still applies. |
| `gpt-audio-mini` and `gemini-2.5-flash` are on OpenRouter | **Verified on the audit date** | Both appeared in OpenRouter’s live models API on 2026-09-01. Model availability and pricing can change: [OpenRouter models API](https://openrouter.ai/api/v1/models), [audio inputs](https://openrouter.ai/docs/features/multimodal/audio). |
| “End to end inside n8n: 2 seconds” | **Overstated** | The recorded number covers the measured transcription → `/ask` → speech → encode path. It excludes Telegram upload/download, webhook transit, phone playback, and cold starts. Publish it as a processing-path observation, not an end-to-end guarantee. |
| The shared workflow is production-ready | **False today** | The study copy shipped as `workflow/09-voice-ask.UNVERIFIED.json` is generated and structurally tested, but has not been imported and run through Telegram. The pre-class pack labels it `UNVERIFIED` and tells students to keep it inactive. |
| Pasting the bot token into the n8n credential form is safe on a shared screen | **Verified, with conditions** | `accessToken` is declared `typeOptions: { password: true }` and the save test calls `getMe`, in n8n’s [TelegramApi.credentials.ts](https://github.com/n8n-io/n8n/blob/master/packages/nodes-base/credentials/TelegramApi.credentials.ts), read 2026-09-01. The field masks the value; the reveal icon, the private terminal and BotFather do not, so those stay off screen and the on-camera bot is revoked afterwards. |
| Temp-file cleanup always runs | **False in the draft** | `Clean up` is downstream of `sendVoice`; an earlier failure stops before it. The class now describes cleanup as best-effort, and tested error-output cleanup remains a release-gate item. |

## Release gate

The workflow can lose the `UNVERIFIED` label only after all of these pass on the
same exported JSON that will ship:

1. Public HTTPS health check and Telegram `getWebhookInfo` show the intended URL.
2. Owner text message, owner voice message, and unsupported message all behave as documented.
3. A second Telegram account receives no answer and starts no AI or file-processing nodes.
4. OpenRouter 401/429 and Telegram 401/404 paths leave no secret in execution output.
5. Failure paths remove `/tmp/voice-*` and `/tmp/answer-*` files, or a documented cleanup job does.
6. The exported workflow and both packs pass the credential scanner.
