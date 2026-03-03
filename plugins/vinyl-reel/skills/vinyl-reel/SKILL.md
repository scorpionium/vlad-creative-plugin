---
name: vinyl-reel
description: >
  Create vertical short-form vinyl unboxing reels from raw footage and audio samples.
  Use this skill whenever the user wants to make a vinyl unboxing video, short reel,
  Instagram reel, YouTube Short, or any short vertical video from a folder of clips.
  Also trigger when the user says "make a reel", "vinyl reel", "unboxing video",
  "create a short", or references a folder with video/ and audio/ subfolders for reel creation.
---

# Vinyl Reel Maker

Create polished 9:16 vertical vinyl unboxing reels (under 59 seconds) from raw footage,
with user-recorded voiceover in English and Ukrainian, background music from all audio
samples crossfaded together, text overlays, and platform-specific exports.

## Workflow Overview

The skill runs in 5 phases. Phases 1-2 run automatically. Phase 3 has two pauses —
first for script approval, then for voiceover file upload. Phases 4-5 resume automatically.

```
Phase 1: Scan & Catalog  ──► Phase 2: Research Album  ──► Phase 3: Write Voiceover Scripts EN+UA
  (PAUSE 1: approve scripts)  ──►  (PAUSE 2: user uploads voiceover files)
Phase 4: Arrange & Mix  ──► Phase 5: Export & Metadata (EN video + UA audio track)
```

## Expected Folder Structure

The user selects a working folder. Inside it:

```
<Album Name>/
├── video/              # Raw clips (PXL_*.mp4, IMG_*.mov, etc.)
├── audio/              # Background music samples (sample1.m4a, *.mp3, *.wav, etc.)
├── voiceover.mp3       # English voiceover (user-provided after script approval)
├── voiceover_ua.mp3    # Ukrainian voiceover (user-provided after script approval)
└── subscribe_btn_animation_small.mp4  # (Optional) Subscribe overlay animation
```

If `subscribe_btn_animation_small.mp4` is not in the folder, use the one bundled in this
skill's `assets/` directory.

## Phase 1: Scan & Catalog

Run the analysis script to inventory all clips:

```bash
python3 <skill-path>/scripts/analyze_clips.py "<working-folder>"
```

This outputs a JSON catalog to stdout with each clip's duration, dimensions, and a
thumbnail extracted to `<working-folder>/.thumbnails/`. Review the thumbnails to understand
what each clip shows (shelf, cover, inner gatefold, booklet pages, patch, poster, vinyl,
turntable, beauty shot, etc.).

**Clip categorization**: Based on thumbnails and visual content, mentally categorize each clip:
- **Intro** clips: record on shelf, pulling from shelf
- **Cover** clips: front cover, back cover, spine
- **Inside** clips: gatefold open, inner artwork, booklet/insert pages
- **Extras** clips: patch, poster, stickers, other inserts
- **Vinyl** clips: pulling vinyl from sleeve, vinyl against light, vinyl detail
- **Turntable** clips: placing on turntable, cue/tonearm, stylus close-up, playing
- **Beauty** clips: final shot with cover + turntable together

## Phase 2: Research Album

Use web search to gather information about this specific album and edition:

1. **Band/artist background**: genre, origin, significance, key members
2. **Album details**: release year, place in discography, musical style, themes, lyrical content
3. **This edition**: label, edition name (anniversary, reissue, etc.), pressing details, limited run,
   vinyl color/variant, bonus content, packaging features
4. **Cultural context**: what makes this album important, fan reception, notable influences

Search queries like: `"<artist> <album>" vinyl reissue`, `"<artist>" discography`,
`"<album>" review`, `"<artist> <album>" <label> edition`

## Phase 3: Write Voiceover Scripts (TWO PAUSES)

Write voiceover scripts in **both English and Ukrainian**, following the style guide in
`references/voiceover_style.md`. Read that file first:

```
Read <skill-path>/references/voiceover_style.md
```

Key requirements:
- **Speech duration**: ~30 seconds of spoken text per language
- **Pauses**: 2-3 natural pauses of approximately 5 seconds each (marked with `[pause]`)
- **Total audio** (speech + pauses): approximately 40-50 seconds
- **Video entry point**: voiceover starts at the **3-second mark** — the first 3 seconds are
  a music-only intro while the first clip plays
- **Tone**: Excited, knowledgeable fan — not a product-spec reader
- **Structure**: Hook → album significance → music/band → edition contents → vinyl reveal → closer
- **Multilingual titles**: If the album title is in a non-English language, include the original
  + translation in both scripts

Save scripts to:
- `<working-folder>/voiceover_script_en.md` — English script
- `<working-folder>/voiceover_script_ua.md` — Ukrainian script

### PAUSE 1: Script Approval

Present both scripts and say something like:
"Here are the voiceover scripts in English and Ukrainian. Let me know if you'd like
any changes to either version, or confirm to proceed to recording."

### Recording Instructions (after script approval)

Once approved, give the user clear recording instructions:

"Please record (or have voiced) both scripts and save them as:
- **`voiceover.mp3`** — English version
- **`voiceover_ua.mp3`** — Ukrainian version

Place both files directly in the working folder (alongside the `video/` and `audio/` folders),
then let me know when they're ready and I'll continue."

### PAUSE 2: Wait for Voiceover Upload

Wait until the user confirms both files are in place. Then verify:

```bash
ls -lh "<working-folder>/voiceover.mp3" "<working-folder>/voiceover_ua.mp3"
```

Check approximate durations (expect ~40-50 seconds each including pauses):
```bash
ffprobe -v quiet -show_entries format=duration -of csv=p=0 "<working-folder>/voiceover.mp3"
ffprobe -v quiet -show_entries format=duration -of csv=p=0 "<working-folder>/voiceover_ua.mp3"
```

If either file is missing, remind the user of the expected filenames and wait.

## Phase 4: Arrange & Mix

This is the core video production phase. Read the ffmpeg patterns reference:

```
Read <skill-path>/references/ffmpeg_patterns.md
```

### 4a. Plan the Edit

Based on clip categories from Phase 1, plan the sequence. Standard structure:

| Timestamp | Content | Text Overlay |
|-----------|---------|-------------|
| 0-3s | Record on shelf / pull from shelf | — |
| 3-7s | Front cover full view | — |
| 7-10s | Front cover close-up / back cover | Artist name + "Album Title" |
| 10-14s | Inner gatefold / poetry pages | Edition subtitle (e.g., "20th Anniversary") |
| 14-17s | Back cover / artwork details | Label info |
| 17-22s | Inside features (booklet pages) | Feature text (e.g., "12-page Insert / ...") |
| 22-26s | Extra items (patch, poster, etc.) | Feature text for each |
| 26-30s | Poster displayed / other extras | Feature text |
| 30-34s | Vinyl pull from sleeve | Vinyl variant text (e.g., "Crystal Clear / Marbled") |
| 34-38s | Vinyl against light | Same vinyl text |
| 38-42s | Vinyl on turntable | — |
| 42-46s | Tonearm / cue lever | — |
| 46-50s | Stylus close-up | — |
| 50-54s | Turntable playing (top-down) | — |
| 54-59s | Beauty shot (cover + turntable) | — |

This is a template — adapt timing based on available clips and their natural content.
Each segment should be 3-5 seconds. Total must be under 59 seconds.

Clips that don't exist in the footage can be skipped. The arrangement should feel natural
and follow the physical unboxing order.

### 4b. Build Video Segments

For each segment, use ffmpeg to:
1. Trim the source clip to the desired portion (`-ss` and `-t`)
2. Scale and pad to 1080x1920 (9:16 portrait)
3. Apply text overlays where specified (white bold title + lighter subtitle, bottom center, with shadow)

Text overlay style (use LiberationSans if available, else DejaVuSans):
```
drawtext=fontfile=<bold-font>:text='<title>':fontcolor=white:fontsize=42:
  x=(w-text_w)/2:y=h-160:shadowcolor=black@0.7:shadowx=3:shadowy=3,
drawtext=fontfile=<regular-font>:text='<subtitle>':fontcolor=white@0.9:fontsize=30:
  x=(w-text_w)/2:y=h-110:shadowcolor=black@0.7:shadowx=2:shadowy=2
```

### 4c. Concatenate Segments

Create a concat list and join all segments:
```bash
ffmpeg -f concat -safe 0 -i concat_list.txt -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 -an video_silent.mp4
```

### 4d. Mix Audio — English and Ukrainian Versions

Run the audio mixing script **twice** — once per voiceover language. The script:
1. Concatenates **all** audio samples from `audio/` with smooth 1-second crossfades
2. Pads the voiceover with 3 seconds of silence (so voiceover begins at t=3 in the video)
3. Uses silence detection to find speech vs. pause periods in the voiceover
4. Drops background music to **10% volume** during speech, returns to **100%** only during
   pauses **longer than 1 second** — short hesitations stay ducked
5. Applies smooth 0.5-second ramps at every volume transition
6. Keeps the voiceover itself at 100% volume throughout

```bash
# English mix (for video)
bash <skill-path>/scripts/mix_audio.sh \
  "<working-folder>" \
  "<video-duration>" \
  "<working-folder>/voiceover.mp3" \
  "<working-folder>/.work/mixed_audio_en.wav"

# Ukrainian mix (audio track only — for YouTube language track upload)
bash <skill-path>/scripts/mix_audio.sh \
  "<working-folder>" \
  "<video-duration>" \
  "<working-folder>/voiceover_ua.mp3" \
  "<working-folder>/.work/mixed_audio_ua.wav"
```

### 4e. Combine Video + Audio (English only)

There is **no Ukrainian video**. The Ukrainian output is an audio track only (exported in Phase 5c).

```bash
# English assembled version
ffmpeg -y -i video_silent.mp4 -i .work/mixed_audio_en.wav \
  -c:v copy -c:a aac -b:a 192k -shortest assembled_en.mp4
```

## Phase 5: Export & Metadata

### 5a. YouTube Shorts Version — English (Subscribe overlay at 20s)

Overlay the subscribe animation starting at exactly the **20-second mark**, playing **once**
(no looping). Use `-itsoffset 20` to delay the subscribe animation input by 20 seconds:

```bash
# Find subscribe animation (working folder first, then skill assets)
SUBSCRIBE="<working-folder>/subscribe_btn_animation_small.mp4"
[ ! -f "$SUBSCRIBE" ] && SUBSCRIBE="<skill-path>/assets/subscribe_btn_animation_small.mp4"

ffmpeg -y \
  -i assembled_en.mp4 \
  -itsoffset 20 -i "$SUBSCRIBE" \
  -filter_complex " \
    [1:v]chromakey=0x00FF00:0.3:0.1,scale=1080:-1[sub]; \
    [0:v][sub]overlay=(W-w)/2:(H-h)/2:eof_action=pass[out]" \
  -map "[out]" -map "0:a" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 \
  -c:a copy \
  "<Album>_Reel.mp4"
```

The `-itsoffset 20` delays the animation so it appears at t=20 in the output video.
It plays once through and stops naturally — no looping.

### 5b. Instagram Version — English (clean, no subscribe)

```bash
cp assembled_en.mp4 "<Album>_Reel_Clean.mp4"
```

### 5c. Ukrainian Audio Track (for YouTube language section)

Export the Ukrainian mixed audio as a standalone AAC file. Upload this to YouTube via
**Subtitles → Add language → Ukrainian** to make the Ukrainian audio track available
in the language selector — no separate video needed.

```bash
ffmpeg -y -i .work/mixed_audio_ua.wav \
  -c:a aac -b:a 192k \
  "<Album>_Audio_UA.m4a"
```

### 5d. Generate YouTube Metadata (English + Ukrainian)

Write titles and descriptions in **both languages**. Save both to
`<working-folder>/youtube_metadata.md` (English first, Ukrainian below a `---` divider).

**Band name in ALL CAPS** everywhere in both titles and descriptions — e.g., IRON MAIDEN,
METALLICA, DRUDKH, PINK FLOYD. Apply this consistently in both English and Ukrainian text.

**English title format**: `BAND NAME - Album Title 🎵 Edition Info`
- Keep under 70 characters
- Include relevant emoji (🎵 📀 🔥 etc.)
- Use a simple hyphen `-` as separator, not an em dash

**English description format**:
```
BAND NAME - Album Title (Original Title if different language)
Edition Name / Label

Vinyl variant description - limited to N copies, numbering details.

This edition includes:
- feature 1
- feature 2
- ...

1-2 sentences about the album's musical significance.

Subscribe for weekly metal vinyl from my collection.

#hashtags (artist, genre, vinyl, vinylunboxing, vinylcollection, label, etc.)
```

Do not use em dashes (—) anywhere in titles or descriptions.

**Ukrainian title and description**: same structure, fully translated into Ukrainian.
Keep BAND NAME in all caps in the Ukrainian text as well.

## Encoding Settings

All video outputs use:
- Codec: H.264 (libx264)
- Preset: fast
- CRF: 18 (high quality)
- Pixel format: yuv420p
- Frame rate: 30fps
- Audio: AAC 192kbps
- Resolution: 1080x1920 (9:16 portrait)

## Error Handling

- If source clips have rotation metadata (common with phone videos), ffmpeg auto-rotates.
  The scale filter handles this correctly.
- If a clip is landscape (1920x1080), it gets letterboxed into portrait with black bars.
  This is expected and looks fine for unboxing content.
- If `voiceover.mp3` or `voiceover_ua.mp3` are not found, remind the user of the exact
  expected filenames and wait.
- The Ukrainian output is audio-only (`<Album>_Audio_UA.m4a`). Instruct the user to upload
  it to YouTube via **Subtitles → Add language → Ukrainian**.
- If total video exceeds 59 seconds, trim the turntable/playing sections (they have the
  most flexibility) to fit.
- If the concatenated background music is shorter than the video duration, `apad` fills
  the remainder with silence — use longer samples if this sounds abrupt.
