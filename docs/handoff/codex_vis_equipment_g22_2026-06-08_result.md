# 装备图 G2.2 抠白底三屏视觉验收回执

日期：2026-06-08  
worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/equip-cutout-transparent`  
分支：`worktree-equip-cutout-transparent`

## 1. 总判

PASS。

未记录到装备图周围浅底矩形块、明显白边 / 灰投影云、半透残洞，场景图未出现被抠成碎片的问题。`equipment_detail_gallery` 源码为 80 项、4 列网格，实际 1920x1080 下 4 张有效截图覆盖从寻常到神物尾段；后续补滚停在底部。

## 2. 逐屏结果

| 屏幕 | 1280x720 | 1920x1080 |
|---|---|---|
| `inventory` | PASS：装备缩略图在宣纸格内显示，镂空饰品中心透出格底；未见独立浅底块。 | PASS：同屏缩略图更完整，玉佩 / 银戒等镂空中心透底；未见白晕或矩形色差。 |
| `character_panel` | PASS：该尺寸首屏只能露出装备区标题，滚动可达更下方；未见页面局部异常。 | PASS：装备槽完整可见，武器 / 护甲 / 饰品浮在奶纸底上，无旧染底矩形块。 |
| `equipment_detail_screen` | PASS：默认天问剑 detail 作为整幅场景图装裱显示，画面完整。 | PASS：天问剑场景图完整，未见碎片、破洞或浅底块。 |
| `equipment_detail_gallery` | PASS：顶部首屏复核无异常。 | PASS：逐屏滚动覆盖 gallery，有效截图 `g22_gallery_1.png` 至 `g22_gallery_4.png`；场景图整幅保留，cut 图无矩形底块。 |

## 3. FAIL 记录

无。

重点样本记录：

- `accessory_baowu_yu_long_pei`：在 gallery 中作为整幅暖底 detail 出现，未见破洞或异常浅底块。
- `accessory_baowu_long_gu_lian`：在 inventory 可见同类环形/镂空饰品中心透底；未见白盘填充。
- `accessory_baowu_zi_jin_hu_lu`：gallery 扫描未见同类暖底产品照残留灰投影云。
- `weapon_baowu_chang_hong_jian`：gallery 场景图整幅显示，未被抠碎。
- `armor_shenwu_xuan_huang_pao`：gallery 场景图整幅显示，未被抠碎。

## 4. 截图

- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_main_menu_smoke_1280.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_inventory_1920.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_character_panel_1920.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_detail_hero_1920.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1280_top.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_1.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_2.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_3.png`
- `docs/handoff/codex_vis_equipment_g22_2026-06-08_result/g22_gallery_4.png`

## 5. 验证备注

- 启动命令：`flutter run -d macos --dart-define=VISUAL_ROUTE=hub`，烟测 `main_menu` 正常。
- 因 `main_menu` 是全屏门面且没有返回 hub 的显式控件，后续路由使用同一 build 缓存逐 route 启动：`inventory`、`character_panel`、`equipment_detail_screen`、`equipment_detail_gallery`。
- 未找到 `docs/handoff/codex_vis_equipment_g22_2026-06-08.md` 原始细则文件；本回执按用户消息中的判据执行。
