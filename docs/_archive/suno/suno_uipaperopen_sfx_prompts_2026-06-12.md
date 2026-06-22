# Suno uiPaperOpen 音效 Prompt：UI 弹窗/面板展开（宣纸声）

> 日期：2026-06-12
> 目标：生成 `SfxId.uiPaperOpen`（弹窗/面板展开 UI 反馈音）。enum 定义 + 调用已在（`lib/shared/widgets/wuxia_ui/paper_dialog.dart:35`），**但素材文件 `assets/audio/sfx/uiPaperOpen.mp3` 不存在 + 此前无 prompt**（`audio_asset_generation_guide.md` 未覆盖）→ 当前运行期静默 no-op（`SoundManager._guard` 吞异常）。
> 方向：**克制、轻、不抢戏的「宣纸展开 / 卷轴轻开」声**。这是每次开弹窗/面板都会响的高频 UI 音，必须**极短、低存在感**，只给一缕纸感反馈，不能是音乐/jingle、不能有旋律或长尾。水墨母题：宣纸、卷轴、纸页。
> 模式：Suno `Sounds` / `One-Shot`。目标 **0.25–0.55s**（落位裁切 + 归一到与 `uiTap`/`uiTabSwitch` 同产线 UI 响度，比 jingle 类低 6–8dB，避免高频弹窗扰耳）。
> 落位：放 `assets/audio/sfx/uiPaperOpen.mp3`（文件名即接线，零 Dart 改动）。调用路径已跑通，素材到位即生效。

## uiPaperOpen（弹窗/面板展开 UI 音）

### uipaperopen_v1_01 — 宣纸轻展
```text
A very short, soft UI sound of a sheet of rice paper (xuan paper) being gently unfolded, under half a second. A single subtle paper rustle with a light airy texture, delicate and restrained — a quiet, tasteful interface feedback for opening a panel in a Chinese wuxia game. Soft, low-presence, not attention-grabbing. No music, no melody, no chime, no vocals, no reverb tail, no drums.
```

### uipaperopen_v1_02 — 卷轴轻开
```text
A tiny one-shot interface sound of a small paper scroll opening, 0.3 to 0.5 seconds. A brief, soft paper slide / unroll with a faint air movement, elegant and minimal — the sound of a wuxia menu or dialog sliding open. Gentle and unobtrusive, clean and dry. No musical notes, no bell, no whoosh sweep, no vocals, no long tail.
```

### uipaperopen_v1_03 — 纸页翻动（脆而短）
```text
A crisp, very short page-turn UI sound for a wuxia game menu, about 0.3 seconds. A single light paper flip with a soft papery snap, refined and quiet, used as feedback when a panel appears. Subtle and low in level, not startling. Real paper texture, dry and clean. No music, no chime, no vocal, no reverb, no rhythm, no long decay.
```

### uipaperopen_v1_04 — 宣纸 + 微气感（最含蓄）
```text
An extremely subtle UI feedback sound for opening a paper panel in a calligraphy-themed wuxia game, under 0.5 seconds. A faint xuan-paper unfold layered with a barely-there breath of air, soft, refined, almost ambient — a whisper of paper, not a loud effect. Should sit quietly under the interface, low presence, tasteful. No melody, no chime, no bell, no drums, no vocals, no reverb wash, no long tail.
```

## 回收与落位
1. 生成后下载到桌面任意文件夹（如 `~/Desktop/uipaperopen_v1_20260612/`），把路径告诉我。
2. 我做静音裁切体检（沿 v2 技术处理体例：响度/峰值/头尾静音）+ afplay 与 `uiTap.mp3`/`uiTabSwitch.mp3` 对放，确认音量同档、不抢戏、开弹窗不扰耳。
3. 选定后放 `assets/audio/sfx/uiPaperOpen.mp3`，`audio_assets_test.dart` 素材齐全测会自动纳入校验；重编 release 包真玩复验（开各面板/弹窗听纸感反馈）。
