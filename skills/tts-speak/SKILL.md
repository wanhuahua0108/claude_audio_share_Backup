---
name: tts-speak
description: >
  Use when the user wants to convert text into spoken audio (text-to-speech / TTS).
  Triggers on requests like "朗读这段文字", "把这段文章念出来", "生成语音", "做个旁白",
  "read this aloud", "text to speech", "make a voiceover", "narrate this", "generate speech".
  Supports multilingual triggers — match equivalent phrases in any language. Routes through
  the company LiteLLM Proxy (TAPSVC) to ElevenLabs `eleven_multilingual_v2` / `eleven_v3`.
  Do NOT trigger on speech-to-text (STT) — that's the `stt-transcribe` skill. Do NOT use
  for music generation (`minimax-music-gen` / `suno-music-gen`) or for cloning a specific
  person's voice (needs ElevenLabs MCP with own key).
license: MIT
metadata:
  version: "1.0"
  category: audio
---

# Text-to-Speech Skill

Synthesize text into MP3 using ElevenLabs models (`eleven_multilingual_v2` /
`eleven_v3`) via the company LiteLLM Proxy (`https://llm-proxy.tapsvc.com`).

Output is a single `.mp3` file under `~/Music/tts-gen/`.

## Prerequisites

- **Proxy API Key** (required): The `ANTHROPIC_AUTH_TOKEN` env var is reused (same TAPSVC
  LiteLLM Proxy key Claude Code uses).

  **Verify it is set:**
  ```bash
  [ -n "$ANTHROPIC_AUTH_TOKEN" ] && echo "Proxy key set" || echo "Missing key"
  ```

  If missing, get one at https://console.tapsvc.com/nova/#/ai-gateway (requires company IP).

- **curl** and **python** (required): curl for the POST, python for safely encoding the
  UTF-8 JSON payload (see "Why python" below).

- **ffprobe** (optional): Used to print final duration. Comes with ffmpeg.

## Why this skill uses python urllib, not curl

Two Windows-specific traps make curl unreliable for this endpoint:

1. `curl -d '<json>'` — shell encodes non-ASCII as the system codepage (GBK on Chinese
   Windows), mangling UTF-8 bytes. ElevenLabs rejects the payload → HTTP 500.
2. `python print(...) > file` + `curl --data-binary @file` — python stdout also defaults
   to GBK on Windows, so the file still contains GBK, not UTF-8. Same failure.

The only cross-platform-safe pattern is `json.dumps(...).encode("utf-8")` inside python
and posting the bytes directly with `urllib.request`. This works on Mac / Linux / Windows
with zero platform branching.

## Constraints

| Limit | Value |
|---|---|
| Max input chars (multilingual_v2) | ~5000 per request |
| Max input chars (eleven_v3) | ~3000 per request |
| Pricing | $0.18 per 1K input chars (both models) |
| Output format | MP3 (default; proxy may also serve other formats but mp3 is safe) |

If the user's text exceeds the model's char limit, **do not auto-split**. Tell the user the
text is too long and ask whether to:

- Trim it manually,
- Run multiple smaller calls and concatenate (ffmpeg `-i "concat:a.mp3|b.mp3" -c copy out.mp3`),
- Or summarize first.

## Storage

Output directory: `~/Music/tts-gen/`

Each call writes one file:

- `<basename>.mp3` — the synthesized audio

Basename format: `YYYYMMDD_HHMMSS_<source-stem>` (e.g. `20260423_124501_intro_paragraph`).

If the source text comes from a file, derive `<stem>` from that filename. If it's
inline text, derive `<stem>` from the first ~30 ASCII-safe chars of the input or use
`speech` as fallback.

## Voice library (defaults + common picks)

ElevenLabs requires a real voice ID — **never** pass OpenAI names like `alloy` / `coral` /
`sage` (those return 500). Skill default is **Rachel** unless the user specifies otherwise
or asks for a male voice.

| Name | ID | Gender | Notes |
|---|---|---|---|
| Rachel | `21m00Tcm4TlvDq8ikWAM` | F | Default. American English; multilingual-capable. |
| Bella | `EXAVITQu4vr4xnSDxMAL` | F | Soft, friendly. |
| Domi | `AZnzlk1XvdvUeBnXmlld` | F | Younger, energetic. |
| Adam | `pNInz6obpgDQGcFmaJgB` | M | Default male. Deep, narrator. |
| Antoni | `ErXwobaYiN019PkySvjV` | M | Warm, conversational. |
| Josh | `TxGEqnHWrfWFTfGW9XjX` | M | Younger male. |

Full library: ElevenLabs official voice catalog (the user can supply any voice ID they
own). Cloned/custom voices are tied to the ElevenLabs account behind the proxy — only
official library voices are guaranteed available via the company key.

## API

- **Endpoint**: `POST https://llm-proxy.tapsvc.com/v1/audio/speech`
- **Auth**: `Authorization: Bearer $ANTHROPIC_AUTH_TOKEN`
- **Models**:
  - `elevenlabs/eleven_multilingual_v2` — 29 languages incl. Chinese / Japanese / Spanish /
    German / Korean. Default for any non-English input.
  - `elevenlabs/eleven_v3` — More expressive prosody, English-strong. Default for English.
- **JSON body**:
  - `model` (required)
  - `input` (required) — the text to synthesize
  - `voice` (required) — ElevenLabs voice ID

## Workflow

1. **Pick the model**:
   - Input is mostly English → `elevenlabs/eleven_v3`
   - Input contains non-English (中文/日本語/Español/etc.) → `elevenlabs/eleven_multilingual_v2`
   - User explicitly asked for one → respect that.

2. **Pick the voice**:
   - User named one → look up ID from the table above (or accept a raw ID).
   - User asked for a "male voice" → `Adam`. "Female voice" or unspecified → `Rachel`.

3. **Validate length**: count chars in the input. If over the model's limit, stop and
   ask the user (see "Constraints" above).

4. **Synthesize** — always use the python-only path below. Do NOT use shell
   `print(...) > file` redirects: on Windows the shell encodes stdout as GBK,
   corrupting non-ASCII text and causing HTTP 500 from ElevenLabs.

   ```python
   import os, json, urllib.request

   MODEL    = "elevenlabs/eleven_multilingual_v2"  # or eleven_v3
   VOICE_ID = "21m00Tcm4TlvDq8ikWAM"              # Rachel (default)
   TEXT     = "要朗读的文字"
   STAMP    = __import__("datetime").datetime.now().strftime("%Y%m%d_%H%M%S")
   STEM     = "speech"  # derive from source filename or first ~30 safe chars
   OUT      = os.path.expanduser(f"~/Music/tts-gen/{STAMP}_{STEM}.mp3")

   os.makedirs(os.path.dirname(OUT), exist_ok=True)

   req = urllib.request.Request(
       "https://llm-proxy.tapsvc.com/v1/audio/speech",
       data=json.dumps({"model": MODEL, "input": TEXT, "voice": VOICE_ID},
                       ensure_ascii=False).encode("utf-8"),
       headers={
           "Authorization": f"Bearer {os.environ['ANTHROPIC_AUTH_TOKEN']}",
           "Content-Type": "application/json; charset=utf-8",
       },
       method="POST",
   )
   with urllib.request.urlopen(req, timeout=60) as r:
       open(OUT, "wb").write(r.read())
   print(f"Saved: {OUT}")
   ```

   Run this as a Bash heredoc:
   ```bash
   python - <<'PY'
   # ... paste the block above with real values filled in ...
   PY
   ```

5. **Verify and report**:
   ```bash
   # Check it's a real MP3, not an error blob
   file "$OUT" 2>/dev/null
   # First 4 bytes should be ID3 (ASCII 0x49 0x44 0x33) or 0xFF 0xFB
   head -c 4 "$OUT" | xxd

   # Optional: print duration
   ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
   ```

   If the file starts with `Internal Server Error` (21 bytes), the request failed —
   re-check voice ID and that the input was sent as UTF-8.

   Show the user:
   - Output path
   - Duration (if ffprobe ran)
   - Voice + model used
   - Approx cost ($0.18/K * char_count / 1000)

## Error handling

- **HTTP 500 "Internal Server Error" (21 bytes body)**: usually one of two causes:
  1. `voice` is not an ElevenLabs ID (e.g. someone passed `alloy`/`coral`).
  2. Input bytes weren't proper UTF-8 (only happens if the workflow above is bypassed).
- **HTTP 400 "Invalid model name"**: only `elevenlabs/eleven_*` models are on the proxy
  key; OpenAI `tts-1` / `gpt-4o-mini-tts` are not. Switch to an ElevenLabs model.
- **HTTP 401 / 403**: Key invalid or expired. Refresh at
  https://console.tapsvc.com/nova/#/ai-gateway.
- **Empty MP3 (< 1KB)**: input may have been empty or all whitespace after parsing.

## Examples

**English, Rachel (default female voice):**
```bash
python - <<'PY'
import os, json, urllib.request, datetime
OUT = os.path.expanduser(f"~/Music/tts-gen/{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}_demo.mp3")
os.makedirs(os.path.dirname(OUT), exist_ok=True)
req = urllib.request.Request(
    "https://llm-proxy.tapsvc.com/v1/audio/speech",
    data=json.dumps({"model": "elevenlabs/eleven_v3",
                     "input": "Hello, this is a quick test of the text to speech pipeline.",
                     "voice": "21m00Tcm4TlvDq8ikWAM"}).encode("utf-8"),
    headers={"Authorization": f"Bearer {os.environ['ANTHROPIC_AUTH_TOKEN']}",
             "Content-Type": "application/json; charset=utf-8"},
    method="POST",
)
open(OUT, "wb").write(urllib.request.urlopen(req, timeout=60).read())
print(f"Saved: {OUT}")
PY
```

**Chinese, male voice (Adam):**
```bash
python - <<'PY'
import os, json, urllib.request, datetime
OUT = os.path.expanduser(f"~/Music/tts-gen/{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}_zh_adam.mp3")
os.makedirs(os.path.dirname(OUT), exist_ok=True)
req = urllib.request.Request(
    "https://llm-proxy.tapsvc.com/v1/audio/speech",
    data=json.dumps({"model": "elevenlabs/eleven_multilingual_v2",
                     "input": "大家好，这是一段中文语音合成示例。",
                     "voice": "pNInz6obpgDQGcFmaJgB"},
                    ensure_ascii=False).encode("utf-8"),
    headers={"Authorization": f"Bearer {os.environ['ANTHROPIC_AUTH_TOKEN']}",
             "Content-Type": "application/json; charset=utf-8"},
    method="POST",
)
open(OUT, "wb").write(urllib.request.urlopen(req, timeout=60).read())
print(f"Saved: {OUT}")
PY
```

## Notes

- The proxy is audited at the company level — do not synthesize personal/sensitive
  content (private messages, impersonation drafts, etc.) through this Skill.
- Voice cloning, sound-effect generation, and Voice Isolator are NOT exposed via the
  proxy — for those, install ElevenLabs MCP with a personal key.
- Output directory `~/Music/tts-gen/` parallels `~/Music/stt-gen/` from `stt-transcribe`.
