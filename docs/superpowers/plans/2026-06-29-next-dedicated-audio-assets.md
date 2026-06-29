# 音频专属素材补齐计划

**Goal:** 把当前转用的 `battleUlt` / `battleChargeStart` 从“文件存在即可通过”提升为“能明确识别专属素材是否到位”，并产出可直接用于素材生成、筛选、替换的执行材料。

**Branch:** `codex/next-dedicated-audio-assets`

**Acceptance:**

- 保持现有音频播放不退化：`battleUlt` / `battleChargeStart` 当前路径继续可播，缺文件仍由 `SoundManager` 静默 no-op。
- 不用粗糙占位冒充最终素材：工程能标记这两个槽位当前仍是 `temporaryBorrowed`。
- 若无可用专属素材，补齐生成 prompt、manifest 和替换计划。
- Targeted audio tests 与 `flutter analyze` 通过。

## Context

- `docs/spec/playability_phase2_backlog.md` 已把“音频专属素材补齐”列入 2026-06-29 下一阶段待办。
- 现有 `assets/audio/sfx/battleUlt.mp3` / `battleChargeStart.mp3` 已可播放，但 backlog 明确它们分别转用 `realmAdvance_v2_01` 裁切、`defeat_v2_02` 负向预警。
- 主项目 `_suno_candidates` 只有 BGM / jingle 候选，没有 `battleUlt` / `battleChargeStart` 专属候选。

## Tasks

- [x] 读取项目约束、音频 guide、manifest、既有 audio tests。
- [x] 核查 assets/handoff 与主项目 `_suno_candidates`，确认没有可直接入库的专属候选。
- [x] 新增工程只读状态表，明确两个槽位当前为临时转用素材。
- [x] 新增测试，防止“临时转用素材”被误判为最终专属素材。
- [x] 产出 Suno/SFX 生成 prompt 与专属素材 manifest。
- [x] 跑 targeted audio tests 与 `flutter analyze`。
- [x] 提交本分支。

## Current Restore Point

- 状态：已完成并提交。
- 最后完成：`flutter analyze` 与 audio targeted tests 通过。
- 下一步：等待真实专属音频素材产出后，把 `battleUlt.mp3` / `battleChargeStart.mp3` 替换为筛选通过的文件，并把 `dedicated_audio_assets.dart` 状态改为 `finalAsset`。
- 已跑验证：`flutter test test/shared/audio/audio_assets_test.dart test/shared/audio/sfx_for_action_test.dart test/shared/audio/charge_transition_sfx_test.dart test/shared/audio/dedicated_audio_assets_test.dart`；`flutter analyze`。
- 阻塞项：缺外部生成/筛选后的最终专属素材。
