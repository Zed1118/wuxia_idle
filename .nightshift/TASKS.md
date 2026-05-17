# Nightshift Plan - 2026-05-18 P1 #42 Phase 1 4 子系统 widget test 加固
Window: 立即 launch → 用户睡眠 8h 内(实际预期 2-3h 跑完)
Total tasks: 8
Dispatcher interval: 40m (timeout 50m + 30s inter-task buffer)
HEAD baseline: 217ddf7 (main, 0 issues + 971/971)

> **本批主题**:P1 #42 Phase 1 收口(GameEventService / HomeFeedScreen / BaikeScreen / 延续典故 hook 4 子系统)widget test edge 加固。25 new test 预期(testWidgets +20 / test +5),全 test/ 新增 0 lib/ 改动。
>
> **吸取昨天教训**:① 不盲信 6h window 必填(`feedback_claude_print_task_duration`);② 旧 SUMMARY 数据 baseline 必重 grep 实测(`feedback_closeout_numbers_grep`);③ dispatcher auto-create worktree(-B 覆盖,免手工)+ build_runner 显式 `--delete-conflicting-outputs`。

## T01: HomeFeedScreen 相对时间剩 4 档 edge
- status: pending
- worktree: ../wuxia-idle-T01 (auto-created by dispatcher)
- skippable: true
- timeout_min: 50
- risk: low
- goal: |
    6 档相对时间(刚才/N分钟/N小时/昨天/N天前/月日)现有 test 只覆盖 2 档。补剩 4 档 widget test 各 1 个,产出唯一新文件 `test/features/home_feed/presentation/home_feed_screen_time_format_test.dart`(testWidgets +4)。
    完整 prompt:`.nightshift/prompts/T01.md`。
    不动 lib/ data/ 其他 test/ GDD CLAUDE PROGRESS numbers IDS_REGISTRY。
- verify: bash .nightshift/prompts/T01.verify.sh
- rollback: git reset --hard HEAD && git clean -fd

## T02: HomeFeedScreen 快速领取按钮行为 edge
- status: pending
- worktree: ../wuxia-idle-T02
- skippable: true
- timeout_min: 50
- risk: low-mid
- goal: |
    快速领取按钮当前只测 visible 未测 tap / 重复点 / 空 list 容错。补 3 个 widget test,产出唯一新文件 `test/features/home_feed/presentation/home_feed_screen_quick_claim_test.dart`(testWidgets +3)。
    完整 prompt:`.nightshift/prompts/T02.md`。
- verify: bash .nightshift/prompts/T02.verify.sh

## T03: HomeFeedProviders markAllFeedRead 边界 edge
- status: pending
- worktree: ../wuxia-idle-T03
- skippable: true
- timeout_min: 50
- risk: low
- goal: |
    markAllFeedRead 顶级函数当前测「基础批量 mark」未测 Isar null / 已全读再 mark idempotent / mark 后 feed 顺序不乱。补 3 个 test,产出唯一新文件 `test/features/home_feed/application/home_feed_providers_mark_all_edge_test.dart`(test +3)。
    完整 prompt:`.nightshift/prompts/T03.md`。
- verify: bash .nightshift/prompts/T03.verify.sh

## T04: BaikeScreen 典故 tab 7 阶分组 + 段数 edge
- status: pending
- worktree: ../wuxia-idle-T04
- skippable: true
- timeout_min: 50
- risk: low-mid
- goal: |
    典故 tab 当前测「加载/未加载」二分,未细化 7 阶顺序严格性 / presetLoreIds 段数 0/1/N 三态。补 4 个 widget test,产出唯一新文件 `test/features/baike/presentation/baike_screen_tier_group_test.dart`(testWidgets +4)。
    完整 prompt:`.nightshift/prompts/T04.md`。
- verify: bash .nightshift/prompts/T04.verify.sh

## T05: BaikeScreen MainMenu 11 按钮导航 + 6 档时间 override edge
- status: pending
- worktree: ../wuxia-idle-T05
- skippable: true
- timeout_min: 50
- risk: low-mid
- goal: |
    MainMenu 10→11 按钮新增「江湖见闻录」入口 0 导航 test 覆盖 + 见闻 tab 6 档时间 override 未详化。补 3 个 widget test,产出唯一新文件 `test/features/baike/presentation/baike_screen_navigation_test.dart`(testWidgets +3)。
    完整 prompt:`.nightshift/prompts/T05.md`。
- verify: bash .nightshift/prompts/T05.verify.sh

## T06: EquipmentDetailScreen _LoreSection 延续典故渲染(0→1)【最高价值】
- status: pending
- worktree: ../wuxia-idle-T06
- skippable: true
- timeout_min: 50
- risk: mid
- goal: |
    **本批 0→1 最高价值缺口**。`_LoreSection` widget(P1 #42 Phase 5 新加 equipment 参数 + preset/continued 段顺序 + `_ContinuedLoreChip` 墨青色)0 widget test 覆盖。补 5 个 widget test:仅 preset / 仅延续 / 混排顺序 / 都空 / `_ContinuedLoreChip` 颜色。产出唯一新文件 `test/features/inventory/presentation/equipment_detail_screen_lore_section_test.dart`(testWidgets +5)。
    完整 prompt:`.nightshift/prompts/T06.md`。
- verify: bash .nightshift/prompts/T06.verify.sh

## T07: GameEventService #4 接口 + #9 路由 edge
- status: pending
- worktree: ../wuxia-idle-T07
- skippable: true
- timeout_min: 45
- risk: low
- goal: |
    14 现有 test 覆盖主路径 + safety,未细化 #4 lineageInherited placeholder + #9 founder/disciple 路由分支反向断言。补 3-5 test,产出唯一新文件 `test/features/event/application/game_event_service_lineage_routing_edge_test.dart`(test +3-5)。
    完整 prompt:`.nightshift/prompts/T07.md`。
- verify: bash .nightshift/prompts/T07.verify.sh

## T08: SUMMARY 生成(收尾)
- status: pending
- worktree: ../wuxia-idle-T08
- skippable: true
- timeout_min: 30
- risk: low
- goal: |
    读 T01-T07 status / commit / 测试结果,产出唯一新文件 `.nightshift/SUMMARY.md`(覆盖旧的)含:任务执行表 / commits / 测试状态 / 早上 review 三 phase 清单 / 已知偏差 / 下一波候选 / dispatcher 健壮性观察 / 启动到结束时间。
    完整 prompt:`.nightshift/prompts/T08.md`。
- verify: bash .nightshift/prompts/T08.verify.sh

---

## 启动

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/launch.sh
```

`launch.sh` 内含 `caffeinate -dimsu nohup ... &` + disown,关闭 Terminal 不影响 dispatcher。

## Dry-run(睡前必跑一次,已验证)

```bash
bash /Users/a10506/Desktop/挂机武侠/.nightshift/dispatcher.sh --dry-run
```

打印「会调度哪些 task / 用哪些 prompt」不真启 claude,< 5s 完成。

## 早上检查入口

```bash
cat /Users/a10506/Desktop/挂机武侠/.nightshift/SUMMARY.md
ls /Users/a10506/Desktop/挂机武侠/.nightshift/status/
```
