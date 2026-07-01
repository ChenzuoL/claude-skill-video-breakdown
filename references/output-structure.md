# Output Structure & Templates

The deliverable is ONE self-contained, packable folder per video. Produce exactly this layout.

## Folder layout

```
<video-title>/
├── <video-title>.<ext>        # the source video (leave in place)
├── TIMELINE.md                # PRIMARY deliverable — sequence timeline + shot table
├── README.md                  # OPTIONAL — source metadata, only if title/desc/comments are on hand
├── clips/                     # sequence sub-clips (from cut_clips.sh)
│   └── seqNN_<slug>_START-END.mp4
└── frames/                    # keyframes (from sample.sh)
    ├── shotNN_START-END.jpg   # one representative frame per shot; filename = start-end seconds
    ├── shots.tsv              # shot<TAB>start<TAB>end<TAB>frame_path
    └── _sheets/
        └── sheet_NN.jpg       # 3x3 contact sheets (sheet_01 = shots 1-9, 02 = 10-18, …)
```

Keep the video's own name as the folder name (sanitize only characters illegal on disk). Never invent
a generic folder name when the real title is known.

## TIMELINE.md template

Fill this structure. Keep the top matter, the sequence table, and the shot table; adapt section
wording to the actual video. Times are `MM:SS.s`; keep the shot table in seconds to match filenames.

```markdown
# 时间轴 · <标题>

> 本文件是这条视频的分镜/序列索引，供后续 agent 快速定位「某个时间段 = 哪个子片段 = 讲了什么」。
> 视频<AI生成/实拍>，<竖屏/横屏> <W>×<H>，<fps>fps，总时长 <DUR>s。
> 采样：ffmpeg 场景检测（scene><阈值>）切出 <N> 个镜头，每镜取中间帧，再按叙事归并为 <M> 个 sequence。
> 字幕（若有）已从关键帧转写。

## 文件夹结构
<paste the tree above, trimmed to what exists>

## 主要人物 / 元素
| 代号 | 描述 | 出现 |
|------|------|------|
| … | … | shotNN–NN |

## 序列时间轴（<M> 个 Sequence）
| # | 时间 | 时长 | 子片段 | 内容 | 关键台词/字幕 |
|---|------|------|--------|------|----------------|
| S1 | 00:00.0–00:11.0 | 11.0s | `seq01_intro` | … | … |

## 镜头级明细（<N> shot）
| shot | 时间(s) | 归属 | 画面 | 字幕(原文 / 译文) |
|------|---------|------|------|--------------------|
| 01 | 000.00–006.10 | S1 | … | … / … |

## 结构/形态观察（供临摹参考）
- 模板 / 叙事结构：…
- 节奏（镜头数、平均时长、空镜与特效镜的作用）：…
- 梗点 / 记忆点：…
- 人设与服化道一致性：…
```

## README.md template (optional)

Only produce this when source metadata (title, description, tags, interaction counts, comments) was
actually captured — e.g. handed over from the download/scrape step. Do NOT fabricate numbers.

```markdown
# <标题>

> 素材归档，用于学习 / 临摹参考。

## 基本信息
| 项目 | 内容 |
|------|------|
| 标题 | … |
| 作者 | … |
| 发布地 / 时间 | … |
| 类型 | 视频（<W>×<H>，<codec>，约 <MM:SS>） |
| 原链接 | … |
| 本地文件 | `<video-title>.<ext>` |

## 描述 / 文案
> …

**话题标签：** `#…`

## 互动数据
| 点赞 | 收藏 | 评论 | 分享 |
|------|------|------|------|
| … | … | … | … |

## 评论区精选
- **<用户>**（<地区> · 👍<n>）：…

## 观察小结
- …
```

## Heuristics

- **Scene threshold** (`sample.sh` arg 3, default `0.30`): lower to `0.20` if cuts are missed on a
  soft-transition video; raise to `0.40` for a fast-cut montage that over-segments. Re-run and re-read
  the sheets; the script clears old frames each run.
- **Frame width** (arg 4, default `432`): raise to `540`+ only if subtitles are still unreadable in the
  contact sheets.
- **Reading sheets**: read `_sheets/sheet_*.jpg` in order. Sheet_01 = shots 1-9, sheet_02 = 10-18, etc.
  (row-major). Transcribe on-screen text verbatim; bilingual subtitles → capture both lines. If a shot's
  key subtitle isn't in its mid-frame, pull an extra frame:
  `ffmpeg -ss <t> -i <video> -frames:v 1 -vf scale=540:-1 frames/shotNN_extra.jpg`.
- **Grouping shots into sequences**: merge adjacent shots that share a location, speaker, topic, or
  narrative beat (an interview Q→A→reaction is one sequence; an establishing empty-room shot belongs to
  the sequence it introduces). Aim for a handful of sequences, not one-per-shot. Write them to a
  `sequences.tsv` (`START<TAB>END<TAB>slug`) whose boundaries align to shot boundaries from `shots.tsv`,
  covering 0 → duration with no gaps. Then run `cut_clips.sh`.
- **Slugs**: short english or pinyin, hyphenated (`interview-patronus`, `to-three-broomsticks`).
