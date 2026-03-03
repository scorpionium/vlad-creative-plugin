# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repo is a Claude Code **plugin marketplace** for creative and media production skills. Plugins live under `plugins/`, each with its own manifest and skill/command files. New plugins are added as subdirectories there, plus an entry in `.claude-plugin/marketplace.json`.

## Repo Structure

```
vlad-creative-plugin/          ← marketplace root
├── .claude-plugin/
│   └── marketplace.json       ← marketplace catalog (lists all plugins)
├── plugins/
│   └── vinyl-reel/            ← first plugin
│       ├── .claude-plugin/
│       │   └── plugin.json    ← plugin manifest
│       ├── commands/          ← slash command (/vinyl-reel)
│       └── skills/
│           └── vinyl-reel/    ← skill with SKILL.md + scripts/ + references/ + assets/
└── LICENSE
```

To add a new plugin: create `plugins/<plugin-name>/` with its own `.claude-plugin/plugin.json`, then add an entry to `.claude-plugin/marketplace.json`.

## Installing This Marketplace

```
/plugin marketplace add scorpionium/vlad-creative
/plugin install vinyl-reel@vlad-creative
```

## vinyl-reel Plugin

Automates 9:16 vertical vinyl unboxing reels (YouTube Shorts / Instagram Reels) from raw phone footage. The workflow is bilingual (English + Ukrainian) and outputs three MP4 files plus YouTube metadata.

This is a **declarative workflow** — no build step, no package manager, no test runner. Everything runs within Claude Code using ffmpeg, Python 3, and bash.

### Trigger

- `/vinyl-reel /path/to/Album-Folder`
- Describe a vinyl reel task in natural language (skill auto-triggers)

### Expected Input

```
Album Name/
├── video/    # raw clips (.mp4 .mov .avi .mkv .m4v)
└── audio/    # background music samples (.m4a .mp3 .wav .aac .flac .ogg)
```

### System Dependencies

**Python 3**, **ffmpeg**, **ffprobe** with filters: `silencedetect`, `acrossfade`, `adelay`, `volume`, `afade`, `alimiter`, `chromakey`, `drawtext`. Text overlays use `LiberationSans` or `DejaVuSans`.

### 6-Phase Workflow

| Phase | Tool | Pause? |
|-------|------|--------|
| 1. Scan & catalog clips | `analyze_clips.py` (ffprobe) | No |
| 2. Research album | Web search | No |
| 3. Write EN + UA voiceover scripts | Claude | **Yes — user approves scripts** |
| 4. Record voiceover | User records & drops MP3s in folder | **Yes — wait for user confirmation** |
| 5. Arrange, mix, assemble video | ffmpeg + `mix_audio.sh` | No |
| 6. Export 3 outputs + metadata | ffmpeg + chromakey | No |

### Key Scripts

**`scripts/analyze_clips.py`** — probes each video with ffprobe, extracts a thumbnail at t=1s, outputs a JSON catalog with duration, dimensions, orientation.

**`scripts/mix_audio.sh`** — audio mixing: concatenates all samples with 1s crossfades, detects speech/silence in the voiceover, ducks background to **10%** during speech / **100%** during pauses (0.5s smooth transitions), voiceover starts at **t=3s**.

### Reference Guides (read during execution)

- `references/ffmpeg_patterns.md` — ffmpeg commands for 1080×1920 scaling, text overlays, concat, chromakey, CRF-18 H.264
- `references/voiceover_style.md` — script structure, ~30s speech + 2–3 × 5s pauses, bilingual tone guidance

### Outputs

| File | Description |
|------|-------------|
| `*_yt_shorts_en.mp4` | YouTube Shorts (EN) with subscribe overlay at t=20s |
| `*_instagram_en.mp4` | Instagram Reels (EN), clean |
| `*_Audio_UA.m4a` | Ukrainian audio track — upload via YouTube Subtitles → Add language |
| `*_metadata.md` | EN + UA titles, descriptions, hashtags |
