# Nightshift Plan - 2026-05-17 二次跑(W17 dispatcher 修复后验证)
Window: 立即 launch → ~6h
Total tasks: 6
Dispatcher interval: 40m (timeout 50m + 30s inter-task buffer)

> **二次跑目标**:验证 dispatcher 修复后 3 处(bash 3.2 兼容 / idempotency / verify 含 build_runner)的健壮性。沿用 W17 首跑全 skippable + 低-中风险体例;主战场切「数据一致性扫描」+「目录审计」+「PROGRESS 行数清理」+「CharacterPanelScreen 边界 test」+「SUMMARY」混合配方。

## T01: encounter id 一致性扫描
- status: pending
- depends: []
- worktree: ../wuxia-idle-T01
- skippable: true
- timeout_min: 45
- risk: low
- goal: |
    扫描 `data/encounters.yaml` 40 id ↔ `data/events/*.yaml` 40 文件 ↔ `data/events/_archive/*.yaml` 6 orphan 双向对账,产出唯一新文件 `docs/handoff/wuxia_encounter_id_consistency_2026-05-17.md`(统计 + 双向对账 + 结论 + 后续维护建议)。0 漂移即基线建立。
    完整 prompt:`.nightshift/prompts/T01.md`。
    不动 lib/ data/ test/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T01.verify.sh
    # = test -f doc + grep 关键章节 + git log + flutter pub get + dart run build_runner + dart analyze
- rollback: |
    git reset --hard HEAD && git clean -fd

## T02: equipment id ↔ lore yaml 一致性扫描
- status: pending
- depends: [T01]
- worktree: ../wuxia-idle-T02
- skippable: true
- timeout_min: 45
- risk: low
- goal: |
    扫描 `data/equipment.yaml` 35 id ↔ `data/lore/*.yaml` 35 文件 双向对账 + 7 阶分布抽样校验,产出唯一新文件 `docs/handoff/wuxia_equipment_lore_id_consistency_2026-05-17.md`。
    完整 prompt:`.nightshift/prompts/T02.md`。
    不动 lib/ data/ test/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T02.verify.sh
    # = test -f doc + grep 关键章节 + git log + flutter pub get + dart run build_runner + dart analyze
- rollback: |
    git reset --hard HEAD && git clean -fd

## T03: CharacterPanelScreen 边界用例
- status: pending
- depends: [T02]
- worktree: ../wuxia-idle-T03
- skippable: true
- timeout_min: 50
- risk: low-mid
- goal: |
    读现有 `test/features/character_panel/presentation/character_panel_screen_test.dart`(431 行 主体例)+ W17 T04 产物 `lineage_panel_screen_edge_test.dart`(245 行 边界模板)学体例。
    新增 3-5 边界用例,产出唯一新文件 `test/features/character_panel/presentation/character_panel_screen_edge_test.dart`(候选:character 主属性极端值 / 无装备态 / 无心法态 / tab 切换序 / school=null 兜底 / 装备 tier 与角色 realm 边界 — 任选 3+)。
    红线遵守约束语义不写瞬时事实(参 `feedback_red_line_test_semantics`)。
    完整 prompt:`.nightshift/prompts/T03.md`。
    不动现有 test 文件,不动 lib/,不动 GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T03.verify.sh
    # = test -f new test + git log + flutter pub get + dart run build_runner + dart analyze + flutter test 新文件全过
- rollback: |
    git reset --hard HEAD && git clean -fd

## T04: PROGRESS.md 行数清理
- status: pending
- depends: [T03]
- worktree: ../wuxia-idle-T04
- skippable: true
- timeout_min: 45
- risk: low
- goal: |
    当前 PROGRESS.md ~83 行,逼近 100 红线。**T04 是唯一允许动 PROGRESS 的 nightshift task**。
    压缩到 < 80 行(留 20 行 buffer):
    - 当前阶段最旧 W16 节日段一句话化
    - 已销账 ~~划掉~~ 条目列表化或一句话归档
    - 强保留最新 W17 段 + 下一步 + 关键约束 + 远程仓库 + 归档段
    完整 prompt:`.nightshift/prompts/T04.md`。
    不动 lib/ data/ test/ docs/ assets/ GDD CLAUDE numbers IDS_REGISTRY。**只动 PROGRESS.md 一个文件**。
- verify: |
    bash .nightshift/prompts/T04.verify.sh
    # = wc -l < 80 + grep 5 个 ## 段保留 + 最新 W17 锚点保留 + git log + flutter pub get + dart run build_runner + dart analyze
- rollback: |
    git reset --hard HEAD && git clean -fd

## T05: lib/ 目录结构审计
- status: pending
- depends: [T04]
- worktree: ../wuxia-idle-T05
- skippable: true
- timeout_min: 45
- risk: low
- goal: |
    对照 CLAUDE.md §3 期望目录结构(`core/{domain,application}/` + `data/` + `features/<X>/{domain,application,presentation}/` 14 feature + `shared/`),扫描实际 lib/ 树,产出唯一新文件 `docs/handoff/wuxia_lib_structure_audit_2026-05-17.md`(目录树快照 + 14 feature 三态完整性表 + §3 期望对账 + 漂移清单 + 后续维护建议)。预期 0 漂移(Phase 5 #3 第 6 批 finalization 销账后)。
    完整 prompt:`.nightshift/prompts/T05.md`。
    不动 lib/ data/ test/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T05.verify.sh
    # = test -f doc + grep 关键章节 + git log + flutter pub get + dart run build_runner + dart analyze
- rollback: |
    git reset --hard HEAD && git clean -fd

## T06: 今晚 SUMMARY 二次跑
- status: pending
- depends: [T05]
- worktree: ../wuxia-idle-T06
- skippable: true
- timeout_min: 50
- risk: low
- goal: |
    读 `.nightshift/status/T0[1-5].status` + `git log --all --oneline` + `flutter analyze` + `flutter test`(可能慢 2-3 min)。
    产出唯一新文件 `.nightshift/SUMMARY.md`(覆盖旧的):任务执行状态表 / git commits 一览 / 测试 analyze 状态 / **dispatcher 健壮性验证表(本批二次跑核心目标)** / 早上 review 清单 / 已知偏差 / 分支清单 / 启动到结束时间。
    完整 prompt:`.nightshift/prompts/T06.md`。
    不动 lib/ test/ docs/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY,只产 `.nightshift/SUMMARY.md`。
- verify: |
    bash .nightshift/prompts/T06.verify.sh
    # = test -f SUMMARY + grep 关键章节(含 dispatcher 健壮性验证)+ git log
- rollback: |
    git reset --hard HEAD && git clean -fd
