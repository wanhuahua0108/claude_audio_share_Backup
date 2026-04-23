---
name: suno-music-gen
description: >
  Use when user wants to generate music using Suno AI. Triggers on any request that
  explicitly mentions "Suno" combined with music creation, song writing, lyrics generation,
  audio production, or covers. Also triggers when user says "用Suno作曲", "Suno写歌",
  "generate with Suno", or similar. Supports multilingual triggers — match equivalent
  phrases in any language. Do NOT trigger on generic music requests without mention of
  Suno — those should go to minimax-music-gen. Do NOT use for music playback of existing
  files, music theory questions, or music recommendation without generation.
license: MIT
metadata:
  version: "1.0"
  category: creative
---

# Suno Music Generation Skill

Generate songs (vocal or instrumental) using the Suno AI music API via sunoapi.org.
Supports two creation modes: **Basic** (one-sentence-in, song-out) and **Advanced Control**
(edit lyrics, refine style, choose model, plan before generating).

Suno generates **2 songs per request**, giving users options to compare and choose.

## Prerequisites

- **Suno API Key** (required): Obtain from [sunoapi.org/api-key](https://sunoapi.org/api-key).

  **Store the key** as an environment variable:
  ```bash
  export SUNO_API_KEY="your-api-key-here"
  ```

  Or save to config file (`~/.suno/config.json`):
  ```bash
  mkdir -p ~/.suno && echo '{"api_key":"your-api-key-here"}' > ~/.suno/config.json
  ```

  **Check if configured:**
  ```bash
  [ -n "$SUNO_API_KEY" ] && echo "ENV set" || ([ -f ~/.suno/config.json ] && echo "Config file found" || echo "Not configured")
  ```

  **Verify API key and check credits:**
  ```bash
  curl -s -H "Authorization: Bearer $SUNO_API_KEY" \
    "https://api.sunoapi.org/api/v1/generate/credit" | jq .
  ```

- **curl** (required): For API calls and downloading audio. Pre-installed on macOS and
  Windows Git Bash. **IMPORTANT: use curl (not Python urllib) for all downloads** —
  Cloudflare blocks urllib requests with HTTP 403.

- **JSON parser** (one of):
  - `jq` — preferred when available (`brew install jq` on macOS, `choco install jq` on
    Windows). Used in the code snippets below.
  - `python` — fallback when jq is missing (see python alternatives in each step).

- **Audio player** (recommended): `mpv`, `ffplay`, or `afplay` (macOS built-in) for local
  playback. `mpv` is preferred for its interactive controls.

## API Overview

This skill calls the Suno API (sunoapi.org) directly via `curl`. No additional CLI tool needed.

- **Base URL**: `https://api.sunoapi.org`
- **Auth**: `Authorization: Bearer $SUNO_API_KEY`
- **Generate**: `POST /api/v1/generate` — returns `taskId`, generates 2 songs
- **Poll status**: `GET /api/v1/generate/record-info?taskId=<id>` — poll every 30s
- **Timing**: Stream URL available in ~30-40s, full MP3 in ~2-3 minutes

### Supported Models

| Model | Max Duration | Best For |
|-------|-------------|----------|
| `V4` | 4 min | Proven quality, stable |
| `V4_5` | 8 min | Smart prompts, genre blending |
| `V4_5PLUS` | 8 min | Richer tones, enhanced variation |
| `V4_5ALL` | 8 min | Better song structure (recommended) |
| `V5` | 8 min | Latest, superior expression |
| `V5_5` | 8 min | Voice-customized, custom models |

Default model: `V4_5ALL` unless user specifies otherwise.

## Storage

All generated music is saved to `~/Music/suno-gen/`. Create the directory if it doesn't
exist. Files are named with a timestamp and a short slug derived from the prompt:
`YYYYMMDD_HHMMSS_<slug>.mp3`

Since Suno generates 2 songs per request, save both as:
- `YYYYMMDD_HHMMSS_<slug>_A.mp3`
- `YYYYMMDD_HHMMSS_<slug>_B.mp3`

---

## Language & Interaction

Detect the user's language from their first message and respond in that language for the
entire session. This applies to all interaction text, questions, confirmations, and feedback
prompts.

**User-facing text localization rule**:
- ALL text shown to the user — including preview labels, field names, confirmations, status
  messages, playback info, feedback prompts — MUST be fully translated into the user's
  language.
- The **style** and **prompt** sent to the API should always be written in English for best
  generation quality. When previewing to the user, show a localized description.

**Lyrics language rule**:
- Default lyrics language = the user's language.
- Only generate lyrics in a different language if the user **explicitly** requests it.
- When a different lyrics language is needed, embed it naturally into the style description
  (e.g., "K-pop", "J-rock", "Mandopop", "Latin pop").

---

## Workflow

### Step 0: Detect Intent

Parse the user's message to determine:

1. **Song category**: vocal (with lyrics), instrumental (no vocals), or cover
2. **Creation mode preference**: did they provide detailed requirements (Advanced) or a
   casual one-liner (Basic)?

If ambiguous, ask using this decision tree:

```
Q1: What type of music?
  - Vocal (with lyrics)
  - Instrumental (no vocals)
  - Cover (restyle existing audio)

Q2: Creation mode?
  - Basic — one-line description, auto-generate
  - Advanced — edit lyrics, refine style, choose model
```

If the user gives a clear one-liner like "用Suno帮我写一首伤感的钢琴曲", skip the
questions — infer instrumental + basic mode and proceed.

---

### Step 1: Read API Key

Before making any API call, read the API key:

```bash
# jq version
SUNO_API_KEY="${SUNO_API_KEY:-$(jq -r '.api_key // empty' ~/.suno/config.json 2>/dev/null)}"
# python fallback (Windows / no jq)
SUNO_API_KEY="${SUNO_API_KEY:-$(python -c "import json; print(json.load(open('$HOME/.suno/config.json')).get('api_key',''))" 2>/dev/null)}"
```

If empty, tell the user to set it up (see Prerequisites).

---

### Step 2: Basic Mode

**Goal**: User provides a short description, the skill auto-generates everything.

1. **Expand the description into a style and prompt**: Take the user's one-liner and expand
   it into a rich English style tag string and an optional lyrics prompt.

   For **vocal songs** (customMode=false): put the full description in `prompt`.
   For **vocal songs** (customMode=true): write `style`, `title`, and `prompt` (as lyrics).
   For **instrumental**: set `instrumental=true`.

2. **Show the user a preview** before generating:

   ```
   About to generate (Suno AI):
   Type: Vocal / Instrumental
   Model: V4_5ALL
   Style: indie folk, melancholic, acoustic guitar, gentle female voice
   Title: Autumn Leaves
   Lyrics: [Auto-generated] / [Custom below]
   
   Suno will generate 2 versions for you to compare.
   Confirm? (press enter to confirm, or tell me what to change)
   ```

3. **Call API**: Generate the music (see Step 4).

---

### Step 3: Advanced Control Mode

**Goal**: User has full control over every parameter before generation.

1. **Lyrics phase**:
   - If user provided lyrics: display them formatted with section markers, ask for edits.
   - If user has a theme but no lyrics: set `customMode=false` and put theme in `prompt`.
   - Support iterative editing: "change the second chorus" -> only rewrite that section.
   - Lyrics must include structure markers: `[Verse]`, `[Chorus]`, `[Bridge]`, etc.

2. **Style phase**:
   - Generate a recommended style string based on the lyrics' mood and content.
   - Present it as editable — user can add/remove/modify style tags.
   - Style examples: "Indie Folk, Acoustic, Warm, Melancholic, Female Vocals"
   - Maximum length: V4 = 200 chars, V4_5+/V5/V5_5 = 1000 chars.

3. **Model selection** (optional, offer but don't force):
   - Default: V4_5ALL
   - Explain differences briefly if user asks

4. **Advanced parameters** (optional):
   - `negativeTags`: styles to exclude (e.g., "Heavy Metal, Screaming")
   - `vocalGender`: `m` or `f`
   - `styleWeight`: 0.00-1.00, how closely to follow the style
   - `weirdnessConstraint`: 0.00-1.00, creativity level

5. **Final confirmation**: Show complete parameter summary, then generate.

---

### Step 4: Call Suno API

**Generate music** using curl:

```bash
SUNO_API_KEY="${SUNO_API_KEY:-$(python -c "import json; print(json.load(open('$HOME/.suno/config.json')).get('api_key',''))" 2>/dev/null)}"

RESPONSE=$(curl -s -X POST "https://api.sunoapi.org/api/v1/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "<lyrics or description>",
    "customMode": <true|false>,
    "instrumental": <true|false>,
    "model": "V4_5ALL",
    "style": "<style tags>",
    "title": "<song title>",
    "callBackUrl": "https://example.com/callback"
  }')

TASK_ID=$(echo "$RESPONSE" | python -c "import json,sys; print(json.load(sys.stdin).get('data',{}).get('taskId',''))")
echo "Task ID: $TASK_ID"
```

**Parameter rules for customMode:**
- `customMode=false`: `prompt` is the description (max 500 chars), `style` and `title` are
  ignored, Suno auto-generates everything.
- `customMode=true, instrumental=false`: `prompt` is the lyrics (V4: max 3000, V4_5+: max
  5000 chars), `style` and `title` are required.
- `customMode=true, instrumental=true`: `prompt` is ignored (or empty), `style` and `title`
  describe the instrumental.

Display a progress indicator while waiting.

---

### Step 5: Poll for Results

Poll every 30 seconds until status is `SUCCESS` or an error state:

```bash
while true; do
  sleep 30
  RESULT=$(curl -s -H "Authorization: Bearer $SUNO_API_KEY" \
    "https://api.sunoapi.org/api/v1/generate/record-info?taskId=$TASK_ID")
  
  STATUS=$(echo "$RESULT" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('status','UNKNOWN'))")

  case "$STATUS" in
    SUCCESS)
      echo "Generation complete!"
      break
      ;;
    PENDING|TEXT_SUCCESS|FIRST_SUCCESS)
      echo "Status: $STATUS — still generating..."
      ;;
    *)
      echo "Error: $STATUS"
      echo "$RESULT" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('errorMessage',''))"
      break
      ;;
  esac
done
```

**Status values:**
- `PENDING` — queued
- `TEXT_SUCCESS` — lyrics generated
- `FIRST_SUCCESS` — first song ready (stream URL available)
- `SUCCESS` — both songs complete
- `CREATE_TASK_FAILED`, `GENERATE_AUDIO_FAILED` — errors

---

### Step 6: Download Songs

Extract audio URLs and download both songs:

```bash
mkdir -p ~/Music/suno-gen

SLUG="<short_slug_from_prompt>"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

AUDIO_URL_A=$(echo "$RESULT" | python -c "import json,sys; print(json.load(sys.stdin)['data']['response']['sunoData'][0]['audioUrl'])")
AUDIO_URL_B=$(echo "$RESULT" | python -c "import json,sys; print(json.load(sys.stdin)['data']['response']['sunoData'][1]['audioUrl'])")
TITLE_A=$(echo "$RESULT" | python -c "import json,sys; print(json.load(sys.stdin)['data']['response']['sunoData'][0]['title'])")
TITLE_B=$(echo "$RESULT" | python -c "import json,sys; print(json.load(sys.stdin)['data']['response']['sunoData'][1]['title'])")

FILE_A=~/Music/suno-gen/${TIMESTAMP}_${SLUG}_A.mp3
FILE_B=~/Music/suno-gen/${TIMESTAMP}_${SLUG}_B.mp3

curl -s -o "$FILE_A" "$AUDIO_URL_A"
curl -s -o "$FILE_B" "$AUDIO_URL_B"

echo "Downloaded:"
echo "  A: $FILE_A"
echo "  B: $FILE_B"
```

Also extract and display metadata:
- `duration`: song duration in seconds
- `tags`: style tags used
- `title`: generated title

---

### Step 7: Playback

After download, detect an available audio player and play **song A first**:

**Detect player:**
```bash
command -v mpv || command -v ffplay || command -v afplay
```

**Play based on detected player (in priority order):**

| Player | Command |
|--------|---------|
| `mpv` (preferred) | `mpv --no-video "$FILE_A"` |
| `ffplay` | `ffplay -nodisp -autoexit "$FILE_A"` |
| `afplay` (macOS) | `afplay "$FILE_A"` |
| None found | Show file path only |

After playing song A, ask:

```
Song A finished. Want to hear Song B as well?
  1. Yes, play Song B
  2. No, Song A is great — keep it
  3. Neither is good, let me adjust and regenerate
```

---

### Step 8: Feedback & Iteration

After the user has heard both songs, ask:

```
Which song do you prefer?
  1. Keep Song A
  2. Keep Song B
  3. Keep both
  4. Neither — adjust and regenerate
  5. Fine-tune lyrics/style then regenerate
```

Based on feedback:
- **Keep one**: Delete the other file, mention the kept file's path.
- **Keep both**: Done. Mention both file paths.
- **Adjust & regenerate**: Ask what to change (style? lyrics? model?), apply edits,
  re-run generation. Rename old files with `_v1` suffix.
- **Fine-tune**: Enter Advanced Control Mode with the current parameters pre-filled.

---

## Cover Mode

Restyle an existing audio file with a new style using Suno.

### Workflow

1. User provides source audio — upload it first:
   ```bash
   SUNO_API_KEY="${SUNO_API_KEY:-$(jq -r '.api_key // empty' ~/.suno/config.json 2>/dev/null)}"
   UPLOAD_RESPONSE=$(curl -s -X POST "https://sunoapiorg.redpandaai.co/api/file-stream-upload" \
     -H "Authorization: Bearer $SUNO_API_KEY" \
     -F "file=@<local_file.mp3>")
   UPLOAD_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.data.fileUrl')
   ```

2. Call the cover endpoint:
   ```bash
   curl -s -X POST "https://api.sunoapi.org/api/v1/generate/upload-cover" \
     -H "Authorization: Bearer $SUNO_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "uploadUrl": "'$UPLOAD_URL'",
       "customMode": true,
       "instrumental": false,
       "model": "V4_5ALL",
       "style": "<target style>",
       "title": "<cover title>",
       "prompt": "<optional new lyrics>",
       "callBackUrl": "https://example.com/callback"
     }'
   ```

3. Poll and download as in Steps 5-6.

**Audio constraints**: Max 8 minutes (1 min for V4_5ALL). Formats: mp3, wav, flac.

---

## Extend Mode

Continue an existing Suno-generated song:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/extend" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "audioId": "<suno_audio_id>",
    "defaultParamFlag": false,
    "model": "V4_5ALL",
    "callBackUrl": "https://example.com/callback"
  }'
```

With custom parameters (`defaultParamFlag=true`):
- `continueAt`: seconds to continue from (must be > 0 and < audio duration)
- `prompt`, `style`, `title`: same as generate

---

## Mashup Mode

Combine 2 audio files into a mashup:

1. Upload both audio files (see Cover Mode step 1 for upload method).
2. Call mashup endpoint:
   ```bash
   curl -s -X POST "https://api.sunoapi.org/api/v1/generate/mashup" \
     -H "Authorization: Bearer $SUNO_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "uploadUrlList": ["'$URL_1'", "'$URL_2'"],
       "customMode": true,
       "instrumental": false,
       "style": "<target style>",
       "title": "<mashup title>",
       "model": "V4_5ALL",
       "callBackUrl": "https://example.com/callback"
     }'
   ```
3. Poll and download as in Steps 5-6.

---

## Replace Section (Remix)

Replace a specific time range within a song:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/replace-section" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<original_task_id>",
    "audioId": "<audio_id>",
    "prompt": "<new content for this section>",
    "tags": "<style tags>",
    "title": "<song title>",
    "infillStartS": 30.00,
    "infillEndS": 45.00,
    "callBackUrl": "https://example.com/callback"
  }'
```

Use this when user wants to fix or redo a specific section without regenerating the whole
song. Ask the user for the start/end time range.

---

## Add Vocals / Add Instrumental

Add vocals to an instrumental, or add accompaniment to a vocal track:

1. Upload the source audio file first.
2. **Add vocals**:
   ```bash
   curl -s -X POST "https://api.sunoapi.org/api/v1/generate/add-vocals" \
     -H "Authorization: Bearer $SUNO_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "uploadUrl": "'$UPLOAD_URL'",
       "prompt": "<vocal style description>",
       "title": "<track title>",
       "style": "<music style>",
       "negativeTags": "<styles to avoid>",
       "vocalGender": "f",
       "callBackUrl": "https://example.com/callback"
     }'
   ```
3. **Add instrumental**:
   ```bash
   curl -s -X POST "https://api.sunoapi.org/api/v1/generate/add-instrumental" \
     -H "Authorization: Bearer $SUNO_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "uploadUrl": "'$UPLOAD_URL'",
       "title": "<track title>",
       "tags": "<instrumental style>",
       "negativeTags": "<styles to avoid>",
       "callBackUrl": "https://example.com/callback"
     }'
   ```

---

## Stem Separation

Separate a generated song into individual tracks:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/vocal-removal/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<original_task_id>",
    "audioId": "<audio_id>",
    "type": "separate_vocal",
    "callBackUrl": "https://example.com/callback"
  }'
```

**Two separation types:**
- `separate_vocal` — 2 stems: vocals + instrumental (10 credits)
- `split_stem` — up to 12 stems: vocals, drums, bass, guitar, keyboard, percussion,
  strings, synth, fx, brass, woodwinds, backingVocals (50 credits)

Poll with `GET /api/v1/vocal-removal/record-info?taskId=<taskId>`. Response contains
download URLs for each stem (`vocalUrl`, `instrumentalUrl`, `drumsUrl`, etc.).

---

## MIDI Export

Generate MIDI data from a song. **Requires stem separation first.**

1. Run stem separation (above).
2. Use the separation task's result to generate MIDI:
   ```bash
   curl -s -X POST "https://api.sunoapi.org/api/v1/midi/generate" \
     -H "Authorization: Bearer $SUNO_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "taskId": "<vocal_separation_task_id>",
       "audioId": "<separated_track_id>",
       "callBackUrl": "https://example.com/callback"
     }'
   ```
3. Poll with `GET /api/v1/midi/record-info?taskId=<taskId>`. Response contains structured
   MIDI data (instruments, notes with pitch/timing/velocity).

---

## WAV Export

Convert any generated song to lossless WAV:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/wav/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<original_task_id>",
    "audioId": "<audio_id>",
    "callBackUrl": "https://example.com/callback"
  }'
```

Poll with `GET /api/v1/wav/record-info?taskId=<taskId>`. Download from
`data.response.audioWavUrl`. Save as `.wav` in `~/Music/suno-gen/`.

---

## Cover Art Generation

Generate album cover art images for a song (2 different styles):

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/suno/cover/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<original_task_id>",
    "callBackUrl": "https://example.com/callback"
  }'
```

Poll with `GET /api/v1/suno/cover/record-info?taskId=<taskId>`. Response:
`data.response.images` (array of 2 image URLs, valid 14 days). Download and save to
`~/Music/suno-gen/` alongside the song.

---

## Music Video (MV) Generation

Generate an MP4 music video for a song:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/mp4/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<original_task_id>",
    "audioId": "<audio_id>",
    "author": "<artist name>",
    "callBackUrl": "https://example.com/callback"
  }'
```

Poll with `GET /api/v1/mp4/record-info?taskId=<taskId>`. Download from
`data.response.videoUrl`. Save as `.mp4` in `~/Music/suno-gen/`.

---

## Sound Effects Generation

Generate sound effects (not music) using V5 model only:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/sounds" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "<sound description, max 500 chars>",
    "model": "V5",
    "soundLoop": false,
    "soundTempo": 120,
    "soundKey": "Any",
    "callBackUrl": "https://example.com/callback"
  }'
```

Optional parameters: `soundLoop` (loop playback), `soundTempo` (BPM 1-300), `soundKey`
(pitch: Any, Cm, C#m, ... A#, B).

---

## Timestamped Lyrics

Get word-by-word timed lyrics for karaoke/subtitles:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/get-timestamped-lyrics" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<original_task_id>",
    "audioId": "<audio_id>"
  }'
```

Response: `data.alignedWords` array — each entry has `word`, `startS`, `endS`. Not
available for instrumental tracks.

---

## Boost Music Style

Expand simple style keywords into rich, detailed style descriptions:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/style/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "Pop, Mysterious"}'
```

Use this to help users who don't know what style tags to use. Feed the result back into
the `style` parameter of the generate endpoint.

---

## Persona (Custom Voice)

Create a custom voice from an existing generated song:

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/generate-persona" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "<task_id>",
    "audioId": "<audio_id>",
    "name": "<persona name>",
    "description": "<voice description>",
    "vocalStart": 0.0,
    "vocalEnd": 30.0,
    "style": "<style label>"
  }'
```

Returns a `personaId`. Use it in subsequent generate/extend calls:
- `"personaId": "<id>"` — apply this voice
- `"personaModel": "voice_persona"` — use voice cloning (V5 only)
- `"personaModel": "style_persona"` — use style transfer (default)

---

## File Upload

Upload audio files before using cover, extend, mashup, add-vocals, or add-instrumental.

**Upload Base URL**: `https://sunoapiorg.redpandaai.co`

```bash
# Upload a local file
UPLOAD_RESPONSE=$(curl -s -X POST "https://sunoapiorg.redpandaai.co/api/file-stream-upload" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -F "file=@/path/to/audio.mp3")
UPLOAD_URL=$(echo "$UPLOAD_RESPONSE" | jq -r '.data.fileUrl')
```

Uploaded files expire after **3 days**. Three upload methods available:
- `/api/file-stream-upload` — for local files (multipart/form-data)
- `/api/file-base64-upload` — for small files (JSON body with base64)
- `/api/file-url-upload` — for files already hosted online (JSON body with URL)

---

## Error Handling

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| 200 | Success | Continue |
| 400 | Invalid parameters | Check and fix request body |
| 401 | Unauthorized | Check API key |
| 405 | Rate limit (20 req/10s) | Wait and retry |
| 413 | Prompt/style too long | Shorten text |
| 429 | Insufficient credits | Report to user, suggest top-up at sunoapi.org |
| 430 | Call frequency too high | Wait and retry |
| 451 | File download failure | Retry download |
| 500 | Server error | Retry once |
| 501 | Generation failed | Adjust prompt, retry |
| 531 | Credits refunded | Retry generation |

**Task status errors:**
- `CREATE_TASK_FAILED`: API error — retry with adjusted parameters
- `GENERATE_AUDIO_FAILED`: Generation error — try different style/lyrics
- `SENSITIVE_WORD_ERROR`: Content filter — adjust prompt to avoid filtered content

---

## Important Notes

- **Two songs per request**: Suno always generates 2 versions. Let the user compare and
  choose. This is a feature, not a limitation.
- **Never reproduce copyrighted lyrics.** When doing covers, always write original lyrics
  inspired by the song's theme. Explain this to the user.
- **Style language**: The style field works best with English tags. Comma-separated genre
  and mood descriptors work best (e.g., "Indie Folk, Acoustic, Warm, Melancholic").
- **File retention**: Generated files on Suno's servers expire after 14-15 days. Uploaded
  files expire after 3 days. Always download to local storage immediately.
- **Rate limit**: Maximum 20 requests per 10 seconds. Space out rapid operations.
- **callBackUrl**: Must be a valid URL string — cannot be empty. Use a placeholder like
  `https://example.com/callback` when no webhook server is available.
- **Credits**: Check remaining credits before large batch operations:
  ```bash
  curl -s -H "Authorization: Bearer $SUNO_API_KEY" \
    "https://api.sunoapi.org/api/v1/generate/credit" | python -c "import json,sys; print(json.load(sys.stdin).get('data',''))"
  ```
- **No callback server needed**: This skill uses polling (every 30 seconds) instead of
  callbacks, since Claude Code doesn't have a webhook endpoint.
- **Section markers in lyrics**: Use `[Verse]`, `[Chorus]`, `[Bridge]`, `[Outro]`,
  `[Intro]`, `[Pre-Chorus]`, `[Hook]`, `[Solo]`, `[Interlude]`, `[Break]`, `[Build Up]`
  for structured lyrics.
- **Workflow chains**: Some features require prior steps:
  - MIDI export requires stem separation first
  - Cover/extend/mashup with external audio requires file upload first
  - Persona creation requires a completed generation first

---

## Complete Feature Overview

| Feature | Endpoint | When to Use |
|---------|----------|-------------|
| Generate music | `/api/v1/generate` | Core creation (vocal/instrumental) |
| Generate lyrics | `/api/v1/generate/lyrics` | Auto-write lyrics from theme |
| Generate sounds | `/api/v1/generate/sounds` | Sound effects (V5 only) |
| Extend song | `/api/v1/generate/extend` | Continue a Suno song |
| Replace section | `/api/v1/generate/replace-section` | Fix/redo a specific part |
| Upload & cover | `/api/v1/generate/upload-cover` | Restyle external audio |
| Upload & extend | `/api/v1/generate/upload-extend` | Continue external audio |
| Mashup | `/api/v1/generate/mashup` | Combine 2 songs |
| Add vocals | `/api/v1/generate/add-vocals` | Add singing to instrumental |
| Add instrumental | `/api/v1/generate/add-instrumental` | Add backing to vocals |
| Stem separation | `/api/v1/vocal-removal/generate` | Split into stems (2 or 12) |
| MIDI export | `/api/v1/midi/generate` | Get MIDI data |
| WAV export | `/api/v1/wav/generate` | Lossless download |
| Cover art | `/api/v1/suno/cover/generate` | Album art (2 styles) |
| Music video | `/api/v1/mp4/generate` | Auto-generate MV |
| Timestamped lyrics | `/api/v1/generate/get-timestamped-lyrics` | Karaoke/subtitles |
| Boost style | `/api/v1/style/generate` | Expand style keywords |
| Create persona | `/api/v1/generate/generate-persona` | Custom voice |
| Check credits | `/api/v1/generate/credit` | Balance check |

---

## Appendix: Suno API Reference

See [references/suno_api.md](references/suno_api.md) for the complete API endpoint reference
(24 endpoints with parameters, examples, and response formats).
