# Codex 派单:验收基建确认 + 金边 WARN 收口(hub 快速验收)

> 2026-06-04 · Mac 本地 Codex · 复用 `VISUAL_ROUTE=hub` 一次 build 点选全路由

项目:挂机武侠 (/Users/a10506/Desktop/Projects/挂机武侠)

【背景】上次复跑 PASS with 1 WARN。WARN 已在代码侧处理(boss 改名西凉霸主 + 金边偏暗系死亡灰化非 bug)。但你上次 git pull 被本地 unstaged 改动挡住,HEAD 停在 b69235a,没拉到新加的验收基建(hub + enemy_gallery + equipment_detail_gallery)。本任务:解阻塞拉最新(HEAD 41019ec)→ build 一次走 hub 确认基建 + 收口金边 WARN。

【第一步:解阻塞拉最新】
```
cd /Users/a10506/Desktop/Projects/挂机武侠
git stash            # 或 git checkout -- macos/ ,清掉构建产物 unstaged 改动
git pull --rebase
git rev-parse --short HEAD   # 确认 = 41019ec(或更新)
```

【第二步:build 一次,走 hub 点选验收(免每路由重 flutter run)】
```
flutter run -d macos --dart-define=VISUAL_ROUTE=hub
```
等日志出现 `VISUAL_ROUTE_READY: hub` → app 显示路由列表。全程不关 app、不重 run:点一项进对应屏截图 → 左上返回 → 点下一项。窗口 1280×720。

1. 点 `enemy_gallery` → 全敌人圆形头像网格滚动看:
   - 无破图占位 / 无明显裁切偏心
   - boss(如西凉霸主)显**存活状态亮金 6px 边框**(收口上次「金边偏暗」WARN)
   截图 r3_01_enemy_gallery(滚动可多张)。返回。
2. 点 `equipment_detail_gallery` → 全装备 detail 按阶网格滚动看风格统一 + 本体清晰。
   截图 r3_02_equip_gallery。返回。
3. 确认 hub 点选切屏全程是同一个 app 进程、没有重新编译(验提速基建生效)。

【判据】
- PASS:enemy_gallery 无破图 + boss 亮金边可辨;equipment_gallery 风格统一;hub 切屏不重 build
- FAIL/WARN 必记:路由/defId + 现象

【交付】
结果补进 docs/handoff/codex_vis_rerun_2026-06-04.md(标「金边 WARN 已收口」+ 基建确认),截图存同名目录。先报告结论,不改代码/资产;工作树 pre-existing 未提交内容别动。
