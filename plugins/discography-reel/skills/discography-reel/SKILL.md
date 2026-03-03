---
name: discography-reel
description: >
  Create a ≤59s 9:16 discography reel showcasing a band's complete studio discography.
  One video + audio clip per album, chronological oldest to newest, equal duration per album,
  album name text overlay at the top. Trigger when the user wants a discography reel,
  "band discography video", "all albums reel", or references making a short about a band's
  full catalogue.
---

# Discography Reel Maker

Create a ≤59-second 9:16 discography reel (YouTube Shorts / Instagram Reels) showcasing a
band's complete studio discography — one video + audio clip per album, chronological order,
equal duration per album, album name overlay at the top of each section, no voiceover.

## Workflow Overview

```
Phase 1: Research Discography  ──► Phase 2: Create Folders (PAUSE: populate assets)
  ──► Phase 3: Scan & Validate  ──► Phase 4: Assemble & Export
```

Phases 1, 3, and 4 run automatically. Phase 2 has one pause for the user to populate
the per-album asset folders.

---

## Phase 1: Research Studio Discography

Web-search the band's studio discography using at least two sources (Wikipedia preferred,
plus a corroborating source such as Metal-Archives, AllMusic, or Discogs):

```
"<BAND NAME>" studio discography
"<BAND NAME>" discography site:en.wikipedia.org
```

**Include ONLY studio albums.** Strictly exclude:
- EPs, singles, split releases
- Compilations, best-ofs, anthologies
- Live albums, concert recordings
- Demos, promos, bootlegs
- Box sets, reissues counted as separate entries

Sort chronologically (oldest first). Number them 1…N.

**For each album, research one suggested audio sample** using Last.fm, Spotify charts, or
fan/review sources (AllMusic, Metal-Archives reviews, RateYourMusic). Search:

```
"<BAND NAME>" "<ALBUM NAME>" most popular song
"<BAND NAME>" "<ALBUM NAME>" best track site:last.fm OR site:rateyourmusic.com
```

Pick the track that best satisfies **both** criteria:
1. **Most recognisable** — highest play count, biggest single, or the track the band is
   known for from that album.
2. **Catchy opening** — the hook, riff, or melody hits within the first 3–5 seconds so
   even a short section_sec clip lands immediately. Avoid slow intros, long instrumental
   buildups, or fade-ins.

If two tracks tie on popularity, prefer the one with the more immediately striking opening.

**Compute timing:**
```
section_sec = floor(59 / N)
total_sec   = section_sec * N
```

Reference table:

| N albums | section_sec | total_sec | note              |
|----------|-------------|-----------|-------------------|
| 4        | 14          | 56        | comfortable       |
| 5        | 11          | 55        | comfortable       |
| 8        | 7           | 56        | comfortable       |
| 10       | 5           | 50        | comfortable       |
| 12       | 4           | 48        | minimum workable  |
| 14       | 4           | 56        | minimum workable  |
| 15       | 3           | 45        | too fast — split  |
| 20       | 2           | 40        | too fast — split  |

**Minimum viable time per album is 4 seconds.** Below that, the viewer cannot read the album
name overlay, recognise the audio snippet, or appreciate the clip before the crossfade hits.

Show the user a numbered table including the suggested sample track for each album:

```
Studio discography: N albums  →  section_sec s each  →  total_sec s total

 1. Album Name One (1985)    — Xs   ♪ "Suggested Track Title"
 2. Album Name Two (1987)    — Xs   ♪ "Suggested Track Title"
 ...
```

The ♪ suggestion is a starting point — the user can use any track they prefer.

**Timing checks (evaluate in order):**

1. If `section_sec >= 4`: proceed normally.

2. If `section_sec == 3` (N = 15–19 albums): suggest splitting into two parts.
   Compute split sizes: `part1 = ceil(N / 2)`, `part2 = N - part1`.
   Show the user:

   > "At 3 s per album the reel will feel very rushed. I recommend splitting into two
   > parts: Part 1 (albums 1–`part1`, `floor(59/part1)` s each) and Part 2
   > (albums `part1+1`–N, `floor(59/part2)` s each).
   > Reply **split** to make two reels, or **single** to continue as one."

   Wait for the user's choice. If **split**, run Phases 2–4 twice — once per part — using
   the same asset folders. If **single**, continue with `section_sec = 3` and note it will
   be fast-paced.

3. If `section_sec <= 2` (N ≥ 20 albums): splitting is required.
   Compute split sizes as above and tell the user:

   > "At `section_sec` s per album a single reel is not watchable. I'll produce two parts:
   > Part 1 (albums 1–`part1`) and Part 2 (albums `part1+1`–N).
   > Confirm to continue."

   Wait for confirmation, then run Phases 2–4 twice.

---

## Phase 2: Create Working Directory + Asset Folders (PAUSE)

Create a working directory in the current directory:
```
<Band Name> Discography/
```

For each album i (1…N), create two subfolders. Use the naming convention:
- Zero-pad the index to 2 digits: `01`, `02`, … `NN`
- Replace spaces with underscores in the album name
- Strip special characters (colons, slashes, apostrophes, quotes, asterisks) from the album name

```
<Band Name> Discography/
├── 01_<AlbumName>_(<Year>)/
│   ├── video/
│   └── audio/
├── 02_<AlbumName>_(<Year>)/
│   ├── video/
│   └── audio/
└── ...
```

Show the complete folder tree to the user.

### PAUSE

Tell the user:

"Asset folders are ready. Please drop **exactly one video clip** and **exactly one audio sample**
into each album's `video/` and `audio/` subfolder respectively.

Video formats accepted: `.mp4 .mov .avi .mkv .m4v`
Audio formats accepted: `.m4a .mp3 .wav .aac .flac .ogg`

The video clip should be representative footage for that album (live clip, vinyl shot, cover
art pan, etc.). For the audio sample, I suggested a track for each album above (♪) — pick a
file that starts at or near the catchy hook so the best seconds land within your section window.
You are free to use any track you like.

Confirm here when all folders are populated."

**Wait for the user's confirmation before continuing.**

---

## Phase 3: Scan & Validate

Read the ffmpeg patterns reference first:
```
Read <skill-path>/references/ffmpeg_patterns.md
```

Then run the scan script:
```bash
python3 <skill-path>/scripts/scan_assets.py "<Band Name> Discography"
```

The script outputs JSON with `errors[]` and per-album asset paths.

**If errors exist:** list every error clearly (missing video, missing audio, multiple files
found, unreadable file). Stop. Tell the user to fix the listed folders and confirm again.
Re-run the scan after confirmation. Do NOT proceed with an invalid asset structure.

**If all valid:** echo the scan summary (N albums, total duration) and continue to Phase 4.

---

## Phase 4: Assemble & Export

Variables established in earlier phases:
- `BAND` — band name (ALL CAPS for metadata, original case for paths)
- `N` — number of albums
- `section_sec` — integer seconds per album
- `YEAR_FIRST` — year of album 1
- `YEAR_LAST` — year of album N
- `WORK_DIR` — `<Band Name> Discography`
- `WORK` — `<WORK_DIR>/.work` (create if needed)
- `SUBSCRIBE` — path to subscribe animation (see 4d)

```bash
mkdir -p "$WORK_DIR/.work"
```

### 4a. Detect Font

Check for available fonts:
```bash
fc-list | grep -i "LiberationSans-Bold"
fc-list | grep -i "DejaVuSans-Bold"
```

Use the first font found. Fallback order:
1. `/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf`
2. `/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf`
3. Any bold `.ttf` reported by `fc-list`

### 4b. Build Per-Album Segments

For each album i (1…N), build a self-contained segment with video scaled/padded to portrait,
album name + year text overlay at the top:

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
  "<WORK>/segment_<NN>.mp4"
```

Notes:
- The text overlay is at `y=60` (top of frame with padding) with a semi-transparent black
  box background strip for legibility.
- `-ss 0 -t <section_sec>` before each `-i` trims at the demuxer level (fast, no re-decode
  for finding the start). For sources shorter than `section_sec`, `apad` fills audio and
  `tpad=stop_mode=clone` fills video — add `tpad` to `-vf` only if the source is shorter:
  ```
  tpad=stop_mode=clone:stop_duration=<extra_sec>
  ```
  Check source duration from the scan output to determine if padding is needed.
- Escape special characters in album names: apostrophes → `'\''`, colons → `\:`.

### 4c. Concatenate Segments with Crossfades

Use chained `xfade` + `acrossfade` filter_complex for smooth transitions between segments.

**Crossfade duration:** 0.5 seconds per transition.

**Offset formula for transition i (0-indexed, i=0 is first transition between seg 0 and seg 1):**
```
O_i = (i + 1) * section_sec - (i + 1) * 0.5 - 0.5
```

Simplified: `O_0 = section_sec - 1.0`, `O_1 = 2*section_sec - 1.5`, etc.

Build the filter_complex dynamically based on N:

For N=3 (example with 2 transitions):
```
-filter_complex "
  [0:v][1:v]xfade=transition=fade:duration=0.5:offset=<O0>[v01];
  [v01][2:v]xfade=transition=fade:duration=0.5:offset=<O1>[vout];
  [0:a][1:a]acrossfade=d=0.5:c1=tri:c2=tri[a01];
  [a01][2:a]acrossfade=d=0.5:c1=tri:c2=tri[aout]
" -map "[vout]" -map "[aout]"
```

General pattern for N segments (N-1 transitions):
```
# Video chain:
[0:v][1:v]xfade=transition=fade:duration=0.5:offset=<O0>[v01];
[v01][2:v]xfade=transition=fade:duration=0.5:offset=<O1>[v02];
...
[v(N-2)](N-1):v]xfade=transition=fade:duration=0.5:offset=<O(N-2)>[vout];

# Audio chain:
[0:a][1:a]acrossfade=d=0.5:c1=tri:c2=tri[a01];
[a01][2:a]acrossfade=d=0.5:c1=tri:c2=tri[a02];
...
[a(N-2)][N-1):a]acrossfade=d=0.5:c1=tri:c2=tri[aout];
```

**Special case N=1:** No crossfade needed — copy segment directly to assembled.mp4.

Full assemble command:
```bash
ffmpeg -y \
  -i "<WORK>/segment_01.mp4" \
  -i "<WORK>/segment_02.mp4" \
  ... \
  -i "<WORK>/segment_NN.mp4" \
  -filter_complex "<generated_filter_complex>" \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 \
  -c:a aac -b:a 192k \
  "<WORK>/assembled.mp4"
```

### 4d. Clean Export

```bash
cp "<WORK>/assembled.mp4" \
   "<WORK_DIR>/<BAND_SLUG>_Discography_<YEAR_FIRST>-<YEAR_LAST>.mp4"
```

Where `<BAND_SLUG>` = band name with spaces replaced by underscores, special chars stripped.

### 4e. YouTube Shorts Export (subscribe overlay at t=20s)

Locate the subscribe animation:
```bash
SUBSCRIBE="<skill-path>/assets/subscribe_btn_animation_small.mp4"
```

The `<skill-path>` is the directory containing this SKILL.md file.

Apply overlay starting at t=20s using `-itsoffset 20`:
```bash
ffmpeg -y \
  -i "<WORK>/assembled.mp4" \
  -itsoffset 20 -i "$SUBSCRIBE" \
  -filter_complex " \
    [1:v]chromakey=0x00FF00:0.3:0.1,scale=1080:-1[sub]; \
    [0:v][sub]overlay=(W-w)/2:(H-h)/2[out]" \
  -map "[out]" -map "0:a" \
  -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -r 30 \
  -c:a copy \
  "<WORK_DIR>/<BAND_SLUG>_Discography_<YEAR_FIRST>-<YEAR_LAST>_yt.mp4"
```

If `total_sec <= 20`, skip the subscribe overlay (the animation would not appear within
the video duration). Mention this to the user.

### 4f. Generate Metadata

Write `<WORK_DIR>/<BAND_SLUG>_Discography_metadata.md` with English and Ukrainian sections.

**BAND NAME in ALL CAPS** everywhere in titles and descriptions.
**No em dashes (—) anywhere.** Use plain hyphens `-` as separators.

```markdown
# BAND NAME - Full Discography (<YEAR_FIRST>-<YEAR_LAST>)

---

## English

**Title:** BAND NAME - Full Discography (<YEAR_FIRST>-<YEAR_LAST>) #vinyl

**Description:**
BAND NAME is a <genre> band from <country>, active since <year>.
This reel covers their complete studio discography — N albums from <YEAR_FIRST> to <YEAR_LAST>.

Albums:
1. Album Name (YEAR)
2. Album Name (YEAR)
...

Subscribe for weekly metal vinyl from my collection.

#BandName #Discography #vinyl #vinylcollection #youtubeShorts #metal #<genre>

---

## Ukrainian

**Назва:** BAND NAME - Повна дискографія (<YEAR_FIRST>-<YEAR_LAST>) #vinyl

**Опис:**
BAND NAME — <genre> гурт з <country>, заснований у <year>.
Цей ролик охоплює повну студійну дискографію — N альбомів від <YEAR_FIRST> до <YEAR_LAST>.

Альбоми:
1. Album Name (YEAR)
2. Album Name (YEAR)
...

Підписуйтесь — щотижня метал-вінілова колекція.

#BandName #Discography #vinyl #vinylcollection #youtubeShorts #metal #<genre>
```

---

## Summary Output

After Phase 4 completes, tell the user:

```
Done! Outputs saved to: <WORK_DIR>/

  <BAND_SLUG>_Discography_<YEAR_FIRST>-<YEAR_LAST>.mp4     — clean version
  <BAND_SLUG>_Discography_<YEAR_FIRST>-<YEAR_LAST>_yt.mp4  — YouTube Shorts (subscribe at t=20s)
  <BAND_SLUG>_Discography_metadata.md                       — EN + UA titles and descriptions
```

---

## Error Handling

- **Source clip shorter than section_sec:** Add `tpad=stop_mode=clone` to freeze the last
  frame for the remaining duration. Add `apad` for audio (already in the segment command).
- **Font not found:** Try `fc-list` to find any available bold TTF. If none, omit
  `fontfile=` — ffmpeg will use its default font (text will still render, just less styled).
- **Crossfade offset calculation:** If the filter_complex fails with offset errors, double-check
  that O_i values are strictly less than `(i+1) * section_sec`. Round to 2 decimal places.
- **assembled.mp4 duration check:** After assembly, verify duration with ffprobe. It should
  be approximately `total_sec - (N-1) * 0.5` due to crossfade overlap. This is expected.
- **Subscribe asset not found:** If `<skill-path>/assets/subscribe_btn_animation_small.mp4`
  is missing, skip the `_yt.mp4` export and tell the user — the asset should be bundled
  with the plugin.
- **N=1 (band with only 1 studio album):** No crossfade. Copy segment_01.mp4 to assembled.mp4.
  Subscribe overlay still applied if total_sec > 20.
