#!/bin/bash
# Mix voiceover with background music.
#
# Audio design:
#   - Background music: all samples from audio/ concatenated with 1s crossfades
#   - Voiceover starts at 3 seconds into the video (3s of music-only intro)
#   - Background at 100% when no voiceover is speaking (intro + long pauses + tail)
#   - Background ducked to 22% while voiceover speech is active
#   - Short pauses under 1s stay ducked (background does NOT rise back up)
#   - Smooth 0.5s ramps between 22% and 100% at every transition
#   - Voiceover always at 100% volume
#
# Usage: bash mix_audio.sh <working-folder> <video-duration> <voiceover-path> [output-path]
#
# Output defaults to <working-folder>/.work/mixed_audio.wav

set -e

WORKING_FOLDER="$1"
VIDEO_DURATION="$2"
VOICEOVER="$3"
OUTPUT_PATH="${4:-$WORKING_FOLDER/.work/mixed_audio.wav}"
WORK_DIR="$WORKING_FOLDER/.work"

if [ -z "$WORKING_FOLDER" ] || [ -z "$VIDEO_DURATION" ] || [ -z "$VOICEOVER" ]; then
    echo "Usage: bash mix_audio.sh <working-folder> <video-duration> <voiceover-path> [output-path]" >&2
    exit 1
fi

mkdir -p "$WORK_DIR"
mkdir -p "$(dirname "$OUTPUT_PATH")"

AUDIO_DIR="$WORKING_FOLDER/audio"

# ── Step 1: Concatenate all background music samples with 1s crossfades ──

echo "=== Concatenating background samples ==="

SAMPLES=()
for ext in m4a mp3 wav aac flac ogg; do
    while IFS= read -r -d '' f; do
        SAMPLES+=("$f")
    done < <(find "$AUDIO_DIR" -maxdepth 1 -name "*.$ext" -print0 2>/dev/null | sort -z)
done

if [ ${#SAMPLES[@]} -eq 0 ]; then
    echo "Error: No audio samples found in $AUDIO_DIR" >&2
    exit 1
fi

echo "Found ${#SAMPLES[@]} audio samples"

if [ ${#SAMPLES[@]} -eq 1 ]; then
    ffmpeg -y -i "${SAMPLES[0]}" -ar 44100 -ac 2 "$WORK_DIR/background.wav" 2>/dev/null
else
    # Build inputs and filter chain for sequential crossfades
    INPUTS=""
    for i in "${!SAMPLES[@]}"; do
        INPUTS="$INPUTS -i \"${SAMPLES[$i]}\""
    done

    FILTER="[0:a][1:a]acrossfade=d=1:c1=tri:c2=tri"
    if [ ${#SAMPLES[@]} -gt 2 ]; then
        for ((i=2; i<${#SAMPLES[@]}; i++)); do
            FILTER="$FILTER[a$((i-1))];[a$((i-1))][$i:a]acrossfade=d=1:c1=tri:c2=tri"
        done
    fi
    FILTER="$FILTER[bg_out]"

    eval ffmpeg -y $INPUTS -filter_complex "\"$FILTER\"" -map '"[bg_out]"' -ar 44100 -ac 2 "$WORK_DIR/background.wav" 2>/dev/null
fi

BG_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$WORK_DIR/background.wav")
echo "Background track: ${BG_DURATION}s"

# ── Step 2: Prepare voiceover (convert to WAV, full track — no trimming) ──

echo "=== Preparing voiceover ==="

ffmpeg -y -i "$VOICEOVER" -ar 44100 -ac 2 "$WORK_DIR/voiceover_trimmed.wav" 2>/dev/null

VO_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$WORK_DIR/voiceover_trimmed.wav")
echo "Voiceover: ${VO_DURATION}s"

# ── Step 3: Generate volume envelope for background music ──
#
# Detect silence/speech in the voiceover to know when to duck the background.
# Voiceover starts at 3s in the video (we delay it by 3s below).
# Background is at 1.0 (100%) before voiceover and during pauses,
# and at 0.1 (10%) while speech is active.
# Transitions are 0.5s smooth linear ramps.

echo "=== Generating volume envelope ==="

VOLUME_EXPR=$(python3 << 'PYTHON'
import subprocess, re, sys, os

voiceover = os.environ.get("VO_FILE")
start_offset = float(os.environ.get("VO_OFFSET", "3.0"))
transition   = float(os.environ.get("VO_TRANS",  "0.5"))
low_vol      = 0.22
high_vol     = 1.0

# Detect silence periods in the trimmed voiceover
result = subprocess.run(
    ["ffmpeg", "-i", voiceover, "-af", "silencedetect=noise=-40dB:d=0.3", "-f", "null", "-"],
    capture_output=True, text=True
)
out = result.stderr

silence_starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", out)]
silence_ends   = [float(x) for x in re.findall(r"silence_end: ([\d.]+)",   out)]
silence_ivs    = list(zip(silence_starts[:len(silence_ends)], silence_ends))

total = float(subprocess.run(
    ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", voiceover],
    capture_output=True, text=True
).stdout.strip())

# Build speech segments (gaps between silence intervals)
speech_segs = []
pos = 0.0
for ss, se in silence_ivs:
    if ss > pos + 0.1:
        speech_segs.append((pos, ss))
    pos = se
if pos < total - 0.1:
    speech_segs.append((pos, total))

# Shift by start_offset (voiceover enters at 3s in the video)
shifted = [(s + start_offset, e + start_offset) for s, e in speech_segs]

# Build control points: list of (time, volume)
# Between speech segments (pauses + before/after): high_vol
# During speech: low_vol, with linear ramps at boundaries
points = [(0.0, high_vol)]
for seg_start, seg_end in shifted:
    ramp_dn_end = seg_start + transition
    ramp_up_end = seg_end   + transition
    # Ensure monotonic time
    if points[-1][0] < seg_start:
        points.append((seg_start, high_vol))
    points.append((ramp_dn_end, low_vol))
    points.append((seg_end,     low_vol))
    points.append((ramp_up_end, high_vol))

# Deduplicate and sort
seen = {}
for t, v in points:
    key = round(t, 4)
    if key not in seen:
        seen[key] = v
sorted_pts = sorted(seen.items())

# Build piecewise-linear ffmpeg volume expression
# Uses if(between(t,t0,t1), linear_interp, ...) evaluated per frame
expr = str(high_vol)
for i in range(len(sorted_pts) - 1):
    t0, v0 = sorted_pts[i]
    t1, v1 = sorted_pts[i + 1]
    dt = t1 - t0
    if dt < 0.001:
        continue
    if abs(v1 - v0) < 0.001:
        seg_expr = f"{v0:.4f}"
    else:
        seg_expr = f"{v0:.4f}+({v1:.4f}-{v0:.4f})*(t-{t0:.4f})/{dt:.4f}"
    expr = f"if(between(t,{t0:.3f},{t1:.3f}),{seg_expr},{expr})"

print(expr)
PYTHON
)

# Export env vars for the Python heredoc above
export VO_FILE="$WORK_DIR/voiceover_trimmed.wav"
export VO_OFFSET="3.0"
export VO_TRANS="0.5"

# Re-run with env vars properly set
VOLUME_EXPR=$(VO_FILE="$WORK_DIR/voiceover_trimmed.wav" VO_OFFSET="3.0" VO_TRANS="0.5" python3 - << 'PYTHON'
import subprocess, re, sys, os

voiceover    = os.environ["VO_FILE"]
start_offset = float(os.environ["VO_OFFSET"])
transition   = float(os.environ["VO_TRANS"])
low_vol      = 0.22
high_vol     = 1.0
min_pause    = 1.0  # background only rises for pauses longer than this

result = subprocess.run(
    ["ffmpeg", "-i", voiceover, "-af", "silencedetect=noise=-40dB:d=0.3", "-f", "null", "-"],
    capture_output=True, text=True
)
out = result.stderr

silence_starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", out)]
silence_ends   = [float(x) for x in re.findall(r"silence_end: ([\d.]+)",   out)]
silence_ivs    = list(zip(silence_starts[:len(silence_ends)], silence_ends))

total = float(subprocess.run(
    ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", voiceover],
    capture_output=True, text=True
).stdout.strip())

# Build raw speech segments (gaps between silence intervals)
raw_segs = []
pos = 0.0
for ss, se in silence_ivs:
    if ss > pos + 0.1:
        raw_segs.append((pos, ss))
    pos = se
if pos < total - 0.1:
    raw_segs.append((pos, total))

# Merge speech segments separated by short silences (< min_pause).
# Background stays ducked through short pauses; only rises on real pauses.
speech_segs = []
for seg in raw_segs:
    if not speech_segs:
        speech_segs.append(list(seg))
    else:
        gap = seg[0] - speech_segs[-1][1]
        if gap < min_pause:
            speech_segs[-1][1] = seg[1]  # extend through the short silence
        else:
            speech_segs.append(list(seg))
speech_segs = [tuple(s) for s in speech_segs]

shifted = [(s + start_offset, e + start_offset) for s, e in speech_segs]

points = [(0.0, high_vol)]
for seg_start, seg_end in shifted:
    ramp_dn_end = seg_start + transition
    ramp_up_end = seg_end   + transition
    if points[-1][0] < seg_start:
        points.append((seg_start, high_vol))
    points.append((ramp_dn_end, low_vol))
    points.append((seg_end,     low_vol))
    points.append((ramp_up_end, high_vol))

seen = {}
for t, v in points:
    key = round(t, 4)
    if key not in seen:
        seen[key] = v
sorted_pts = sorted(seen.items())

expr = str(high_vol)
for i in range(len(sorted_pts) - 1):
    t0, v0 = sorted_pts[i]
    t1, v1 = sorted_pts[i + 1]
    dt = t1 - t0
    if dt < 0.001:
        continue
    if abs(v1 - v0) < 0.001:
        seg_expr = f"{v0:.4f}"
    else:
        seg_expr = f"{v0:.4f}+({v1:.4f}-{v0:.4f})*(t-{t0:.4f})/{dt:.4f}"
    expr = f"if(between(t,{t0:.3f},{t1:.3f}),{seg_expr},{expr})"

print(expr)
PYTHON
)

echo "Volume envelope generated (${#VOLUME_EXPR} chars)"

FADE_OUT_START=$(python3 -c "print(max(0, float('$VIDEO_DURATION') - 2))")

# ── Step 4: Mix voiceover + background with dynamic volume ──

echo "=== Mixing audio ==="

# Voiceover is delayed by 3000ms (adelay) to start at t=3 in the video.
# Background loops/pads to fill the full video duration, then volume envelope applied.
# Both streams mixed at equal level (normalize=0), limiter prevents clipping.

ffmpeg -y \
    -i "$WORK_DIR/voiceover_trimmed.wav" \
    -i "$WORK_DIR/background.wav" \
    -filter_complex "
        [0:a]adelay=3000|3000,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo[vo_delayed];
        [1:a]apad=whole_dur=${VIDEO_DURATION},atrim=0:${VIDEO_DURATION},asetpts=PTS-STARTPTS,aformat=sample_fmts=fltp:sample_rates=44100:channel_layouts=stereo,volume='${VOLUME_EXPR}':eval=frame,afade=t=in:st=0:d=1,afade=t=out:st=${FADE_OUT_START}:d=2[bg_final];
        [vo_delayed][bg_final]amix=inputs=2:duration=longest:normalize=0[audio_mix];
        [audio_mix]alimiter=limit=0.95[audio_final]" \
    -map "[audio_final]" \
    -ar 44100 -ac 2 \
    "$OUTPUT_PATH" 2>/dev/null

MIX_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$OUTPUT_PATH")
echo "Final mix: ${MIX_DURATION}s"
echo "Output: $OUTPUT_PATH"
