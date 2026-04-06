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
with background music from all audio samples crossfaded together, text overlays, and
platform-specific exports. Optionally includes a user-recorded bilingual voiceover
(English + Ukrainian).

## Workflow Overview

Three modes are supported:

**Voiceover mode** (default): EN + UA narration recorded by the user.
```
Phase 1: Scan & Catalog  ──► Phase 2: Research Album  ──► [PAUSE: choose mode]
  ──► Phase 3: Write Voiceover Scripts EN+UA
  (PAUSE 1: approve scripts)  ──►  (PAUSE 2: user uploads voiceover files)
  ──► Phase 4: Arrange & Mix  ──► Phase 5: Export & Metadata (EN video + UA audio track)
```

**No-voiceover mode**: music-only reel, no recording needed.
```
Phase 1: Scan & Catalog  ──► Phase 2: Research Album  ──► [PAUSE: choose mode]
  ──► Phase 4: Arrange & Mix (music only)  ──► Phase 5: Export & Metadata (EN video only)
```

**Tight-cut mode** (optional flag, works with either mode above): targets 35-45 seconds
instead of 55-59 seconds. Tighter clip selection, shorter script. Can be combined with
either voiceover or no-voiceover mode. The user can request it in their trigger message
("tight cut", "short version", "35 seconds") or be offered it after Phase 1.

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

## Mode Selection (after Phase 1)

If the user's trigger message explicitly mentions "no voiceover", "music only",
"instrumental", or similar — set **no-voiceover mode** automatically without asking.

If the trigger message mentions "tight cut", "short version", "35 seconds", or similar —
set **tight-cut mode** automatically.

Otherwise, after completing Phase 1 and reviewing the catalog, ask:

> "Clips scanned — N clips, ~Xs total. Two questions:
> 1. **Voiceover** (you'll record narration in English + Ukrainian) or **music-only**?
> 2. **Standard length** (~55s) or **tight cut** (~35-40s, higher retention)?"

Wait for the user's reply before continuing.

---

## Phase 2: Research Album

Use web search to gather information about this specific album and edition:

1. **Band/artist background**: genre, origin, significance, key members
2. **Album details**: release year, place in discography, musical style, themes, lyrical content
3. **This edition** — prioritize scarcity and rarity signals:
   - Pressing quantity (limited to X copies?) and numbering details
   - Label and pressing plant
   - Vinyl colorway description (exact name, unique characteristics)
   - Resale/market value if notable (Discogs average)
   - Bonus content, packaging features
4. **Cultural context**: what makes this album important, fan reception, notable influences
5. **Band popularity signal**: run a quick check (Spotify monthly listeners, Last.fm plays, or
   general web search) to gauge whether the band is niche or widely known. This shapes the
   hook strategy:
   - **Niche band** (< ~500k Spotify listeners or little mainstream coverage): use a
     curiosity/education hook — "You've probably never heard of this band, but..."
   - **Popular band** (widely known): use a specificity/exclusivity hook — lean into what
     makes *this pressing* unique, not the band itself

Search queries like: `"<artist> <album>" vinyl reissue`, `"<artist> <album>" limited pressing`,
`"<artist> <album>" <label> edition`, `"<artist> <album>" discogs`, `"<artist>" spotify`

**After research, identify the single most unusual or rare fact** about this pressing
(colorway, copy count, pressing plant, market value, packaging anomaly). This fact will
lead the voiceover hook — write it down explicitly before moving to Phase 3.

## Phase 3: Write Voiceover Scripts (TWO PAUSES) — voiceover mode only

> **Skip this entire phase in no-voiceover mode.** Proceed directly to Phase 4.


Write voiceover scripts in **both English and Ukrainian**, following the style guide in
`references/voiceover_style.md`. Read that file first:

```
Read <skill-path>/references/voiceover_style.md
```

Key requirements:
- **Speech duration**: ~30 seconds of spoken text per language (tight-cut: ~18-22s)
- **Pauses**: 2-3 natural pauses of approximately 5 seconds each (marked with `[pause]`)
- **Total audio** (speech + pauses): approximately 40-50 seconds (tight-cut: ~28-35s)
- **Video entry point**: voiceover starts at the **3-second mark** — the first 3 seconds are
  a music-only hook with a text overlay (see Phase 4a); the voice comes in after the hook lands
- **Tone**: Excited, knowledgeable fan — not a product-spec reader
- **Structure**: **Surprise/scarcity first** → album significance → band/music → edition
  contents → vinyl reveal → closer. Do NOT open with a description of the band or album
  history — open with the most unusual or rare fact identified in Phase 2.
- **Hook line**: The first sentence must be a standalone statement of scarcity, rarity, or
  surprise. Examples: "Only 300 copies of this exist in the entire world." /
  "This exact colorway was never pressed again." / "This sat in a Kyiv record shop for
  a decade before anyone noticed what it was." Do NOT open with "Here's one from my
  collection" or any variation — that's reserved for the text overlay hook, not the voice.
- **Band popularity shapes the hook** (use Phase 2 popularity signal):
  - Niche band: open with curiosity framing about the band's cult status, then pivot to the pressing
  - Popular band: skip the band intro, go straight to what makes *this pressing* exceptional
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

**Opening rule**: The first clip must be the most visually dramatic shot available — a colored
vinyl reveal, spinning disc close-up, or hands unwrapping. Do NOT open with a static album
cover or shelf shot. Review Phase 1 thumbnails and select the most striking frame as clip 1.

**Hook text overlay (0-2s)**: The very first 2 seconds carry a bold text overlay with a
curiosity or scarcity hook pulled from Phase 2 research. Choose ONE of these framings:
- Pressing quantity: `"Only 300 copies worldwide"`
- Colorway uniqueness: `"Never pressed in this color again"`
- Value/rarity: `"$180 on Discogs — I paid $45"`
- Mystery: `"Most underrated pressing in my entire collection"`

This text appears for the first 2 seconds, before any voiceover. It is the hook that stops
the scroll. Pick the most factually unusual detail from Phase 2.

**Standard structure (55-59s)**:

| Timestamp | Content | Text Overlay |
|-----------|---------|-------------|
| 0-3s | **Most dramatic shot** (vinyl reveal / disc close-up / unwrapping) | Hook text (0-2s only) |
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

**Tight-cut structure (35-45s)** — use when tight-cut mode is active:

| Timestamp | Content | Text Overlay |
|-----------|---------|-------------|
| 0-3s | **Most dramatic shot** (vinyl reveal / disc close-up) | Hook text (0-2s only) |
| 3-6s | Front cover full view | — |
| 6-9s | Cover close-up | Artist name + "Album Title" |
| 9-12s | Gatefold / key artwork | Edition subtitle |
| 12-16s | Best extra (patch / poster / key insert) | Feature text |
| 16-20s | Vinyl pull from sleeve | Vinyl variant text |
| 20-24s | Vinyl against light | Same vinyl text |
| 24-28s | Vinyl on turntable + tonearm | — |
| 28-35s | Turntable playing + beauty shot | — |

Skip any segment where no good clip exists. Tight-cut total must be 35-45 seconds.

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

### 4d. Mix Audio

**Voiceover mode**: Run the audio mixing script **twice** — once per voiceover language.
The script:
1. Concatenates **all** audio samples from `audio/` with smooth 1-second crossfades
2. Pads the voiceover with 3 seconds of silence (so voiceover begins at t=3 in the video)
3. Uses silence detection to find speech vs. pause periods in the voiceover
4. Drops background music to **22% volume** during speech (preserves sonic atmosphere),
   returns to **100%** only during pauses **longer than 1 second** — short hesitations stay ducked
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

**No-voiceover mode**: Concatenate all audio samples with crossfades and loop/trim to match
the video duration. No ducking required.

Discover all audio samples in `audio/` sorted by name. If there is only one sample, loop it.
If there are multiple, concatenate them with 1-second acrossfade transitions using
`filter_complex`:

```bash
# Example for 3 samples: sample0, sample1, sample2
ffmpeg -y \
  -i "<sample0>" -i "<sample1>" -i "<sample2>" \
  -filter_complex "
    [0:a][1:a]acrossfade=d=1:c1=tri:c2=tri[a01];
    [a01][2:a]acrossfade=d=1:c1=tri:c2=tri[aout];
    [aout]atrim=0:<video-duration>,asetpts=PTS-STARTPTS[afinal]
  " \
  -map "[afinal]" \
  -c:a aac -b:a 192k \
  "<working-folder>/.work/mixed_audio.wav"
```

If the concatenated samples are shorter than the video, pad with `apad` before `atrim`:
```
[aout]apad,atrim=0:<video-duration>,asetpts=PTS-STARTPTS[afinal]
```

### 4e. Combine Video + Audio

**Voiceover mode**: There is **no Ukrainian video**. The Ukrainian output is an audio track
only (exported in Phase 5c).

```bash
# English assembled version
ffmpeg -y -i video_silent.mp4 -i .work/mixed_audio_en.wav \
  -c:v copy -c:a aac -b:a 192k -shortest assembled_en.mp4
```

**No-voiceover mode**: Combine video with the music-only mix:

```bash
ffmpeg -y -i video_silent.mp4 -i .work/mixed_audio.wav \
  -c:v copy -c:a aac -b:a 192k -shortest assembled_en.mp4
```

## Phase 5: Export & Metadata

### 5a. YouTube Shorts Version — English (Subscribe overlay at final 5s)

Overlay the subscribe animation starting at the **final 5 seconds** of the video — where
Shorts loop and the end/beginning boundary is a natural engagement moment. The overlay
position is `video_duration - 5` seconds.

```bash
# Find subscribe animation (working folder first, then skill assets)
SUBSCRIBE="<working-folder>/subscribe_btn_animation_small.mp4"
[ ! -f "$SUBSCRIBE" ] && SUBSCRIBE="<skill-path>/assets/subscribe_btn_animation_small.mp4"

# Get video duration and compute overlay offset
VIDEO_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 assembled_en.mp4)
OVERLAY_OFFSET=$(python3 -c "print(max(0, float('$VIDEO_DUR') - 5))")

ffmpeg -y \
  -i assembled_en.mp4 \
  -itsoffset "$OVERLAY_OFFSET" -i "$SUBSCRIBE" \
  -filter_complex " \
    [1:v]chromakey=0x00FF00:0.3:0.1,scale=1080:-1[sub]; \
    [0:v][sub]overlay=(W-w)/2:(H-h)/2:eof_action=pass[out]" \
  -map "[out]" -map "0:a" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 \
  -c:a copy \
  "<Album>_Reel.mp4"
```

The `-itsoffset $OVERLAY_OFFSET` delays the animation so it appears at the final 5 seconds.
It plays once through and stops naturally — no looping.

### 5b. Instagram Version — English (clean, no subscribe)

```bash
cp assembled_en.mp4 "<Album>_Reel_Clean.mp4"
```

### 5c. Thumbnail Candidates

Extract frames at visually interesting timestamps and generate composite thumbnails with
bold title text. YouTube auto-picks a mediocre frame — this gives the user better options.

```bash
THUMB_DIR="<working-folder>/thumbnails_export"
mkdir -p "$THUMB_DIR"

# Extract candidate frames at key moments (vinyl reveal, cover, turntable, gatefold, light shot)
# Adjust timestamps to match the actual edit from Phase 4a
for t in 1 7 30 35 42; do
  ffmpeg -y -ss $t -i assembled_en.mp4 -vframes 1 -q:v 2 \
    "$THUMB_DIR/frame_${t}s.jpg" 2>/dev/null
done

# Generate composite thumbnails — bold BAND NAME + Album Title, high-contrast drop shadow
# Run for each extracted frame (or just the best 2-3 candidates)
FONT_BOLD="/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
[ ! -f "$FONT_BOLD" ] && FONT_BOLD="/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

for frame in "$THUMB_DIR"/frame_*.jpg; do
  name=$(basename "$frame" .jpg)
  ffmpeg -y -i "$frame" \
    -vf "drawtext=fontfile='$FONT_BOLD':text='BAND NAME':fontcolor=white:fontsize=90:\
x=(w-text_w)/2:y=h-260:shadowcolor=black@0.95:shadowx=5:shadowy=5,\
drawtext=fontfile='$FONT_BOLD':text='Album Title':fontcolor=yellow:fontsize=58:\
x=(w-text_w)/2:y=h-160:shadowcolor=black@0.95:shadowx=4:shadowy=4" \
    "$THUMB_DIR/${name}_composite.jpg" 2>/dev/null
done
```

Replace `BAND NAME` and `Album Title` with the actual values from Phase 2.
Present the composite thumbnails to the user and note which timestamp each came from.
Recommend the vinyl reveal or turntable shot as the strongest option.

### 5e. Ukrainian Audio Track (for YouTube language section) — voiceover mode only

> **Skip in no-voiceover mode.** No UA audio track is produced.


Export the Ukrainian mixed audio as a standalone AAC file. Upload this to YouTube via
**Subtitles → Add language → Ukrainian** to make the Ukrainian audio track available
in the language selector — no separate video needed.

```bash
ffmpeg -y -i .work/mixed_audio_ua.wav \
  -c:a aac -b:a 192k \
  "<Album>_Audio_UA.m4a"
```

### 5f. Generate YouTube Metadata (English + Ukrainian)

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
- **(Voiceover mode only)** If `voiceover.mp3` or `voiceover_ua.mp3` are not found, remind
  the user of the exact expected filenames and wait.
- **(Voiceover mode only)** The Ukrainian output is audio-only (`<Album>_Audio_UA.m4a`).
  Instruct the user to upload it to YouTube via **Subtitles → Add language → Ukrainian**.
- **(No-voiceover mode)** No UA audio track is produced. Only the YT Shorts and Instagram
  clean versions are output.
- **(Thumbnail phase)** Replace `BAND NAME` and `Album Title` placeholders in the thumbnail
  ffmpeg commands with the actual values before running — these are templates, not literals.
- If total video exceeds 59 seconds, trim the turntable/playing sections (they have the
  most flexibility) to fit.
- If the concatenated background music is shorter than the video duration, `apad` fills
  the remainder with silence — use longer samples if this sounds abrupt.
