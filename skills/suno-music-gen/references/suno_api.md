# Suno API Reference (sunoapi.org)

Complete API reference for the Suno music generation API via sunoapi.org.

- **API Base URL**: `https://api.sunoapi.org`
- **File Upload URL**: `https://sunoapiorg.redpandaai.co`
- **Auth**: `Authorization: Bearer <SUNO_API_KEY>`
- **Content-Type**: `application/json`
- **Rate Limit**: 20 requests per 10 seconds

---

# Part 1: Music Generation

## 1. Generate Music

**POST** `/api/v1/generate`

Create a new music generation task. Returns **2 songs** per request.

### Request Body

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prompt` | string | Yes | Song description or lyrics |
| `customMode` | boolean | Yes | `false` = auto-generate, `true` = custom lyrics/style |
| `instrumental` | boolean | Yes | `true` = no vocals |
| `model` | string | Yes | Model version: V4, V4_5, V4_5PLUS, V4_5ALL, V5, V5_5 |
| `callBackUrl` | string | Yes | Webhook URL (use placeholder like `https://example.com/callback`) |
| `style` | string | Conditional | Style tags. Required when `customMode=true` |
| `title` | string | Conditional | Song title. Required when `customMode=true` |
| `negativeTags` | string | No | Styles to exclude (e.g., "Heavy Metal, Screaming") |
| `vocalGender` | string | No | `m` or `f` |
| `personaId` | string | No | Persona ID for custom voice (Custom Mode only) |
| `personaModel` | string | No | `style_persona` (default) or `voice_persona` (V5 only) |
| `styleWeight` | number | No | Style adherence (0.00-1.00) |
| `weirdnessConstraint` | number | No | Creative deviation (0.00-1.00) |
| `audioWeight` | number | No | Input audio influence (0.00-1.00) |

### customMode Rules

| customMode | instrumental | prompt | style | title |
|------------|-------------|--------|-------|-------|
| `false` | `false` | Description (max 500 chars) | Ignored | Ignored |
| `true` | `false` | Lyrics (V4: 3000, V4_5+: 5000 chars) | Required | Required |
| `true` | `true` | Ignored | Required | Required |

### Max Length by Model

| Field | V4 | V4_5 / V4_5PLUS / V5 / V5_5 | V4_5ALL |
|-------|-----|------|---------|
| Style | 200 chars | 1000 chars | 1000 chars |
| Title | 80 chars | 100 chars | 80 chars |
| Lyrics | 3000 chars | 5000 chars | 5000 chars |

### Example

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "[Verse]\nWalking through the rain\n[Chorus]\nCant stop this feeling",
    "customMode": true,
    "instrumental": false,
    "model": "V4_5ALL",
    "style": "Indie Folk, Acoustic, Warm, Melancholic, Female Vocals",
    "title": "Rainy Days",
    "callBackUrl": "https://example.com/callback"
  }'
```

### Response

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "taskId": "abc123-def456-..."
  }
}
```

---

## 2. Query Generation Status

**GET** `/api/v1/generate/record-info?taskId=<taskId>`

Poll every 30 seconds after generating.

### Status Values

| Status | Meaning |
|--------|---------|
| `PENDING` | Queued |
| `TEXT_SUCCESS` | Lyrics generated |
| `FIRST_SUCCESS` | First song ready (stream URL available) |
| `SUCCESS` | Both songs complete |
| `CREATE_TASK_FAILED` | API error |
| `GENERATE_AUDIO_FAILED` | Generation failed |
| `SENSITIVE_WORD_ERROR` | Content filter triggered |

### Response (SUCCESS)

```json
{
  "code": 200,
  "data": {
    "taskId": "abc123",
    "status": "SUCCESS",
    "response": {
      "sunoData": [
        {
          "id": "song-id-1",
          "title": "Rainy Days",
          "audioUrl": "https://cdn.example.com/song.mp3",
          "streamAudioUrl": "https://cdn.example.com/stream.mp3",
          "imageUrl": "https://cdn.example.com/cover.png",
          "duration": 180.5,
          "tags": "indie folk, acoustic",
          "prompt": "[Verse]\nWalking through the rain..."
        },
        { "id": "song-id-2", "...": "..." }
      ]
    }
  }
}
```

---

## 3. Generate Lyrics

**POST** `/api/v1/generate/lyrics`

Auto-generate lyrics from a theme description.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prompt` | string | Yes | Theme or description (max 500 chars) |
| `callBackUrl` | string | No | Webhook URL |

**Poll**: `GET /api/v1/generate/lyrics/record-info?taskId=<taskId>`

Response: `data.response.text` (lyrics with section markers), `data.response.title`

---

## 4. Generate Sounds

**POST** `/api/v1/generate/sounds`

Generate sound effects (not music). Only supports V5 model.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `prompt` | string | Yes | Sound description (max 500 chars) |
| `model` | string | Yes | Must be `V5` |
| `callBackUrl` | string | No | Webhook URL |
| `soundLoop` | boolean | No | Loop playback (default: false) |
| `soundTempo` | integer | No | BPM 1-300 (auto if omitted) |
| `soundKey` | string | No | Pitch key: Any, Cm, C#m, Dm... C, C#, D... B |
| `grabLyrics` | boolean | No | Fetch lyric subtitles (default: false) |

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/sounds" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Soft rain ambience with distant thunder and gentle wind",
    "model": "V5",
    "callBackUrl": "https://example.com/callback"
  }'
```

---

# Part 2: Post-Generation Processing

## 5. Extend Song

**POST** `/api/v1/generate/extend`

Continue an existing Suno-generated song from a specific time point.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `audioId` | string | Yes | Suno audio ID from generation |
| `defaultParamFlag` | boolean | Yes | `false` = use original params, `true` = custom |
| `model` | string | Yes | Model version |
| `callBackUrl` | string | Yes | Webhook URL |
| `continueAt` | number | Conditional | Seconds to extend from (required when `defaultParamFlag=true`) |
| `prompt` | string | Conditional | New lyrics (when `defaultParamFlag=true`) |
| `style` | string | Conditional | New style (when `defaultParamFlag=true`) |
| `title` | string | Conditional | New title (when `defaultParamFlag=true`) |
| `personaId` | string | No | Persona ID |
| `personaModel` | string | No | `style_persona` or `voice_persona` |
| `negativeTags` | string | No | Styles to exclude |
| `vocalGender` | string | No | `m` or `f` |
| `styleWeight` | number | No | 0.00-1.00 |
| `weirdnessConstraint` | number | No | 0.00-1.00 |
| `audioWeight` | number | No | 0.00-1.00 |

---

## 6. Replace Section

**POST** `/api/v1/generate/replace-section`

Replace a specific time range of a song with new content. This is the API equivalent of Suno's "Remix/Edit" feature.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Original generation task ID |
| `audioId` | string | Yes | Audio ID of the track |
| `prompt` | string | Yes | Content for the replacement segment |
| `tags` | string | Yes | Musical style tags |
| `title` | string | Yes | Song title |
| `infillStartS` | number | Yes | Start time in seconds (2 decimal places) |
| `infillEndS` | number | Yes | End time in seconds (2 decimal places) |
| `negativeTags` | string | No | Styles to exclude |
| `callBackUrl` | string | No | Webhook URL |

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/replace-section" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "original-task-id",
    "audioId": "audio-id",
    "prompt": "A soaring guitar solo with distortion",
    "tags": "Rock, Guitar Solo",
    "title": "My Song",
    "infillStartS": 45.00,
    "infillEndS": 60.00,
    "callBackUrl": "https://example.com/callback"
  }'
```

---

## 7. Add Vocals

**POST** `/api/v1/generate/add-vocals`

Add vocals to an existing instrumental track. Requires uploading the audio first.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `uploadUrl` | string | Yes | URL of uploaded instrumental audio |
| `prompt` | string | Yes | Description of desired vocals |
| `title` | string | Yes | Track title (max 100 chars) |
| `style` | string | Yes | Musical style (e.g., "Jazz, Pop") |
| `negativeTags` | string | Yes | Styles to exclude |
| `callBackUrl` | string | Yes | Webhook URL |
| `vocalGender` | string | No | `m` or `f` |
| `model` | string | No | V4_5PLUS (default), V5, or V5_5 |
| `styleWeight` | number | No | 0.00-1.00 |
| `weirdnessConstraint` | number | No | 0.00-1.00 |
| `audioWeight` | number | No | 0.00-1.00 |

---

## 8. Add Instrumental

**POST** `/api/v1/generate/add-instrumental`

Add instrumental accompaniment to a vocal track. Requires uploading the audio first.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `uploadUrl` | string | Yes | URL of uploaded vocal audio |
| `title` | string | Yes | Track title (max 100 chars) |
| `tags` | string | Yes | Music style tags |
| `negativeTags` | string | Yes | Styles to exclude |
| `callBackUrl` | string | Yes | Webhook URL |
| `model` | string | No | V4_5PLUS (default), V5, or V5_5 |
| `vocalGender` | string | No | `m` or `f` |
| `styleWeight` | number | No | 0.00-1.00 |
| `audioWeight` | number | No | 0.00-1.00 |
| `weirdnessConstraint` | number | No | 0.00-1.00 |

---

## 9. Boost Music Style

**POST** `/api/v1/style/generate`

Generate enhanced style descriptions from simple keywords. Useful for expanding brief style ideas into richer prompts.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `content` | string | Yes | Brief style description (e.g., "Pop, Mysterious") |

Returns an expanded, detailed style text.

---

## 10. Concatenate Songs

**POST** `/api/v1/generate/concat`

Merge multiple song clips (from extend operations) into a single track.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `clipId` | string | Yes | Suno audio ID of the clip to concat |
| `callBackUrl` | string | No | Webhook URL |

---

# Part 3: Cover & Mashup

## 11. Upload and Cover Audio

**POST** `/api/v1/generate/upload-cover`

Restyle an uploaded audio file with a new style (AI cover).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `uploadUrl` | string | Yes | URL of uploaded audio file |
| `customMode` | boolean | Yes | `true` for custom style |
| `instrumental` | boolean | Yes | `true` = no vocals |
| `model` | string | Yes | Model version |
| `callBackUrl` | string | Yes | Webhook URL |
| `style` | string | Conditional | Style tags (required when `customMode=true`) |
| `title` | string | Conditional | Title (required when `customMode=true`) |
| `prompt` | string | No | New lyrics |
| `negativeTags` | string | No | Styles to exclude |
| `vocalGender` | string | No | `m` or `f` |
| `styleWeight` | number | No | 0.00-1.00 |
| `weirdnessConstraint` | number | No | 0.00-1.00 |
| `audioWeight` | number | No | 0.00-1.00 |

**Audio constraints**: Max 8 minutes (1 min for V4_5ALL). Formats: mp3, wav, flac.

---

## 12. Upload and Extend Audio

**POST** `/api/v1/generate/upload-extend`

Upload an audio file and extend/continue it.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `uploadUrl` | string | Yes | URL of uploaded audio (max 8 min) |
| `defaultParamFlag` | boolean | Yes | `true` = custom params |
| `model` | string | Yes | Model version |
| `callBackUrl` | string | Yes | Webhook URL |
| `continueAt` | number | Conditional | Seconds to extend from |
| `prompt` | string | Conditional | Lyrics for extension |
| `style` | string | Conditional | Style tags |
| `title` | string | Conditional | Track title |
| `instrumental` | boolean | No | Instrumental flag |
| `personaId` | string | No | Persona ID |
| `negativeTags` | string | No | Styles to exclude |
| `vocalGender` | string | No | `m` or `f` |
| `styleWeight` | number | No | 0.00-1.00 |
| `weirdnessConstraint` | number | No | 0.00-1.00 |
| `audioWeight` | number | No | 0.00-1.00 |

---

## 13. Mashup

**POST** `/api/v1/generate/mashup`

Combine **2 audio files** into a mashup.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `uploadUrlList` | array | Yes | Exactly 2 audio file URLs |
| `customMode` | boolean | Yes | `true` for custom style |
| `model` | string | Yes | Model version |
| `callBackUrl` | string | Yes | Webhook URL |
| `style` | string | Conditional | Style (when `customMode=true`) |
| `title` | string | Conditional | Title (when `customMode=true`) |
| `prompt` | string | Conditional | Lyrics (when `customMode=true` and `instrumental=false`) |
| `instrumental` | boolean | No | Instrumental flag |
| `vocalGender` | string | No | `m` or `f` |
| `styleWeight` | number | No | 0.00-1.00 |
| `weirdnessConstraint` | number | No | 0.00-1.00 |
| `audioWeight` | number | No | 0.00-1.00 |

```bash
curl -s -X POST "https://api.sunoapi.org/api/v1/generate/mashup" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "uploadUrlList": ["https://example.com/song1.mp3", "https://example.com/song2.mp3"],
    "customMode": true,
    "instrumental": false,
    "style": "Electronic Dance, Energetic",
    "title": "Mashup Mix",
    "model": "V4_5ALL",
    "callBackUrl": "https://example.com/callback"
  }'
```

---

# Part 4: Stem Separation & MIDI

## 14. Vocal & Instrument Stem Separation

**POST** `/api/v1/vocal-removal/generate`

Separate a song into individual stems.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Original generation task ID |
| `audioId` | string | Yes | Audio ID to process |
| `type` | string | Yes | `separate_vocal` or `split_stem` |
| `callBackUrl` | string | Yes | Webhook URL |

### Separation Types

| Type | Output | Credits |
|------|--------|---------|
| `separate_vocal` | 2 stems: vocals + instrumental | 10 |
| `split_stem` | Up to 12 stems | 50 |

### split_stem Output Tracks

vocals, backingVocals, drums, bass, guitar, keyboard, percussion, strings, synth, fx, brass, woodwinds

**Poll**: `GET /api/v1/vocal-removal/record-info?taskId=<taskId>`

### Response Fields

For `separate_vocal`: `data.response.vocalUrl`, `data.response.instrumentalUrl`

For `split_stem`: `data.response.vocalUrl`, `data.response.drumsUrl`, `data.response.bassUrl`, `data.response.guitarUrl`, etc.

---

## 15. Generate MIDI

**POST** `/api/v1/midi/generate`

Generate MIDI data from a separated audio track. **Requires vocal separation first.**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Task ID from a **completed vocal separation** |
| `audioId` | string | No | Which separated track to convert to MIDI |
| `callBackUrl` | string | Yes | Webhook URL |

**Poll**: `GET /api/v1/midi/record-info?taskId=<taskId>`

Response: `data.midiData` contains structured MIDI data (detected instruments, note arrays with pitch, timing, velocity). Note: Returns data object, not a downloadable .mid file.

---

# Part 5: Export & Media

## 16. Convert to WAV

**POST** `/api/v1/wav/generate`

Convert a generated song to lossless WAV format.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Original generation task ID |
| `audioId` | string | Yes | Suno audio ID |
| `callBackUrl` | string | Yes | Webhook URL |

**Poll**: `GET /api/v1/wav/record-info?taskId=<taskId>`

Response: `data.response.audioWavUrl`

```bash
# Request WAV conversion
curl -s -X POST "https://api.sunoapi.org/api/v1/wav/generate" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "taskId": "original-task-id",
    "audioId": "song-audio-id",
    "callBackUrl": "https://example.com/callback"
  }'

# Poll result
curl -s -H "Authorization: Bearer $SUNO_API_KEY" \
  "https://api.sunoapi.org/api/v1/wav/record-info?taskId=$WAV_TASK_ID" | jq '.data.response.audioWavUrl'
```

---

## 17. Generate Cover Art

**POST** `/api/v1/suno/cover/generate`

Generate album cover art images for a song. Returns **2 different style images**.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Music generation task ID |
| `callBackUrl` | string | Yes | Webhook URL |

**Poll**: `GET /api/v1/suno/cover/record-info?taskId=<taskId>`

Response: `data.response.images` (array of 2 image URLs, valid for 14 days)

### successFlag Values

| Value | Meaning |
|-------|---------|
| 0 | Pending |
| 1 | Success |
| 2 | Generating |
| 3 | Failed |

Each music task can only generate one cover art set. Duplicate requests return the existing task.

---

## 18. Create Music Video (MV)

**POST** `/api/v1/mp4/generate`

Generate an MP4 music video for a song.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Music generation task ID |
| `audioId` | string | Yes | Audio ID |
| `callBackUrl` | string | Yes | Webhook URL |
| `author` | string | No | Artist name for video display (max 50 chars) |
| `domainName` | string | No | Brand/website watermark (max 50 chars) |

**Poll**: `GET /api/v1/mp4/record-info?taskId=<taskId>`

Response: `data.response.videoUrl`

---

## 19. Get Timestamped Lyrics

**POST** `/api/v1/generate/get-timestamped-lyrics`

Get word-by-word timestamped lyrics for a generated song (useful for karaoke/subtitles).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Music generation task ID |
| `audioId` | string | Yes | Audio ID |

Response: `data.alignedWords` array with `word`, `startS`, `endS` for each word.

Note: Not available for instrumental tracks.

---

# Part 6: Persona (Custom Voice)

## 20. Create Persona

**POST** `/api/v1/generate/generate-persona`

Create a custom voice persona from an existing generated song.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `taskId` | string | Yes | Task ID from music generation |
| `audioId` | string | Yes | Audio ID |
| `name` | string | Yes | Persona name |
| `description` | string | Yes | Musical characteristics and style |
| `vocalStart` | number | No | Voice sample start time (default: 0.0) |
| `vocalEnd` | number | No | Voice sample end time (default: 30.0) |
| `style` | string | No | Style label |

Returns a `personaId` for use in subsequent generation requests with `personaId` + `personaModel` parameters.

---

# Part 7: File Upload

**Base URL**: `https://sunoapiorg.redpandaai.co`

All upload methods require Bearer token auth. Uploaded files are valid for **3 days**.

## 21. File Stream Upload

**POST** `/api/file-stream-upload`

Best for local audio files.

```bash
curl -s -X POST "https://sunoapiorg.redpandaai.co/api/file-stream-upload" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -F "file=@/path/to/audio.mp3" \
  -F "uploadPath=audio" \
  -F "fileName=my-song.mp3"
```

Response: `data.fileUrl` — use this URL in cover/extend/mashup endpoints.

## 22. Base64 File Upload

**POST** `/api/file-base64-upload`

Best for small files or API integration.

```bash
curl -s -X POST "https://sunoapiorg.redpandaai.co/api/file-base64-upload" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "base64Data": "data:audio/mp3;base64,<base64-encoded-data>",
    "uploadPath": "audio",
    "fileName": "my-song.mp3"
  }'
```

## 23. URL File Upload

**POST** `/api/file-url-upload`

Best for files already hosted online.

```bash
curl -s -X POST "https://sunoapiorg.redpandaai.co/api/file-url-upload" \
  -H "Authorization: Bearer $SUNO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "fileUrl": "https://example.com/song.mp3",
    "uploadPath": "audio",
    "fileName": "my-song.mp3"
  }'
```

---

# Part 8: Utilities

## 24. Check Credits

**GET** `/api/v1/generate/credit`

```bash
curl -s -H "Authorization: Bearer $SUNO_API_KEY" \
  "https://api.sunoapi.org/api/v1/generate/credit" | jq '.data'
```

---

# Appendix

## Supported Models

| Model | Max Duration | Best For |
|-------|-------------|----------|
| `V4` | 4 min | Proven quality, stable |
| `V4_5` | 8 min | Smart prompts, genre blending |
| `V4_5PLUS` | 8 min | Richer tones, enhanced variation |
| `V4_5ALL` | 8 min | Better song structure (recommended) |
| `V5` | 8 min | Latest, superior expression |
| `V5_5` | 8 min | Voice-customized, custom models |

## All Polling Endpoints

| Feature | Poll Endpoint |
|---------|--------------|
| Music generation | `GET /api/v1/generate/record-info?taskId=` |
| Lyrics generation | `GET /api/v1/generate/lyrics/record-info?taskId=` |
| WAV conversion | `GET /api/v1/wav/record-info?taskId=` |
| Stem separation | `GET /api/v1/vocal-removal/record-info?taskId=` |
| MIDI generation | `GET /api/v1/midi/record-info?taskId=` |
| Cover art | `GET /api/v1/suno/cover/record-info?taskId=` |
| Music video | `GET /api/v1/mp4/record-info?taskId=` |

## Error Codes

| HTTP Code | Meaning | Action |
|-----------|---------|--------|
| 200 | Success | Continue |
| 400 | Invalid parameters | Check request body |
| 401 | Unauthorized | Check API key |
| 405 | Rate limit (20 req/10s) | Wait and retry |
| 413 | Prompt/style too long | Shorten text |
| 429 | Insufficient credits | Top up at sunoapi.org |
| 430 | Call frequency too high | Wait and retry |
| 451 | File download failure | Retry download |
| 455 | Sound generation error | Adjust prompt |
| 500 | Server error | Retry once |
| 501 | Generation failed | Adjust prompt, retry |
| 531 | Credits refunded | Retry generation |

## Task Status Values

| Status | Meaning |
|--------|---------|
| `PENDING` | Queued |
| `TEXT_SUCCESS` | Lyrics generated |
| `FIRST_SUCCESS` | First song ready |
| `SUCCESS` | Complete |
| `CREATE_TASK_FAILED` | API error |
| `GENERATE_AUDIO_FAILED` | Generation failed |
| `SENSITIVE_WORD_ERROR` | Content filter |
| `CALLBACK_EXCEPTION` | Callback delivery failed |

## Lyrics Structure Tags

`[Intro]` `[Verse]` `[Pre-Chorus]` `[Chorus]` `[Bridge]` `[Outro]` `[Hook]` `[Solo]` `[Interlude]` `[Break]` `[Build Up]`

## Important Notes

- Generated files on Suno servers expire after **14-15 days** — always download immediately
- Uploaded files expire after **3 days**
- Each generation produces **2 songs** — by design, not configurable
- Style tags work best in **English**, comma-separated
- Polling interval: **30 seconds** recommended
- Stream URL available in ~30-40s, full MP3 in ~2-3 minutes
- `callBackUrl` must be a valid URL string (cannot be empty)
- For Claude Code usage, polling is recommended since there is no webhook server
