# 战斗场景长尾 9 biome MJ prompt（battle scene 出版美术）

用途：补 B1 已识别的 9 个长尾 biome 专属战斗背景（现走近邻复用兜底）。出图后归位 `assets/scenes/battle_<biome>.png`（沿现有 7 张体例：1456×816 / oxipng·pngquant 压缩 ~350-420KB）。
约束：16:9 横构图作战斗背景 / **中部+中下留空旷平地给 3v3 角色站位**（地标/结构偏置一侧，沿 battle_frontier 体例）/ 无人物无文字无钤印 / 水墨厚涂低饱和（沿 `feedback_mj_wuxia_prompt_pitfalls`）。scrim 已 black 40% 均匀压暗，不需额外暗区。
顺序严格对应下表 1→9。

| # | biome | 文件名 | 覆盖 stage | 题材 | 现兜底 |
|---|---|---|---|---|---|
| 1 | inn | battle_inn.png | stage_01_02 荒山野店 | 荒山野店院前 | citywall |
| 2 | escortRoad | battle_escortroad.png | stage_02_01 镖局护送 | 官道镖路关卡 | mountainpath |
| 3 | teaHouse | battle_teahouse.png | stage_02_02 茶馆论剑 | 江南水畔茶馆 | citywall |
| 4 | smithy | battle_smithy.png | stage_02_03 春水堂 | 铁匠铺炉前空场 | drillground |
| 5 | alley | battle_alley.png | stage_02_05 巷中夜雨 | 雨夜窄巷 | citywall |
| 6 | temple | battle_temple.png | stage_03_03 山寺夜话 / stage_05_02 嵩山道观 | 山中寺观庭院（佛道通用） | mountainforest |
| 7 | desert | battle_desert.png | stage_04_03 沙海迷踪 / stage_06_04 昆仑山外 | 大漠戈壁（昆仑外缘荒原通用） | frontier |
| 8 | bambooForest | battle_bambooforest.png | stage_light_foot_03 竹海听风 | 竹海空地 | mountainforest |
| 9 | cliffWaterfall | battle_cliffwaterfall.png | stage_light_foot_04 险崖飞渡 | 险崖飞瀑栈道 | mountainpath |

注：#6 temple 一图通用佛寺(山寺夜话)+道观(嵩山道观)；#7 desert 一图通用大漠(沙海迷踪)+昆仑荒原(昆仑山外)。按 biome 接线粒度 1 图覆盖多 stage，沿 B1「按 biome 非按 stage」决策。

## 出图后接线 update（次轮，图归位后做）

11 处 stage `sceneBackgroundPath` 从兜底改专属（data/stages.yaml）：
- stage_01_02 → battle_inn.png
- stage_02_01 → battle_escortroad.png
- stage_02_02 → battle_teahouse.png
- stage_02_03 → battle_smithy.png
- stage_02_05 → battle_alley.png
- stage_03_03 → battle_temple.png
- stage_05_02 → battle_temple.png
- stage_04_03 → battle_desert.png
- stage_06_04 → battle_desert.png
- stage_light_foot_03 → battle_bambooforest.png
- stage_light_foot_04 → battle_cliffwaterfall.png

改后跑全量 `flutter test`（接线在 stages.yaml，battle_screen 消费）+ Codex 验 `battle_scene` 路由（可临时改 visual_route_host 抽样各 biome 图）。

---

A desolate wilderness inn courtyard at dusk, a weathered timber two-story inn with a hanging lantern offset to the left, bare trees and a low fence, an open packed-earth yard across the center, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A misty official escort caravan road through a valley, a stone watch-pass gate and a laden cart with banner-poles offset to one side, an open flat roadway across the center, overcast, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A Jiangnan waterside teahouse, a two-story wooden teahouse with cloth awnings and a willow tree offset to one side, a calm canal behind, an open flagstone plaza across the center, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A village blacksmith forge yard, a timber smithy with a glowing forge, anvil and hung tools offset to one side, drifting smoke, an open packed-earth ground across the center, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A narrow rain-soaked town alley at night, dark wet brick walls and a single dim hanging lantern, puddled flagstones reflecting faint light, an open passage running down the center, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A secluded mountain temple courtyard, a stone temple hall with curved eaves and a worn stone incense burner offset to one side, ancient gnarled pines, an open stone-paved yard across the center, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A vast windswept desert of rolling dunes, a half-buried ruined beacon tower offset to one side, an open flat expanse of sand across the center, distant pale haze and faint far mountains, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A dense misty bamboo grove, tall slender bamboo stalks clustering along the sides, an open mossy clearing across the center, light drifting rain, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

A towering sheer cliff with a thundering waterfall plunging into churning mist, the falls offset to one side, a narrow rocky ledge crossing the foreground center, precarious and grand, Chinese ink wash painting, thick wet impasto ink brushwork, desaturated cyan-grey ink and rice-paper cream palette, misty atmospheric, cinematic wide establishing shot, open uncluttered flat foreground across the lower center for character staging, no people, no text, no signature --ar 16:9 --style raw --v 7

---

## 选片记录(2026-06-02 · 我多模态从各 4 变体挑选)

| biome | 选 | 压缩后 | 理由 |
|---|---|---|---|
| inn | v1 | 716KB | 建筑偏左上+下方大片留空 |
| escortRoad | v4 | 584KB | 远景镖队+雾山前景留白,贴 frontier 体例 |
| teaHouse | v3 | 576KB | 石板广场居中+江南识别度高(排除带钤印的 v1) |
| smithy | v4 | 524KB | 炉铺偏右+中左留空+烟雾克制 |
| alley | v4 | 856KB | 较亮冷灰,叠 scrim 40% 不至过暗(v1/v3 偏暗) |
| temple | v2 | 468KB | 殿堂偏右+远山雾,佛道通用 |
| desert | v2 | 264KB | 烽燧台地标+大漠前景,识别度最高 |
| bambooForest | v3 | 760KB | 蓝灰最克制(余偏绿/青饱和) |
| cliffWaterfall | v3 | 528KB | 飞瀑偏左+冷灰开阔前景 |

压缩:pngquant --quality=80-94 + oxipng -o2(源 1456×816 与现有 7 图一致,无需 resize)。纹理重的(alley/bamboo/inn)偏大属正常,未二次有损避 banding。
接线:11 stage sceneBackgroundPath 已改专属(见上表)。测试 battle_scene_wiring_test `_map` 同步更新 + 白名单改 `_map.values` 派生(单一真相源)。1667 测/0 analyze 全绿。
**待 Codex 验 `battle_scene` 路由**:9 图叠 scrim 后观感 + banding + alley/bamboo 暗场/饱和复核。
