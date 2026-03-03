# Changelog

## [Unreleased]

### Changed (`vinyl-reel`) — 0.1.6
- Subscribe overlay now appears at t=20s (was t=30s)

### Changed (`discography-reel`) — 0.1.2
- Subscribe overlay now appears at t=20s (was t=30s); skip-condition updated to `total_sec <= 20`

## [0.1.5] – 2026-02-28

### Changed (`vinyl-reel`)
- Subscribe animation overlay: added `eof_action=pass` so the base video continues cleanly after the animation ends, preventing last-frame freeze
- Updated `ffmpeg_patterns.md` subscribe overlay example to use `-itsoffset 30` on the full assembled video (replaces outdated single-clip approach)

## 2026-02-28

### Added
- `discography-reel` plugin 0.1.0: ≤59 s 9:16 discography reel showcasing a band's complete studio discography — per-album clips and audio, chronological crossfade assembly, album name overlay, EN + UA metadata, YouTube Shorts subscribe overlay; suggests splitting into two parts when timing per album falls below 4 s

### Changed
- `discography-reel` 0.1.1: Phase 1 now researches and suggests one audio sample per album — the most popular and most immediately catchy track; suggestion shown in the discography table (♪) and referenced in the Phase 2 asset-collection prompt

## [0.1.4] – 2026-02-25

### Changed (`vinyl-reel`)
- Added collection-opener segment at the start of the reel
- Subscribe CTA overlay applied at t=30 s for YouTube Shorts export
- Updated plugin description

## [0.1.3] – 2026-02-24

### Changed (`vinyl-reel`)
- UA output is audio track only — no separate UA video export
- Background music ducks only during voiceover pauses longer than 1 s
- Removed voiceover trim step from workflow
- No em dashes in generated metadata; use plain hyphens

## [0.1.0] – 2026-02-23

### Added
- `vinyl-reel` plugin: produces 9:16 YouTube Shorts and Instagram Reels from raw vinyl unboxing footage, with bilingual (EN/UA) voiceover and smart background music ducking
