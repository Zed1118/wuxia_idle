# Nightshift Plan - 2026-05-17
Window: 22:30 → 04:30 (6h)
Total tasks: 6
Dispatcher interval: 40m (timeout 50m + 30s inter-task buffer)

> **Sprint 修正说明**(模板假设 vs 项目实际):
> 模板「3v3 战斗 MVP」与项目实际不符 — 3v3 自动战斗 Phase 1 已完成,Demo 几乎全闭环,当前 W17 候选 E 师徒名单刚收口。今晚 6 task 全部**低-中低风险**,**全部 skippable: true**(无阻塞链),T01-T03/T05 doc 类(0 lib/ 改动),T04 纯新增 test,T06 SUMMARY。无 high risk 战斗核心改动(当前项目核心战斗稳定,改它无必要)。

## T01: #37 永封档
- status: pending
- depends: []
- worktree: ../wuxia-idle-T01
- skippable: true
- timeout_min: 45
- risk: low
- goal: |
    读 `PROGRESS.md` 挂账 #37 段 + `data/events/_archive/` 6 yaml 文件(duan_qiao_can_yue / gu_chuan_deng_ying / huang_cun_yao_ren / qing_lou_can_meng / lao_jing_hui_xiang / yu_zhong_qiao_men)opening 字段 + (可选)GDD §8.4 主题清单。
    产出唯一新文件 `docs/handoff/wuxia_w17_orphan_events_permanent_archive_2026-05-17.md`(背景 / 6 文件逐文件主题分析 / 不挂回理由 / 永封档决议 / PROGRESS 销账建议)。
    完整 prompt:`.nightshift/prompts/T01.md`。
    不动 lib/ data/(含 _archive 内) GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T01.verify.sh
    # = test -f doc + grep 关键字 + git log 验证 commit + flutter pub get + dart analyze --fatal-infos
- rollback: |
    git reset --hard HEAD && git clean -fd

## T02: pattern 审计
- status: pending
- depends: [T01]
- worktree: ../wuxia-idle-T02
- skippable: true
- timeout_min: 45
- risk: low-mid
- goal: |
    全仓 `grep -rn "pumpAndSettle" test/ --include="*.dart"`,对每处 hit 分类风险(A 低 / B 中 / C 高候选)。
    读 `test/features/main_menu/presentation/main_menu_test.dart` 末尾 `_RecordingNavigatorObserver` 实现学套路(commit `4aa54fa` 加)。
    产出唯一新文件 `docs/handoff/wuxia_widget_test_pattern_audit_2026-05-17.md`(套路源码 + 全仓扫描 + 推荐替换清单 + follow-up)。
    完整 prompt:`.nightshift/prompts/T02.md`。
    不动 lib/ test/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T02.verify.sh
    # = test -f doc + grep 关键字 + git log + flutter pub get + dart analyze --fatal-infos
- rollback: |
    git reset --hard HEAD && git clean -fd

## T03: 死代码 scan
- status: pending
- depends: [T02]
- worktree: ../wuxia-idle-T03
- skippable: true
- timeout_min: 50
- risk: low
- goal: |
    扫描 4 维度死代码:A 死 provider(@riverpod 定义 0 引用)/ B 0-lib-consumer service / C 未引用 private function / D extension on entity 类硬编码嫌疑。
    GDD 锚点交叉验证(参 `feedback_riverpod_codegen_provider_split` cookbook 死 provider 决策矩阵)。
    产出唯一新文件 `docs/handoff/wuxia_dead_code_scan_2026-05-17.md`(4 类候选 + GDD 锚点验证 + 删/保留决策建议 + 总结)。
    **只报告不删代码**。
    完整 prompt:`.nightshift/prompts/T03.md`。
    不动 lib/ test/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T03.verify.sh
    # = test -f doc + grep 4 类章节 + git log + flutter pub get + dart analyze --fatal-infos
- rollback: |
    git reset --hard HEAD && git clean -fd

## T04: LineagePanel 边界
- status: pending
- depends: [T03]
- worktree: ../wuxia-idle-T04
- skippable: true
- timeout_min: 50
- risk: mid
- goal: |
    读现有 `test/features/character_panel/presentation/lineage_panel_screen_test.dart`(3 widget test)学体例 + `lib/features/character_panel/application/lineage_info_provider.dart` 看 view model 注入字段。
    新增 3-5 边界用例,产出唯一新文件 `test/features/character_panel/presentation/lineage_panel_screen_edge_test.dart`(大量 heritage / 多 disciples / heritage 空但 founder 在 / school=null 兜底 / 等 — 任选 3+)。
    红线遵守约束语义不写瞬时事实(参 `feedback_red_line_test_semantics`)。
    完整 prompt:`.nightshift/prompts/T04.md`。
    不动现有 test 文件,不动 lib/,不动 GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T04.verify.sh
    # = test -f new test + git log + flutter pub get + dart analyze + flutter test 新文件全过
- rollback: |
    git reset --hard HEAD && git clean -fd

## T05: NavigatorObs doc
- status: pending
- depends: [T04]
- worktree: ../wuxia-idle-T05
- skippable: true
- timeout_min: 45
- risk: low
- goal: |
    读 `test/features/main_menu/presentation/main_menu_test.dart` 末尾 `_RecordingNavigatorObserver` + PROGRESS #31 段 + Phase 5 #2 销账 #28 历史。
    产出唯一新文件 `docs/handoff/wuxia_navigator_observer_mock_pattern_2026-05-17.md`(问题陈述 / 套路源码 / 适用场景 / 与 #28 套路对比表 / 后续复用清单)。
    完整 prompt:`.nightshift/prompts/T05.md`。
    不动 lib/ test/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: |
    bash .nightshift/prompts/T05.verify.sh
    # = test -f doc + grep 关键字段 + git log + flutter pub get + dart analyze --fatal-infos
- rollback: |
    git reset --hard HEAD && git clean -fd

## T06: 今晚 SUMMARY
- status: pending
- depends: [T05]
- worktree: ../wuxia-idle-T06
- skippable: true
- timeout_min: 50
- risk: low
- goal: |
    读 `.nightshift/status/T0[1-5].status`(各 task 状态文件)+ `git log --all --oneline | head -30` + `flutter analyze` + `flutter test`(可能慢 2-3 min)。
    产出唯一新文件 `.nightshift/SUMMARY.md`(任务执行状态表 / git commits 一览 / 测试 analyze 状态 / 早上 review 清单 / 已知偏差 / 分支清单 / 启动到结束时间)。
    完整 prompt:`.nightshift/prompts/T06.md`。
    不动 lib/ test/ docs/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY,只产 .nightshift/SUMMARY.md。
- verify: |
    bash .nightshift/prompts/T06.verify.sh
    # = test -f SUMMARY + grep 关键章节 + git log 验证 commit
- rollback: |
    git reset --hard HEAD && git clean -fd
