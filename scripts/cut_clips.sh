#!/usr/bin/env bash
# cut_clips.sh — cut frame-accurate sequence sub-clips from a TSV that Claude authors
# after grouping shots into narrative sequences.
#
# Usage:
#   bash cut_clips.sh <video> <sequences.tsv> <outdir>
#
# sequences.tsv — one line per sequence, TAB-separated; blank lines and '#' comments ignored:
#   START<TAB>END<TAB>SLUG
# where START/END are seconds (float ok) and SLUG is a short english/pinyin label.
# Example:
#   0.0      11.033   intro
#   11.033   37.133   to-three-broomsticks
#   37.133   55.4     interview-perks
#
# Re-encodes (not stream-copy) so cuts land on exact timestamps instead of snapping
# to keyframes. Outputs:
#   <outdir>/clips/seqNN_<slug>_START-END.mp4
set -eu

VIDEO=${1:?usage: cut_clips.sh <video> <sequences.tsv> <outdir>}
TSV=${2:?usage: cut_clips.sh <video> <sequences.tsv> <outdir>}
OUTDIR=${3:?usage: cut_clips.sh <video> <sequences.tsv> <outdir>}

command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)" >&2; exit 1; }
[ -f "$VIDEO" ] || { echo "video not found: $VIDEO" >&2; exit 1; }
[ -f "$TSV" ]   || { echo "sequences tsv not found: $TSV" >&2; exit 1; }

CLIPS="$OUTDIR/clips"
mkdir -p "$CLIPS"

i=0
while IFS=$'\t' read -r s e slug || [ -n "${s:-}" ]; do
  case "${s:-}" in ''|'#'*) continue;; esac
  [ -n "${e:-}" ] || { echo "skip malformed line (no end): $s" >&2; continue; }
  i=$((i+1))
  idx=$(printf "%02d" "$i")
  dur=$(awk -v a="$s" -v b="$e" 'BEGIN{printf "%.3f", b-a}')
  ss=$(awk -v a="$s" 'BEGIN{printf "%05.1f",a}')
  ee=$(awk -v b="$e" 'BEGIN{printf "%05.1f",b}')
  # sanitize slug: spaces -> '-', keep only [alnum . _ -]
  cslug=$(printf "%s" "${slug:-seq}" | tr ' ' '-' | tr -cd 'A-Za-z0-9._-')
  [ -n "$cslug" ] || cslug="seq"
  out="$CLIPS/seq${idx}_${cslug}_${ss}-${ee}.mp4"
  # -nostdin: this loop reads the TSV on stdin; without it ffmpeg would consume the
  # remaining TSV bytes and corrupt the next `read` (rows would come out mangled).
  ffmpeg -hide_banner -nostdin -loglevel error -y -ss "$s" -i "$VIDEO" -t "$dur" \
    -c:v libx264 -preset veryfast -crf 20 -c:a aac -b:a 128k "$out"
  echo "seq${idx}: ${ss}-${ee}s -> $out" >&2
done < "$TSV"

echo "OK: ${i} sequence clip(s) in ${CLIPS}" >&2
