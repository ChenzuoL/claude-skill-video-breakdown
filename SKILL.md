---
name: video-breakdown
description: Break an already-downloaded short video (社媒/vlog/短视频) into a clean, packable analysis folder — scene-detected keyframes, narrative sequence sub-clips, and a TIMELINE.md index that maps every time range to its sub-clip and content. Use when the user hands over a short video (or a just-downloaded video file) and wants it "拆开/拆解/分镜/做成时间轴/整理关键帧/切成片段" for study, 临摹, or reference. Downloading is out of scope — start from a local video file.
---

# Video Breakdown

Turn one short video into a self-contained folder that a later agent can navigate without re-watching:
scene-based **keyframes**, **contact sheets** to read cheaply, per-sequence **sub-clips**, and a
**TIMELINE.md** mapping `time range → sub-clip → what happens`.

Requires `ffmpeg`/`ffprobe` on PATH (`brew install ffmpeg`). Scripts are `scripts/sample.sh` and
`scripts/cut_clips.sh` — always invoke with `bash <script>` (they use bash arrays; zsh's 1-based
arrays would corrupt frame timestamps).

## Workflow

1. **Locate the video & set up the folder.** Work in a folder named after the video (keep its real
   title). The source video stays inside it. Set `V=<video>` and `D=<folder>`.

2. **Sample keyframes** — one deterministic command:
   ```bash
   bash scripts/sample.sh "$D/<video>" "$D" 0.30 432
   ```
   Produces `$D/frames/shotNN_START-END.jpg`, `$D/frames/shots.tsv`, and 3×3 contact sheets in
   `$D/frames/_sheets/`. Tune the threshold (arg 3) / width (arg 4) per
   `references/output-structure.md` if cuts are missed or subtitles unreadable, and re-run.

3. **Read & understand.** Read `$D/frames/_sheets/sheet_*.jpg` in order (sheet_01 = shots 1-9,
   sheet_02 = 10-18, …). Transcribe on-screen subtitles verbatim (both lines if bilingual). Reading the
   contact sheets — not every frame — is the point: it keeps context small. Pull an extra frame only if
   a shot's key text is missing from its mid-frame.

4. **Group shots into sequences.** Merge adjacent shots sharing a location / speaker / topic / beat
   into a handful of sequences (see grouping heuristic in `references/output-structure.md`). Write a
   `sequences.tsv` — `START<TAB>END<TAB>slug` per line — with boundaries aligned to `shots.tsv`,
   covering 0 → duration with no gaps. Keep this file in `$D/frames/` (or `$D/`).

5. **Cut the sub-clips:**
   ```bash
   bash scripts/cut_clips.sh "$D/<video>" "$D/frames/sequences.tsv" "$D"
   ```
   Produces frame-accurate `$D/clips/seqNN_<slug>_START-END.mp4`.

6. **Write `TIMELINE.md`** (and `README.md` only if source metadata was provided) following the
   templates and folder spec in `references/output-structure.md`. This is the primary deliverable.

7. **Report** the folder tree and the sequence list to the user.

## Output

The full folder layout, the `TIMELINE.md` / `README.md` templates, and all tuning/grouping heuristics
live in **`references/output-structure.md`** — read it before writing the deliverables. Core shape:

```
<video-title>/
├── <video-title>.<ext>     # source
├── TIMELINE.md             # sequence timeline + shot table (primary deliverable)
├── README.md               # optional: source metadata, only if captured
├── clips/  seqNN_<slug>_START-END.mp4
└── frames/ shotNN_START-END.jpg + shots.tsv + _sheets/sheet_NN.jpg
```

## Notes

- **Read sheets, not frames.** For a 1-minute+ video, reading each frame individually blows up context;
  the contact sheets exist so a few image reads cover the whole video.
- **Timestamps must be trustworthy** — the timeline's whole value is time-accuracy. Always run the
  scripts via `bash`; never `source` them from an interactive zsh.
- **Don't fabricate metadata.** Interaction counts, comments, and author info go in `README.md` only
  when actually captured upstream; otherwise omit `README.md`.
