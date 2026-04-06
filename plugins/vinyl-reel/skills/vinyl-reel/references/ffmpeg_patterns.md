# FFmpeg Patterns for Vinyl Reel Production

Proven filter chains and encoding settings refined through production use.

## Table of Contents
1. [Scale & Pad to Portrait](#scale--pad-to-portrait)
2. [Text Overlays](#text-overlays)
3. [Segment Trimming](#segment-trimming)
4. [Concatenation](#concatenation)
5. [Subscribe Overlay (Chromakey)](#subscribe-overlay-chromakey)
6. [Audio: Sidechain Compression](#audio-sidechain-compression)
7. [Audio: Crossfade Samples](#audio-crossfade-samples)
8. [Audio: Silence Detection & Trimming](#audio-silence-detection--trimming)
9. [Final Mux](#final-mux)
10. [Standard Encoding Settings](#standard-encoding-settings)

---

## Scale & Pad to Portrait

Phone clips are often 1920x1080 with rotation metadata. This filter handles any
orientation and outputs clean 1080x1920:

```bash
-vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black"
```

## Text Overlays

Two-line overlay: bold title + lighter subtitle, centered at bottom with shadow.

Font detection — check availability in this order:
```bash
fc-list | grep -i "liberation"  # Preferred
fc-list | grep -i "dejavu"      # Fallback
```

Two-line text overlay filter:
```
drawtext=fontfile=/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf:\
  text='Title Line':fontcolor=white:fontsize=42:\
  x=(w-text_w)/2:y=h-160:\
  shadowcolor=black@0.7:shadowx=3:shadowy=3:\
  enable='between(t,START,END)',\
drawtext=fontfile=/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf:\
  text='Subtitle Line':fontcolor=white@0.9:fontsize=30:\
  x=(w-text_w)/2:y=h-110:\
  shadowcolor=black@0.7:shadowx=2:shadowy=2:\
  enable='between(t,START,END)'
```

For text with special characters, escape colons and apostrophes:
```
text='Кров у наших криницях'   # Unicode works directly
text='It'\''s amazing'         # Escape single quotes
text='Title\: Subtitle'        # Escape colons
```

## Segment Trimming

Trim a clip to a specific portion:
```bash
ffmpeg -y -i input.mp4 \
  -ss 1.5 -t 3.5 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,<text_overlays>" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 -an \
  segment_XX.mp4
```

- `-ss`: Start time within the source clip (skip shaky beginnings)
- `-t`: Duration to extract (3-5s per segment typically)

## Concatenation

Create a file list:
```
file 'segment_01.mp4'
file 'segment_02.mp4'
file 'segment_03.mp4'
```

Concatenate:
```bash
ffmpeg -y -f concat -safe 0 -i concat_list.txt \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 -an \
  output.mp4
```

## Subscribe Overlay (Chromakey)

The subscribe animation has a green screen background. Overlay it during the **final 5
seconds** of the video — where Shorts loop and the end/beginning boundary is a natural
engagement moment. Compute the offset dynamically from the video duration.

```bash
SUBSCRIBE="<working-folder>/subscribe_btn_animation_small.mp4"
[ ! -f "$SUBSCRIBE" ] && SUBSCRIBE="<skill-path>/assets/subscribe_btn_animation_small.mp4"

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
  output_yt_shorts.mp4
```

Key settings:
- `-itsoffset $OVERLAY_OFFSET` — delays stream [1] so the animation starts at final-5s mark
- `scale=1080:-1` — full width of the video, maintains aspect ratio
- `overlay=(W-w)/2:(H-h)/2` — centered both horizontally and vertically
- `chromakey=0x00FF00:0.3:0.1` — green screen removal (similarity=0.3, blend=0.1)
- `eof_action=pass` — once the animation ends, pass the base video through cleanly

## Hook Text Overlay (0-2s)

Bold scarcity/curiosity text over the opening shot, fades out before voiceover begins.
Use the most striking fact from research (copy count, colorway uniqueness, resale value).

```bash
drawtext=fontfile=<bold-font>:text='Only 300 copies worldwide':\
  fontcolor=white:fontsize=52:\
  x=(w-text_w)/2:y=(h-text_h)/2:\
  shadowcolor=black@0.85:shadowx=4:shadowy=4:\
  enable='between(t,0,2)',\
drawtext=fontfile=<regular-font>:text='<BAND NAME> — <Album>':\
  fontcolor=white@0.85:fontsize=34:\
  x=(w-text_w)/2:y=(h-text_h)/2+65:\
  shadowcolor=black@0.7:shadowx=3:shadowy=3:\
  enable='between(t,0,2)'
```

The hook text occupies the center of the frame (not the bottom) so it reads clearly over
any background. It disappears at t=2 — before the voiceover enters at t=3.

## Thumbnail Extraction & Composite

Extract candidate frames and generate composites with bold text for YouTube thumbnails.

```bash
THUMB_DIR="<working-folder>/thumbnails_export"
mkdir -p "$THUMB_DIR"

# Extract frames at key timestamps (adjust to match actual edit)
for t in 1 7 30 35 42; do
  ffmpeg -y -ss $t -i assembled_en.mp4 -vframes 1 -q:v 2 \
    "$THUMB_DIR/frame_${t}s.jpg" 2>/dev/null
done

# Generate composite: BAND NAME (large, white) + Album Title (medium, yellow)
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

Notes:
- Replace `BAND NAME` and `Album Title` with actual values before running
- Best candidates: vinyl reveal (~30s), vinyl against light (~35s), turntable top-down (~42s)
- Face shots (holding the record) consistently outperform no-face shots for CTR

## Audio: Sidechain Compression

Duck background music under voiceover using sidechain compression:

```
[vo_padded]asplit=2[vo_main][vo_sc];
[bg_vol][vo_sc]sidechaincompress=threshold=0.015:ratio=10:attack=80:release=800:level_sc=1:level_in=1[bg_ducked];
[vo_main]volume=1.8[vo_loud];
[vo_loud][bg_ducked]amix=inputs=2:duration=longest:normalize=0[audio_mix];
[audio_mix]alimiter=limit=0.95[audio_final]
```

Parameter explanations:
- `threshold=0.015` — very low threshold so any speech triggers ducking
- `ratio=10` — aggressive compression (10:1) for clear ducking
- `attack=80` — 80ms attack for quick ducking onset
- `release=800` — 800ms release for smooth recovery
- `volume=1.8` — boost voiceover (adjust if recording is louder/quieter)
- `volume=0.35` — background base level (before ducking)
- `alimiter=limit=0.95` — prevent clipping

Note: the `mix_audio.sh` script uses a piecewise volume envelope (not sidechain compression)
with a ducking floor of **22%** during speech — high enough to preserve sonic atmosphere
while still letting the voice cut through clearly.

## Audio: Crossfade Samples

Join multiple background samples with 1-second crossfades:

For 2 samples:
```
[0:a][1:a]acrossfade=d=1:c1=tri:c2=tri[bg_out]
```

For 3+ samples (chain crossfades):
```
[0:a][1:a]acrossfade=d=1:c1=tri:c2=tri[a1];
[a1][2:a]acrossfade=d=1:c1=tri:c2=tri[a2];
[a2][3:a]acrossfade=d=1:c1=tri:c2=tri[bg_out]
```

## Audio: Silence Detection & Trimming

Detect silence in voiceover:
```bash
ffmpeg -i voiceover.mp3 -af "silencedetect=noise=-40dB:d=0.3" -f null - 2>&1
```

Trim trailing silence (keep 0.5s padding):
```bash
ffmpeg -y -i voiceover.mp3 \
  -af "atrim=0:TRIM_END,asetpts=PTS-STARTPTS,afade=t=out:st=FADE_START:d=0.5" \
  -ar 44100 -ac 2 \
  voiceover_trimmed.wav
```

## Final Mux

Combine video and audio:
```bash
ffmpeg -y -i video.mp4 -i mixed_audio.wav \
  -c:v copy -c:a aac -b:a 192k -shortest \
  final_output.mp4
```

## Standard Encoding Settings

All video outputs:
```
-c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30
```

Audio outputs:
```
-c:a aac -b:a 192k
```

Working audio (intermediate):
```
-ar 44100 -ac 2  (WAV, PCM)
```
