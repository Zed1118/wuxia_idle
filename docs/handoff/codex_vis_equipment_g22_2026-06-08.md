项目:挂机武侠 · 装备 G2.2 抠白底三屏视觉验收(Mac Codex · flutter run -d macos)

## 一句话
装备图 160 张已抠白底透明(130 cut)/ 整幅水墨场景保原图(30 frame),`EquipmentArtImage` 去掉旧 `BlendMode.multiply` 染底 hack。请验装备图在仓库/角色页/详情三屏渲染**无"浅底块"色差**、透明物件干净浮宣纸面板、场景图整幅成装裱画。

## 跑哪儿(本地 worktree,无需 checkout/push)
改动在本机 worktree(同一台 Mac,直接进目录即可):
```
cd /Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/equip-cutout-transparent
```
- 分支 `worktree-equip-cutout-transparent`,commit `5734650`,**未合 main**。
- `.g.dart` / `flutter pub get` / isar dylib **已就绪**(我已在该 worktree 跑过 build_runner + pub get)。若 `flutter run` 报缺生成文件,补跑 `dart run build_runner build --delete-conflicting-outputs`。

## 启动(一次 build 点遍)
```
flutter run -d macos --dart-define=VISUAL_ROUTE=hub
```
- hub = 验收总入口,一次 build 列出全部路由按钮点选(免每路由重 build)。
- 首帧就绪 debugPrint `VISUAL_ROUTE_READY: <id>`。
- **环境自检**:先点 `main_menu` 确认正常渲染(山门 bg + 题字),再做下面 4 屏。
- macOS 窗口可拖拽缩放,验收时拉到 ~1280x720 与 ~1920x1080 各看一遍。

## 验收 4 屏 + 固定截图名
| # | hub 按钮(route id) | 看什么 | 截图名 |
|---|---|---|---|
| 1 | `inventory` 仓库 | **item_slot 缩略图**:装备图浮宣纸格,**无白/米黄矩形底块**、无白晕;环形物(项链/玉环)中心透格底 | `g22_inventory.png` |
| 2 | `character_panel` 角色页 | **装备槽**:奶纸底(`EFE3C7`)上装备图浮着无矩形块 | `g22_character_panel.png` |
| 3 | `equipment_detail_screen` 详情页 | **hero 大图**:默认 seed=神物天问剑——天问剑 detail 属**场景图**,**预期显整幅水墨剑山景**(装裱画,非 bug);看它完整不碎、无矩形浅块 | `g22_detail_hero.png` |
| 4 | `equipment_detail_gallery` 全 detail 滚动 | 全 detailPath 大图滚动,**逐屏滚完截 3-4 张**,扫:①残留矩形浅底块 ②半透残洞 ③场景图被抠成碎片 | `g22_gallery_1..4.png` |

## G2.2 PASS / FAIL 判据
**PASS**:
- 透明 cut 图(白底 icon / 暖底产品照)干净浮纸面板,**周围无矩形浅底块、无白晕/灰投影云**。
- 环形/镂空物中心透出面板底色(不是填白盘)。
- 30 张场景图(剑横木窗/袍悬山雾/铠甲木架)整幅完整渲成装裱画,**未被抠成碎片浮块**。

**FAIL 信号**(任一即记):
- 装备图周围一圈比面板深/浅的**矩形色块**(multiply 没去净 / 用错图)。
- 物件边缘**白边 / 灰投影残留**。
- 场景图出现**碎片 / 破洞 / 啃缺**。

## 重点抽查样本(gallery / inventory 里找)
- cut 白底 icon:**玉龙佩**(yu_long_pei)→ 干净浮底
- cut 暖底:**紫金葫芦**(zi_jin_hu_lu)→ 无灰投影云
- cut 环形:**龙骨链**(long_gu_lian)→ 环心透底
- scene frame:**长虹剑**(chang_hong_jian)、**玄黄袍**(xuan_huang_pao)→ 整幅画完整

## closeout(回执)
写 `docs/handoff/codex_vis_equipment_g22_2026-06-08_result.md`:
1. 总判 **PASS / FAIL**
2. 4 屏逐屏 PASS/FAIL + 一句话(两个分辨率各记)
3. FAIL 的:截图名 + 哪件装备 + 哪类问题(矩形块/白边/碎片/残洞)
4. 截图全附(`g22_*.png` 放同目录)

PASS → 我 ff 合 main + push;FAIL → 我按你列的问题图调 cut 集/分类重出对应图再来一轮。
