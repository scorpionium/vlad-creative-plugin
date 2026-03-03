# FFmpeg Patterns for Discography Reel Production

Proven filter chains for assembling multi-album discography reels. All outputs are 1080x1920
9:16 portrait, H.264 CRF-18, 30fps, AAC 192kbps.

## Table of Contents
1. [Scale & Pad to Portrait](#scale--pad-to-portrait)
2. [Text Overlay — Top of Frame](#text-overlay--top-of-frame)
3. [Segment Build — Video + Audio Trimmed Together](#segment-build--video--audio-trimmed-together)
4. [Short Clip Padding](#short-clip-padding)
5. [Crossfade — Chained xfade + acrossfade](#crossfade--chained-xfade--acrossfade)
6. [Subscribe Overlay (Chromakey at t=20s)](#subscribe-overlay-chromakey-at-t20s)
7. [Standard Encoding Settings](#standard-encoding-settings)

---

## Scale & Pad to Portrait

Phone clips and footage can be any orientation. This filter outputs a clean 1080x1920 frame
regardless of source aspect ratio, with black bars (letterbox/pillarbox) as needed:

```bash
-vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black"
```

- `force_original_aspect_ratio=decrease` — scales down to fit within 1080x1920
- `pad` — centers the scaled frame, fills remainder with black

---

## Text Overlay — Top of Frame

Album name and year displayed at the top of each section. Semi-transparent black background
box provides legibility over any footage.

Font detection (run before building segments):
```bash
fc-list | grep -i "LiberationSans-Bold"   # Preferred
fc-list | grep -i "DejaVuSans-Bold"       # Fallback
```

Top-of-frame overlay with box background:
```
drawtext=fontfile=<bold_font>:\
  text='Album Name (Year)':\
  fontcolor=white:fontsize=40:\
  x=(w-text_w)/2:y=60:\
  box=1:boxcolor=black@0.5:boxborderw=12:\
  shadowcolor=black@0.6:shadowx=2:shadowy=2
```

Key parameters:
- `y=60` — near the top with breathing room from the edge
- `box=1:boxcolor=black@0.5:boxborderw=12` — semi-transparent background strip (12px padding)
- `fontsize=40` — readable at phone screen size
- `shadowcolor=black@0.6` — additional depth for legibility

Escaping special characters in album names:
```
text='It'\''s a Long Way'     # Escape apostrophes with '\''
text='Title\: Subtitle'       # Escape colons with \:
text='Кров у наших криницях'  # Unicode (Cyrillic etc.) works directly
```

---

## Segment Build — Video + Audio Trimmed Together

Build one self-contained segment per album. Both video and audio are trimmed to
`section_sec` at the demuxer level (fast seek), scaled to portrait, text overlay applied,
and muxed together in a single pass:

```bash
ffmpeg -y \
  -ss 0 -t <section_sec> -i "<video_file>" \
  -ss 0 -t <section_sec> -i "<audio_file>" \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,
       pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,
       drawtext=fontfile=<bold_font>:\
         text='<Album Name> (<Year>)':\
         fontcolor=white:fontsize=40:\
         x=(w-text_w)/2:y=60:\
         box=1:boxcolor=black@0.5:boxborderw=12:\
         shadowcolor=black@0.6:shadowx=2:shadowy=2" \
  -af "apad,atrim=0:<section_sec>,asetpts=PTS-STARTPTS" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 \
  -c:a aac -b:a 192k \
  ".work/segment_<NN>.mp4"
```

Notes:
- `-ss 0 -t <section_sec>` before each `-i` = fast demuxer-level seek (no full decode)
- `-af "apad,atrim=0:<section_sec>,asetpts=PTS-STARTPTS"` — pads short audio to fill
  `section_sec`, then trims to exact length and resets timestamps
- If the video source is shorter than `section_sec`, add `tpad` to the `-vf` chain (see
  [Short Clip Padding](#short-clip-padding))

---

## Short Clip Padding

If a source clip is shorter than `section_sec`, freeze the last frame to fill the gap.

Add `tpad` at the end of the `-vf` filter chain:
```
tpad=stop_mode=clone:stop_duration=<extra_sec>
```

Where `extra_sec = section_sec - source_duration` (use scan output to compute this).

Full `-vf` with padding:
```bash
-vf "scale=1080:1920:force_original_aspect_ratio=decrease,
     pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,
     tpad=stop_mode=clone:stop_duration=<extra_sec>,
     drawtext=..."
```

Audio padding is already handled by `apad` in the `-af` chain.

---

## Crossfade — Chained xfade + acrossfade

Smooth 0.5-second fade transitions between all N album segments, applied in a single
`filter_complex` pass.

### Offset Formula

Each transition i (0-indexed, i=0 is the transition between segment 0 and segment 1):
```
O_i = (i + 1) * section_sec - (i + 1) * 0.5 - 0.5
```

Equivalently: `O_i = (i + 1) * (section_sec - 0.5) - 0.5`

Example — 5 albums, section_sec=11, crossfade=0.5s:
```
O_0 = 1 * 10.5 - 0.5 = 10.0   (transition: seg 0 → seg 1)
O_1 = 2 * 10.5 - 0.5 = 20.5   (transition: seg 1 → seg 2)
O_2 = 3 * 10.5 - 0.5 = 31.0   (transition: seg 2 → seg 3)
O_3 = 4 * 10.5 - 0.5 = 41.5   (transition: seg 3 → seg 4)
```

### Filter Complex Template

For N segments (N-1 transitions), chaining video and audio crossfades in parallel:

```
-filter_complex "
  [0:v][1:v]xfade=transition=fade:duration=0.5:offset=<O0>[v01];
  [v01][2:v]xfade=transition=fade:duration=0.5:offset=<O1>[v02];
  [v02][3:v]xfade=transition=fade:duration=0.5:offset=<O2>[v03];
  ...
  [v(N-2)][N-1:v]xfade=transition=fade:duration=0.5:offset=<O(N-2)>[vout];

  [0:a][1:a]acrossfade=d=0.5:c1=tri:c2=tri[a01];
  [a01][2:a]acrossfade=d=0.5:c1=tri:c2=tri[a02];
  [a02][3:a]acrossfade=d=0.5:c1=tri:c2=tri[a03];
  ...
  [a(N-2)][N-1:a]acrossfade=d=0.5:c1=tri:c2=tri[aout]
"
-map "[vout]" -map "[aout]"
```

### Worked Example — 3 Albums, section_sec=19

Offsets: O_0=18.0, O_1=37.5

```bash
ffmpeg -y \
  -i ".work/segment_01.mp4" \
  -i ".work/segment_02.mp4" \
  -i ".work/segment_03.mp4" \
  -filter_complex "
    [0:v][1:v]xfade=transition=fade:duration=0.5:offset=18.0[v01];
    [v01][2:v]xfade=transition=fade:duration=0.5:offset=37.5[vout];
    [0:a][1:a]acrossfade=d=0.5:c1=tri:c2=tri[a01];
    [a01][2:a]acrossfade=d=0.5:c1=tri:c2=tri[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 \
  -c:a aac -b:a 192k \
  ".work/assembled.mp4"
```

**Special case N=1:** No filter_complex needed — copy segment directly:
```bash
cp ".work/segment_01.mp4" ".work/assembled.mp4"
```

**Note on assembled duration:** The output will be approximately
`total_sec - (N-1) * 0.5` seconds due to crossfade overlap shortening each boundary.
This is expected and correct — each 0.5s crossfade overlaps adjacent segments by 0.5s.

---

## Subscribe Overlay (Chromakey at t=20s)

Overlay the green-screen subscribe animation starting at exactly the 20-second mark.
The animation plays once through and stops naturally (no looping).

```bash
# Locate asset — working folder first, then sibling plugin
SUBSCRIBE="<WORK_DIR>/subscribe_btn_animation_small.mp4"
[ ! -f "$SUBSCRIBE" ] && \
  SUBSCRIBE="<repo-root>/plugins/vinyl-reel/skills/vinyl-reel/assets/subscribe_btn_animation_small.mp4"

ffmpeg -y \
  -i ".work/assembled.mp4" \
  -itsoffset 20 -i "$SUBSCRIBE" \
  -filter_complex " \
    [1:v]chromakey=0x00FF00:0.3:0.1,scale=1080:-1[sub]; \
    [0:v][sub]overlay=(W-w)/2:(H-h)/2[out]" \
  -map "[out]" -map "0:a" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 \
  -c:a copy \
  "<BAND_SLUG>_Discography_<YEAR_FIRST>-<YEAR_LAST>_yt.mp4"
```

Key settings:
- `-itsoffset 20` — delays the subscribe animation input by 20 seconds relative to the main video
- `chromakey=0x00FF00:0.3:0.1` — removes green background (similarity=0.3, blend=0.1)
- `scale=1080:-1` — full frame width, preserves aspect ratio
- `overlay=(W-w)/2:(H-h)/2` — centered on frame
- `-c:a copy` — audio stream passed through without re-encode

If `total_sec <= 20`, skip this export — the animation would appear after the video ends.

---

## Standard Encoding Settings

All video outputs:
```
-c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30
```

Audio:
```
-c:a aac -b:a 192k
```

Resolution: `1080x1920` (9:16 portrait)
