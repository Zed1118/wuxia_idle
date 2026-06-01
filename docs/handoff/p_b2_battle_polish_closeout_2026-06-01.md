# 战斗屏出版美术 Phase B2 收尾 closeout

**日期：** 2026-06-01
**分支：** worktree-battle-b2(基于 1f0e205)· 待合并 main
**流程：** brainstorm→spec→plan(10 task)→subagent-driven TDD→final review→polish

## 交付

两块纯 Flutter UI 改动(**0 MJ 出图** · 不碰战斗引擎/numbers.yaml/Isar schema)：

1. **大招题字 overlay**：ultimate/jointSkill 出招时屏幕中部偏上弹水墨题字招式名，非阻塞自动淡出(250ms 淡入/1200ms 停留/350ms 淡出)，覆盖语义(连放只显最新)。玩家暖金(resultHighlight)/敌方绛红(gangMeng)。双方触发。
2. **Boss 头像边框**：isBoss 敌人头像金色(bossFrame 0xFFD4A017)6px 加粗边框，区别普通流派色 4px。

## 实装链路(9 commit f3beaa1→d8ef483)

- `BattleCharacter.isBoss` 字段(沿 swordSong 体例)
- `EnemyDef.isBoss` + fromYaml(默认 false 向后兼容 · 非 Isar 不升 saveVersion)`[schema]`
- `_enemyToBattle` 透传 + `@visibleForTesting debugEnemyToBattle` 包装
- `CharacterAvatar` 两处描边(hasIcon Container + _FirstGlyphAvatar)按 isBoss 切色/宽 + `WuxiaColors.bossFrame`
- `data/stages.yaml` 标 **14** boss stage 的语义 Boss 敌人 isBoss(inner_demon 7 关空队豁免——动态镜像)`[schema]`
- `ultimate_caption_overlay.dart`：`isUltimateCaptionSkill` 谓词 + `UltimateCaptionContent` 视图 + `UltimateCaptionOverlay`(AnimationController 自管,opacity 断点由 ms 派生防漂移)
- `battle_screen.dart` wire：GlobalKey + `_playAction` hook(复用 actor,teamSide==1→敌)+ Stack 末 Positioned.fill
- 验收路由：`battle_ultimate_caption`(静态题字暖/冷两态)+ `battle_boss_frame`(scenarioBoss 右队首位 Boss)

## verify

- 全量 `flutter test`：**All tests passed**(1642→1661 · 净 +19 · 1 skip)
- `flutter analyze`：**No issues found**
- 真机自验：`flutter run -d macos VISUAL_ROUTE=battle_boss_frame` → `✓ Built` + `VISUAL_ROUTE_READY` + 自动播放战斗 READY 后**零异常**(scenarioBoss 有普攻 AI 不崩,非 mockTeams)
- final code review：**Ready to merge**(0 Critical/0 Important · 1 Minor opacity 魔数已 polish)

## 待办(非阻塞)

- **Codex @ Pen 视觉验收**(需 Windows 协调)：3 路由——①题字水墨观感+暖/冷区分 ②Boss 金边辨识度 vs 流派色 ③battle_scene B1 回归。沿 feedback_codex_visual_acceptance_mac 派单。
- spec 修正记录：scenarioB 无 ultimate 且 ult requiresManualTrigger=true(AI 不自动放)→ 题字验收改**静态路由**(非自动播放抓帧),已落 Task 9。

## 决策

- B2 范围 = 题字 + Boss 边框(B1 已定);题字纯 Flutter 文字(动态招式名不可预出图)、Boss 纯描边 → **0 出图**,比 session 预估轻。
- 题字非阻塞自动淡出(非 modal):挂机品类大招频发,modal 毁节奏。
- isBoss 加在 EnemyDef(语义最准,boss stage 小怪/boss 可分),非复用 isBossStage。
- 长尾:inner_demon 镜像战不走 EnemyDef 路径,无金边(YAGNI);Boss 专属头像图留后续。
