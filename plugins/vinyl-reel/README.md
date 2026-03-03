# vinyl-reel

Produces polished 9:16 vinyl unboxing reels from raw phone footage. Outputs YouTube Shorts and Instagram Reels with background music, text overlays, and a bilingual (EN/UA) voiceover you record yourself.

## Install

```
/plugin marketplace add scorpionium/vlad-creative
/plugin install vinyl-reel@vlad-creative
```

## Usage

```
/vinyl-reel /path/to/Album-Folder
```

Or just describe what you want — "make a reel for this album", "vinyl unboxing video" — and the skill triggers automatically.

## Input folder structure

```
Album Name/
├── video/    # raw clips (.mp4 .mov .avi .mkv .m4v)
└── audio/    # background music samples (.m4a .mp3 .wav .aac .flac .ogg)
```

## Outputs

| File | Description |
|------|-------------|
| `<Album>_Reel.mp4` | YouTube Shorts (EN) with subscribe overlay at t=20s |
| `<Album>_Reel_Clean.mp4` | Instagram Reels (EN), no overlay |
| `<Album>_Audio_UA.m4a` | Ukrainian audio track — upload via YouTube → Subtitles → Add language |
| `youtube_metadata.md` | EN + UA titles, descriptions, hashtags |

## Requirements

- Python 3
- ffmpeg + ffprobe (with `silencedetect`, `chromakey`, `drawtext` filters)
