#!/usr/bin/env bash
# sample.sh — scene-detect a video, extract ONE representative frame per shot,
# and tile the frames into 3x3 contact sheets for efficient reading.
#
# Deterministic and safe under any login shell (written for bash 3.2 = macOS default;
# always invoke via `bash sample.sh ...` or execute directly — do NOT `source` from zsh,
# whose 1-based arrays would corrupt the frame timestamps).
#
# Usage:
#   bash sample.sh <video> <outdir> [scene_threshold] [frame_width]
#     video            path to the source video
#     outdir           analysis folder; frames/ and frames/_sheets/ are created inside
#     scene_threshold  ffmpeg scene-score cut threshold (default 0.30; lower => more cuts)
#     frame_width      px width of extracted frames (default 432; keep subtitles legible)
#
# Outputs:
#   <outdir>/frames/shotNN_START-END.jpg   one mid-frame per detected shot
#   <outdir>/frames/_sheets/sheet_NN.jpg   contact sheets, 9 shots each (row-major)
#   <outdir>/frames/shots.tsv              TSV: shot<TAB>start<TAB>end<TAB>frame_path
set -eu

VIDEO=${1:?usage: sample.sh <video> <outdir> [scene_threshold] [frame_width]}
OUTDIR=${2:?usage: sample.sh <video> <outdir> [scene_threshold] [frame_width]}
THRESH=${3:-0.30}
WIDTH=${4:-432}

command -v ffmpeg  >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)"  >&2; exit 1; }
command -v ffprobe >/dev/null || { echo "ffprobe not found (brew install ffmpeg)" >&2; exit 1; }
[ -f "$VIDEO" ] || { echo "video not found: $VIDEO" >&2; exit 1; }

FRAMES="$OUTDIR/frames"
SHEETS="$FRAMES/_sheets"
mkdir -p "$SHEETS"
rm -f "$FRAMES"/shot*.jpg "$SHEETS"/*.jpg 2>/dev/null || true

# total duration in seconds (float)
DUR=$(ffprobe -v error -show_entries format=duration -of default=nk=1:nw=1 "$VIDEO")

# collect scene-cut timestamps (start of each new shot), ascending.
# bash 3.2 has no mapfile -> read via process substitution into an array.
CUTS=()
while IFS= read -r t; do
  [ -n "$t" ] && CUTS+=("$t")
done < <(
  ffmpeg -hide_banner -nostats -i "$VIDEO" \
    -filter_complex "select='gt(scene,$THRESH)',metadata=print:file=-" \
    -an -f null - 2>/dev/null \
  | awk -F'pts_time:' '/pts_time/{printf "%.3f\n", $2+0}'
)

# boundary list: 0 + interior cuts (skip the near-0 first frame) + duration
BOUNDS=(0)
for t in ${CUTS[@]+"${CUTS[@]}"}; do
  if awk -v x="$t" 'BEGIN{exit !(x>0.2)}'; then BOUNDS+=("$t"); fi
done
BOUNDS+=("$DUR")

N=$(( ${#BOUNDS[@]} - 1 ))
echo "duration=${DUR}s  threshold=${THRESH}  shots=${N}" >&2

: > "$FRAMES/shots.tsv"
i=0
while [ "$i" -lt "$N" ]; do
  s=${BOUNDS[$i]}; e=${BOUNDS[$((i+1))]}
  mid=$(awk -v a="$s" -v b="$e" 'BEGIN{printf "%.3f",(a+b)/2}')
  ss=$(awk -v a="$s" 'BEGIN{printf "%06.2f",a}')
  ee=$(awk -v b="$e" 'BEGIN{printf "%06.2f",b}')
  idx=$(printf "%02d" $((i+1)))
  rel="frames/shot${idx}_${ss}-${ee}.jpg"
  ffmpeg -hide_banner -nostdin -loglevel error -ss "$mid" -i "$VIDEO" \
    -frames:v 1 -vf "scale=${WIDTH}:-1" "$OUTDIR/$rel"
  printf "%s\t%s\t%s\t%s\n" "$idx" "$ss" "$ee" "$rel" >> "$FRAMES/shots.tsv"
  i=$((i+1))
done

# contact sheets: 3x3 tiles, ceil(N/9) sheets, row-major by shot index
NSHEETS=$(( (N + 8) / 9 ))
ffmpeg -hide_banner -loglevel error -pattern_type glob -i "$FRAMES/shot*.jpg" \
  -vf "scale=360:-1,tile=3x3:margin=8:padding=6:color=white" \
  -frames:v "$NSHEETS" "$SHEETS/sheet_%02d.jpg"

echo "OK: ${N} shots -> ${FRAMES}  (${NSHEETS} contact sheet(s) in _sheets/)" >&2
echo "Next: read ${SHEETS}/sheet_*.jpg  (sheet_01 = shots 1-9, sheet_02 = 10-18, ...)," >&2
echo "      transcribe on-screen subtitles, then group shots into sequences." >&2
