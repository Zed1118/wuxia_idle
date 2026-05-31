# Codex 派单:sect 立绘 portrait wiring 视觉验收

派单方:Claude (Mac+Opus) · 日期:2026-05-31 · HEAD:f025c09(origin/main 同步)
关联:关闭 closeout `codex_visual_compress_portraits_20260531.md` B 段 FAIL(生产 UI 未接 portraitPath)。
规范依据:`docs/handoff/codex_visual_acceptance_prompt_guide_2026-05-31.md`。

---

## 任务

sect 立绘渲染视觉验收,截图 + closeout。**不改代码 / 不改 yaml / 不 push**。

## 验收背景(已实装)

`Character.portraitPath` 单一真相源(Isar 0.15.0);`PortraitFrame` 共享 widget 接 3 站点:
sect_screen 成员行 48 / sect_recruit 确认 dialog 96 / 强制招募 debug 列表 40。
祖师弟子立绘 ← MasterDef,sect NPC 立绘 ← SectCandidateDef。

---

## A 段(必验):sect_screen 成员行 7 立绘

【启动】优先用已编译 app,**不要 checkout / build**:
```
pkill -f wuxia_idle || true
open /Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app
```
该 app 来自 commit f025c09,已烧入 `--dart-define=VISUAL_ROUTE=sect_screen_npc`,**启动自动直达 sect_screen**(内置 `seedSectWithFullNpc` seed),无需导航。

【验收数据】成员列表应含 7 人,**每人左侧一张立绘**:
- 祖师(founder.png · 长老 chip)
- 竹影客 / 漠行客 / 山隐子 / 江湖客 / 幽谷客 / 铁匠之子(6 张 sect_candidate_*.png)

若立绘缺失只显空框/图标,先截图记录,不要改代码。

【截图输出】`docs/handoff/codex_visual_sect_portrait_2026-05-31/`
- `a_sect_members_top.png` — 成员列表上半(祖师 + 前几名 NPC 立绘)
- `a_sect_members_bottom.png` — 滚到底(剩余 NPC 立绘,验证滚动连续)
- `a_sect_member_row_closeup.png`(可选)— 单行近景看 48×48 立绘 + 边框

【A 验收点】逐条 PASS/WARN/FAIL:
① 7 人成员行各显一张立绘,无灰空框/图标占位
② 立绘与角色身份吻合(竹林剑客/沙漠刀客/长须隐士/酒葫芦/背药篓/围裙腰刀;祖师=师徒画风)
③ 48×48 立绘 + schoolColor 边框布局正常,不挤压姓名/境界/chip/按钮

---

## B 段(次验):dialog 96 + debug 列表 40

A 段 app 被路由锁在 sect_screen,够不到 debug 菜单。B 段需**正常启动**(无 route):
```
pkill -f wuxia_idle || true
flutter run -d macos
```
(若该 app 缺 .g.dart 报错,跑 `dart run build_runner build --delete-conflicting-outputs` 一次。)
导航:主菜单 → debug 菜单 → 「强制招募 NPC」。

【截图】
- `b_force_recruit_list.png` — 强制招募列表(每行左侧 40×40 立绘缩略图,替换原 person_add 图标)
- `b_recruit_confirm_dialog.png` — 点任一候选 → 确认 dialog 顶部 96×96 立绘

【B 验收点】
④ 强制招募列表每行 40×40 立绘缩略图,姓名/id/流派/境界 文本仍在
⑤ 确认 dialog 顶部 96×96 立绘,下方姓名/流派/属性/lore 仍完整

---

## closeout

写到 `docs/handoff/codex_visual_sect_portrait_2026-05-31/closeout.md`,必含:
- A/B 验收点 ①-⑤ 结论表(PASS/WARN/FAIL)
- 截图路径
- 实际窗口尺寸
- 是否遇构建/权限/导航/存档问题
- 一句话总评

## 边界
不改代码 / 不改 yaml / 不 push / 不装新包。若必须 build_runner,只在临时 worktree 做并在 closeout 说明。

---

## 验收结论(Codex 填)

| # | 验收点 | 结论 | 备注 |
|---|--------|------|------|
| ① | 7 成员行各显立绘无空框 | | |
| ② | 立绘身份吻合 | | |
| ③ | 48 成员行布局正常 | | |
| ④ | debug 列表 40 缩略图 | | |
| ⑤ | dialog 96 立绘 | | |

总评:

---

## 修复轮(R2 · 2026-05-31)

R1 反馈:A FAIL(祖师行空框 · memberCount 6/8) / B PASS。
根因(systematic-debugging 坐实):`seedSectWithFullNpc` 未先 `_clearAll`,真机已存 legacy 祖师(0.14 存档·portraitPath=null)使 `ensureFoundingMasters` 短路,祖师立绘永空(单测在空 tempDir 跑故漏)。
修复(`62ab9d2` merge main):seed 开头加 `await isar.writeTxn(() => _clearAll())` 重建带立绘祖师 + 加 legacy 短路回归测。1627 测/0 analyze。app 已用修复 seed 重建。

**R2 只需复验 A 段**(B 已 PASS):
```
pkill -f wuxia_idle || true
open /Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app
```
该 app 来自 commit 62ab9d2(已烧 VISUAL_ROUTE=sect_screen_npc)。预期祖师行现显 founder.png 立绘,7 行各有立绘。截图存同目录 `a_*_r2.png`,A 验收点 ①②③ 重判。
