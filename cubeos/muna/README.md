# Muna (CubeOS voice agent) — test setup

Muna is the CubeOS voice agent, built on this OpenClaw fork. This folder holds the parts of the
test setup that live outside the repo, so it can be rebuilt on another machine. It is a test
setup: OpenClaw has not been independently audited, and Muna must not ship until it has.

## Limits (owner's decisions, 2026-11-01)

- The model runs on our own hardware (Ollama). No cloud model provider and no cloud speech.
- Text from messages, notifications and contacts is data, never instructions.
- Sending, calling, replying and spending need the owner's spoken yes.
- Muna never handles keys, recovery phrases, passwords, codes or wallet actions.

## Pieces

| Piece                                            | Where it runs                          | Source                                                       |
| ------------------------------------------------ | -------------------------------------- | ------------------------------------------------------------ |
| Gateway (`openclaw gateway run --bind loopback`) | PC, port 18789, loopback only          | npm `openclaw` 2026.10.9                                     |
| Model `qwen3:4b` via Ollama                      | PC GPU, `127.0.0.1:11434`              | `ollama pull qwen3:4b`                                       |
| Phone app (node + chat + Talk)                   | Cube Phone                             | this fork, `apps/android`, branch `cubeos/muna-talk`         |
| Speech-to-text (Whisper, offline)                | Cube Phone, default RecognitionService | `Cube-Operating/cubeos_whisperimeplus`, branch `cubeos/main` |
| Speech output (Piper, offline)                   | PC, `tts-local-cli`                    | rhasspy/piper 2023.11.14-2 + `en_US-lessac-medium`           |

## Files

- `workspace/` — Muna's agent files; copy to `~/.openclaw/workspace/muna/`.
- `openclaw.muna.json` — the Gateway settings Muna needs, with all credentials removed. Merge
  into `~/.openclaw/openclaw.json` after `openclaw onboard` (which creates the auth token).
  `apiKey: "ollama-local"` is OpenClaw's placeholder for a local Ollama, not a secret.
- `piper/say.sh` — the `tts-local-cli` command; install Piper to `~/.local/piper/`.

## Rebuild

1. Ollama: `ollama serve` with `OLLAMA_FLASH_ATTENTION=1 OLLAMA_KV_CACHE_TYPE=q8_0 OLLAMA_MAX_LOADED_MODELS=1`,
   then `ollama pull qwen3:4b`.
2. `openclaw onboard` (owner; it creates the Gateway token). Onboarding picks a cloud model and
   `tools.profile: full` — replace them with the settings in `openclaw.muna.json`.
3. `openclaw agents add muna --non-interactive --workspace ~/.openclaw/workspace/muna --model ollama/qwen3:4b`,
   then copy `workspace/` over the generated files and delete `BOOTSTRAP.md`.
4. Start the Gateway: `openclaw gateway run --bind loopback`.
5. Phone: install the OpenClaw app and the Whisper app from the branches above; copy the Whisper
   model (`whisper_small_int8.zip`, DocWolle/whisperOnnx on Hugging Face) into
   `/sdcard/Android/data/org.woheller69.whisperplus/files/`; then
   `adb shell settings put secure voice_recognition_service org.woheller69.whisperplus/com.whisperonnx.WhisperRecognitionService`.
6. `adb reverse tcp:18789 tcp:18789`, then the owner runs
   `openclaw qr --url ws://127.0.0.1:18789` and scans it in the app (Settings › Gateway).

## Things that bit us

- The phone needs **full** access: the `nodes` tool (phone control) is owner-only, and owner
  means `operator.admin`. A new scan never widens an existing pairing — `openclaw devices remove <id>`,
  Forget on the phone, then scan a fresh code.
- `thinkingDefault: low` for Muna. With thinking off, Qwen3 returns empty replies.
- Keep the `tts` tool denied: Talk speaks replies itself; with the tool Muna answers with WAV files.
- Laptop GPU (RTX 4070 8 GB, NVK driver): on battery or power-saver the model runs ~40× slower;
  the card also suspends (D3cold) when idle and wakes slow. Keep it on mains, profile
  `performance`, and `echo on | sudo tee /sys/bus/pci/devices/0000:01:00.0/power/control`.
  Restart `ollama serve` after any power change. `qwen3:8b` does not fit reliably next to the
  desktop; `qwen3:4b` uses 3.3 GB.
- Cube Phone side mute switch cuts the microphone in hardware; software can't see it.

## Status (2026-11-02)

- Typed questions from the phone: correct (battery, storage, Wi-Fi) in ~20–30 s on a warm GPU.
- Voice dictation on the phone: works (Whisper transcribed speech, Muna replied).
- Spoken replies through Talk (Piper) and the "Hey Muna" wake word: not yet tested / not built.
- Calling and messaging: the phone app has no command for them yet; that needs a CubeOS system app.
