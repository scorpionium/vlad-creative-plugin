# Changelog

## [Unreleased]

### Changed (`vinyl-reel`) — 0.1.6
- Subscribe overlay now appears at t=20s (was t=30s)

### Changed (`discography-reel`) — 0.1.2
- Subscribe overlay now appears at t=20s (was t=30s); skip-condition updated to `total_sec <= 20`

## [0.3.0] – 2026-04-06

### Changed (`vinyl-reel`) — 0.3.0
- **Hook rewrite**: opening shot must now be the most visually dramatic clip (vinyl reveal, spinning disc, unwrapping) — not a shelf or cover shot. A bold scarcity/curiosity text overlay (pressing quantity, colorway, resale value) appears for the first 2 seconds before any voiceover.
- **Voiceover structure**: scripts are now surprise-first / scarcity-first. Opening line must state the most unusual fact about the pressing. "Here's one from my collection" opener is removed from the voice; band popularity signal (niche vs. popular) shapes the hook angle.
- **Thumbnail generation**: new Phase 5c extracts 5 candidate frames at key timestamps (vinyl reveal, cover, turntable, etc.) and generates composite thumbnails with bold BAND NAME + Album Title overlays saved to `thumbnails_export/`.
- **Subscribe overlay timing**: moved from t=20s to final 5 seconds (computed dynamically as `video_duration - 5`). Aligns with Shorts loop boundary for better engagement.
- **Research phase**: Phase 2 now explicitly surfaces scarcity/rarity signals (pressing quantity, colorway name, pressing plant, Discogs resale value) and a band popularity check (Spotify/Last.fm listeners). The single most unusual fact is identified before script writing.
- **Tight-cut mode**: new optional mode targeting 35-45 seconds (vs. standard 55-59s). Tighter clip selection template and shorter voiceover target (~18-22s speech). Offered to the user during mode selection.
- **Music ducking floor**: raised from 10% to 22% during voiceover speech — preserves sonic atmosphere while keeping voice intelligible. `mix_audio.sh` `low_vol` updated accordingly.

## [0.2.0] – 2026-03-16

### Changed (`vinyl-reel`) — 0.2.0
- **No-voiceover mode**: skill now asks whether to include voiceover after Phase 1 scan (or auto-detects from the trigger message). In no-voiceover mode Phase 3 (script writing + recording pauses) is skipped entirely; Phase 4d produces a plain music-only mix (crossfaded samples, no ducking); Phase 5c (UA audio track) is omitted. Voiceover mode behaviour is unchanged.

### Changed (`discography-reel`) — 0.2.0
- **Two videos per album**: each album section is now composed of two sub-clips — `1_cover.*` (cover art footage, capped at 4 s) and `2_turntable.*` (LP on turntable, remainder of the album's time slot). Phase 2 instructs the user to drop both files and collects per-album cover start offsets before assembly begins.
- `scan_assets.py`: now validates exactly 2 video files per album folder and reports them as `cover_video` / `turntable_video` (alphabetical sort) with individual durations.
- **Mixed crossfade durations**: within-album (cover→turntable) transitions use 0.3 s; album-boundary transitions keep 0.5 s. Filter complex now covers `2N-1` transitions across `2N` segments.
- **Audio fade-out**: clean export (Step 4d) applies a 2-second `afade=t=out` over the final 2 seconds of the assembled video. YouTube Shorts export inherits the fade via `-c:a copy` from the 4d output.

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
