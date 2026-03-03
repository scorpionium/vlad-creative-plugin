# discography-reel

Creates a ≤59s 9:16 discography reel showcasing a band's complete studio discography. One video + audio clip per album, chronological oldest to newest, equal duration per album, album name overlay at the top. No voiceover — text does the talking. Outputs a clean version and a YouTube Shorts version with the subscribe button animation.

## Install

```
/plugin marketplace add scorpionium/vlad-creative
/plugin install discography-reel@vlad-creative
```

## Usage

```
/discography-reel Band Name
```

Or describe what you want — "make a discography reel for Drudkh" — and the skill triggers automatically.

## Workflow

1. **Research** — looks up the band's studio discography (Wikipedia + corroboration), computes per-album timing
2. **Create folders + PAUSE** — creates `<Band> Discography/NN_<Album>_(<Year>)/video/` and `audio/` for every studio album; waits for you to drop in one video and one audio file per album
3. **Scan & validate** — verifies all asset folders before assembly
4. **Assemble & export** — builds per-album segments, concatenates with crossfades, exports two MP4s and metadata

## Input folder structure (auto-created in Phase 2)

```
<Band Name> Discography/
├── 01_<Album1>_(<Year1>)/
│   ├── video/    # exactly 1 video clip
│   └── audio/    # exactly 1 audio sample
├── 02_<Album2>_(<Year2>)/
│   ├── video/
│   └── audio/
└── ...
```

## Outputs

| File | Description |
|------|-------------|
| `BANDNAME_Discography_YEARFIRST-YEARLAST.mp4` | Clean version |
| `BANDNAME_Discography_YEARFIRST-YEARLAST_yt.mp4` | YouTube Shorts with subscribe overlay at t=20s |
| `BANDNAME_Discography_metadata.md` | EN + UA titles, album list, hashtags |

## Requirements

- Python 3
- ffmpeg + ffprobe (with `xfade`, `acrossfade`, `chromakey`, `drawtext` filters)
