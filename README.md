# claude-skill-video-breakdown

Break one already-downloaded short video (社媒 / vlog / 短视频) into a self-contained, packable
analysis folder — scene-detected keyframes, contact sheets, per-sequence sub-clips, and a
`TIMELINE.md` that maps every time range to its sub-clip and content. For study, 临摹, or reference.

Downloading is out of scope — start from a local video file.

## Requirements

- `ffmpeg` / `ffprobe` on PATH — `brew install ffmpeg`
- bash (macOS default bash 3.2 is fine). Always run the scripts with `bash <script>`, never `source`
  from zsh — zsh's 1-based arrays would corrupt frame timestamps.

## Use

Hand the agent a local video and ask to "拆解 / 分镜 / 做成时间轴 / 整理关键帧 / 切成片段".
The agent runs two scripts and writes the timeline:

```bash
# 1. Scene-detect + extract one mid-frame per shot + build 3x3 contact sheets
bash scripts/sample.sh "<folder>/<video>" "<folder>" 0.30 432
#                       video               outdir   threshold width

# 2. After grouping shots into sequences.tsv (START<TAB>END<TAB>slug), cut sub-clips
bash scripts/cut_clips.sh "<folder>/<video>" "<folder>/frames/sequences.tsv" "<folder>"
```

`sample.sh` args: `<video> <outdir> [scene_threshold=0.30] [frame_width=432]`. Lower the threshold
for soft-transition videos, raise it for fast-cut montages; raise the width if subtitles are
unreadable in the sheets.

## What it does

1. Scene-detects the video with ffmpeg and extracts one representative mid-frame per shot.
2. Tiles frames into 3×3 contact sheets so the whole video can be read in a few image loads.
3. The agent reads the sheets, transcribes on-screen subtitles, and groups shots into narrative
   sequences.
4. Cuts frame-accurate sub-clips per sequence (re-encoded, so cuts land on exact timestamps).
5. Writes `TIMELINE.md` — the primary deliverable — mapping `time range → sub-clip → content`.

## Output

One folder per video, named after the video:

```
<video-title>/
├── <video-title>.<ext>     # source video (left in place)
├── TIMELINE.md             # primary deliverable: sequence timeline + shot table
├── README.md               # optional: source metadata, only if captured upstream
├── clips/   seqNN_<slug>_START-END.mp4
└── frames/  shotNN_START-END.jpg + shots.tsv + _sheets/sheet_NN.jpg
```

Full folder spec, `TIMELINE.md` / `README.md` templates, and all tuning/grouping heuristics live in
[`references/output-structure.md`](references/output-structure.md).

## Troubleshooting

- **`ffmpeg not found`** — `brew install ffmpeg`.
- **Cuts missed / over-segmented** — tune `sample.sh` arg 3 (threshold): lower to `0.20`, raise to
  `0.40`. Re-run; each run clears old frames.
- **Subtitles unreadable in sheets** — raise `sample.sh` arg 4 (width) to `540`+.
- **Mangled timestamps / garbled TSV rows** — you ran a script under zsh via `source`. Always use
  `bash scripts/sample.sh …`.

## Credits

[Jiaxin Kou 寇佳新](https://github.com/kjx-talesofai) · [Neta Art 捏Ta](https://www.neta.art)

---

MIT License © 2026 Jiaxin Kou 寇佳新
