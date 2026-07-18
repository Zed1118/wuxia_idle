# 正式敌人立绘专属化现状盘点

> 盘点日期：2026-07-19
>
> 盘点基线：`53c47ed5`（首轮 assets WebP 批次 READY tip）
>
> 性质：只读盘点；未改资产、映射、数据或 Dart。

## 结论

- 当前正式数据不是旧台账所写的 **79 种 / 120 次**，而是 **89 种 / 130 次**。差额为 2026-07-17/18 新增的第 7–8 章 10 种敌人、10 次出场。
- 旧台账范围内 79 种敌人已全部使用各自独立的生产立绘；批次 04–07 记载的保守复用已被批次 12–14 的专属化产物替换。按最终生产路径统计：**89 个敌人身份 → 89 个不同文件路径 → 89 个不同 SHA-256 内容**，当前共享源组为 **0**。
- 新增 10 种敌人没有进入 `_battleStandeeOverrides`，但它们的 `iconPath` 本身就是 1024×1536 RGBA 全身透明图；`_resolvedStageIconPath` 会直用该文件。它们是独立立绘，不是复用，不过与旧台账“旧头像经 override 映射到 `battle_<id>.png`”的命名/接线口径不同。
- 因而本次没有可按“章节 Boss > 常驻杂兵 > 一次性”排序的**复用重做债**。明日美术应先核验 4 个新增章节 Boss 的直用图（P0），再核验 6 个单次主线普通敌（P2）；这是台账/视觉验收补齐优先级，不代表已发现复用。

## 数据口径

1. 从 `data/stages.yaml` 与 `data/towers.yaml` 汇总每条 `enemyTeam[].iconPath`，以原画 basename 作为台账敌 id；同一原画跨关卡出现仍算同一敌人身份。
2. 按 `lib/features/battle/presentation/character_avatar.dart` 的 `_resolvedStageIconPath` / `_battleStandeeOverrides` 解析最终生产立绘，再展开 `lib/shared/theme/wuxia_tokens.dart` 中的常量值。
3. 对最终路径检查实物存在性、SHA-256；同一路径或同内容哈希才判为共享源。轮廓观感相近但文件不同不擅自判为“同源”，留给美术目检。
4. 与 `docs/spec/BATTLE_ENEMY_STANDEE_COVERAGE.md` 的批次 04–14 记录交叉核对。优先级只针对尚需动作的项目：P0=章节 Boss，P1=跨关卡常驻杂兵，P2=单次出场；已完成专属化记“—”。

## 台账与实物不符

| 项目 | 台账口径 | 当前实测 | 判断 |
|---|---:|---:|---|
| 正式敌人种类 | 79 | 89 | 台账漏记第 7–8 章 10 敌 |
| 正式出场记录 | 120 | 130 | 台账漏记 10 次主线出场 |
| 仍共享生产立绘 | 0（批次 14 结论） | 0 | 一致；旧批次 04–07 的“待专属重做”是历史状态，不是当前状态 |
| override 覆盖 | 79 / 79 | 79 / 89 | 新 10 敌走透明 `iconPath` 直用，不是缺图 |
| 生产立绘实物 | 79 | 89 / 89 存在 | 新 10 图均为 1024×1536 RGBA、alpha 0–255、四角透明 |

## 建议拍板顺序

- **P0（4）**：`huiyiren_beijing`、`beipai_zongjiang`、`huiyiren_saibei`、`huiyiren_final`。均为新增章节 Boss，先补真实战斗双视口视觉核验与台账登记。
- **P1（0）**：没有仍共享生产立绘的跨关卡常驻杂兵。
- **P2（6）**：`beidi_shuzu`、`fengxue_shaoqi`、`beipai_youshao`、`monan_mazei`、`hanhai_shadao`、`gucheng_shuwei`。均为单次主线敌，补台账/目检即可。
- **无需因复用重做（79）**：旧台账范围内全部已专属。若明日仍觉得某两图轮廓过近，应按视觉相似性另开美术评审，不能从当前引用关系推断为共享源。

## 逐敌明细

| 敌 id | 当前生产立绘文件 | 专属 / 复用 | 共享源与共享敌 | 建议重做优先级 |
|---|---|---|---|---|
| `anye` | `assets/enemies/battle_anye.png` | 专属（override） | — | —（已专属） |
| `balian` | `assets/enemies/battle_balian.png` | 专属（override） | — | —（已专属） |
| `bandit_b` | `assets/enemies/battle_bandit_b.png` | 专属（override） | — | —（已专属） |
| `bandit_c` | `assets/enemies/battle_bandit_c.png` | 专属（override） | — | —（已专属） |
| `bandit_head` | `assets/enemies/battle_bandit_head.png` | 专属（override） | — | —（已专属） |
| `beidi_shuzu` | `assets/enemies/beidi_shuzu.png` | 专属（iconPath 直用；台账漏记） | — | P2 核验（单次主线） |
| `beipai_youshao` | `assets/enemies/beipai_youshao.png` | 专属（iconPath 直用；台账漏记） | — | P2 核验（单次主线） |
| `beipai_zongjiang` | `assets/enemies/beipai_zongjiang.png` | 专属（iconPath 直用；台账漏记） | — | P0 核验（章节 Boss） |
| `black_killer` | `assets/enemies/battle_black_killer.png` | 专属（override） | — | —（已专属） |
| `caobang_duozhu` | `assets/enemies/battle_caobang_duozhu.png` | 专属（override） | — | —（已专属） |
| `elder_grey` | `assets/enemies/battle_elder_grey.png` | 专属（override） | — | —（已专属） |
| `fengxue_shaoqi` | `assets/enemies/fengxue_shaoqi.png` | 专属（iconPath 直用；台账漏记） | — | P2 核验（单次主线） |
| `fu_zhaizhu` | `assets/enemies/battle_fu_zhaizhu.png` | 专属（override） | — | —（已专属） |
| `guard_a` | `assets/enemies/battle_guard_a.png` | 专属（override） | — | —（已专属） |
| `gucheng_shuwei` | `assets/enemies/gucheng_shuwei.png` | 专属（iconPath 直用；台账漏记） | — | P2 核验（单次主线） |
| `guntou` | `assets/enemies/battle_guntou.png` | 专属（override） | — | —（已专属） |
| `guntou_zhu` | `assets/enemies/battle_guntou_zhu.png` | 专属（override） | — | —（已专属） |
| `hanhai_shadao` | `assets/enemies/hanhai_shadao.png` | 专属（iconPath 直用；台账漏记） | — | P2 核验（单次主线） |
| `huanghe_yuantou_yufu` | `assets/enemies/battle_huanghe_yuantou_yufu.png` | 专属（override） | — | —（已专属） |
| `huiyi` | `assets/enemies/battle_huiyi.png` | 专属（override） | — | —（已专属） |
| `huiyiren_beijing` | `assets/enemies/huiyiren_beijing.png` | 专属（iconPath 直用；台账漏记） | — | P0 核验（章节 Boss） |
| `huiyiren_final` | `assets/enemies/huiyiren_final.png` | 专属（iconPath 直用；台账漏记） | — | P0 核验（章节 Boss） |
| `huiyiren_saibei` | `assets/enemies/huiyiren_saibei.png` | 专属（iconPath 直用；台账漏记） | — | P0 核验（章节 Boss） |
| `jianghu_a` | `assets/enemies/battle_jianghu_a.png` | 专属（override） | — | —（已专属） |
| `jianghu_b` | `assets/enemies/battle_jianghu_b.png` | 专属（override） | — | —（已专属） |
| `jianghu_qianbei` | `assets/enemies/battle_jianghu_qianbei.png` | 专属（override） | — | —（已专属） |
| `kunlun_waimen_shouguan` | `assets/enemies/battle_kunlun_waimen_shouguan.png` | 专属（override） | — | —（已专属） |
| `lightfoot_changfeng_a` | `assets/enemies/battle_lightfoot_changfeng_a.png` | 专属（override） | — | —（已专属） |
| `lightfoot_changfeng_b` | `assets/enemies/battle_lightfoot_changfeng_b.png` | 专属（override） | — | —（已专属） |
| `lightfoot_changfeng_c` | `assets/enemies/battle_lightfoot_changfeng_c.png` | 专属（override） | — | —（已专属） |
| `lightfoot_pubu_a` | `assets/enemies/battle_lightfoot_pubu_a.png` | 专属（override） | — | —（已专属） |
| `lightfoot_pubu_b` | `assets/enemies/battle_lightfoot_pubu_b.png` | 专属（override） | — | —（已专属） |
| `lightfoot_pubu_c` | `assets/enemies/battle_lightfoot_pubu_c.png` | 专属（override） | — | —（已专属） |
| `lightfoot_shuikou_a` | `assets/enemies/battle_lightfoot_shuikou_a.png` | 专属（override） | — | —（已专属） |
| `lightfoot_shuikou_b` | `assets/enemies/battle_lightfoot_shuikou_b.png` | 专属（override） | — | —（已专属） |
| `lightfoot_shuikou_c` | `assets/enemies/battle_lightfoot_shuikou_c.png` | 专属（override） | — | —（已专属） |
| `lightfoot_yexun_a` | `assets/enemies/battle_lightfoot_yexun_a.png` | 专属（override） | — | —（已专属） |
| `lightfoot_yexun_b` | `assets/enemies/battle_lightfoot_yexun_b.png` | 专属（override） | — | —（已专属） |
| `lightfoot_yexun_c` | `assets/enemies/battle_lightfoot_yexun_c.png` | 专属（override） | — | —（已专属） |
| `lightfoot_zhuke_a` | `assets/enemies/battle_lightfoot_zhuke_a.png` | 专属（override） | — | —（已专属） |
| `lightfoot_zhuke_b` | `assets/enemies/battle_lightfoot_zhuke_b.png` | 专属（override） | — | —（已专属） |
| `lightfoot_zhuke_c` | `assets/enemies/battle_lightfoot_zhuke_c.png` | 专属（override） | — | —（已专属） |
| `liukou_a` | `assets/enemies/battle_liukou_a.png` | 专属（override） | — | —（已专属） |
| `lunjian_sanchang_xunluo` | `assets/enemies/battle_lunjian_sanchang_xunluo.png` | 专属（override） | — | —（已专属） |
| `massbattle_canbu_a` | `assets/enemies/battle_massbattle_canbu_a.png` | 专属（override） | — | —（已专属） |
| `massbattle_canbu_b` | `assets/enemies/battle_massbattle_canbu_b.png` | 专属（override） | — | —（已专属） |
| `massbattle_canbu_c` | `assets/enemies/battle_massbattle_canbu_c.png` | 专属（override） | — | —（已专属） |
| `massbattle_cunfei_a` | `assets/enemies/battle_massbattle_cunfei_a.png` | 专属（override） | — | —（已专属） |
| `massbattle_cunfei_b` | `assets/enemies/battle_massbattle_cunfei_b.png` | 专属（override） | — | —（已专属） |
| `massbattle_cunfei_c` | `assets/enemies/battle_massbattle_cunfei_c.png` | 专属（override） | — | —（已专属） |
| `massbattle_guanqi_a` | `assets/enemies/battle_massbattle_guanqi_a.png` | 专属（override） | — | —（已专属） |
| `massbattle_guanqi_b` | `assets/enemies/battle_massbattle_guanqi_b.png` | 专属（override） | — | —（已专属） |
| `massbattle_guanqi_c` | `assets/enemies/battle_massbattle_guanqi_c.png` | 专属（override） | — | —（已专属） |
| `massbattle_xianjie_a` | `assets/enemies/battle_massbattle_xianjie_a.png` | 专属（override） | — | —（已专属） |
| `massbattle_xianjie_b` | `assets/enemies/battle_massbattle_xianjie_b.png` | 专属（override） | — | —（已专属） |
| `massbattle_xianjie_c` | `assets/enemies/battle_massbattle_xianjie_c.png` | 专属（override） | — | —（已专属） |
| `massbattle_zhenkou_a` | `assets/enemies/battle_massbattle_zhenkou_a.png` | 专属（override） | — | —（已专属） |
| `massbattle_zhenkou_b` | `assets/enemies/battle_massbattle_zhenkou_b.png` | 专属（override） | — | —（已专属） |
| `massbattle_zhenkou_c` | `assets/enemies/battle_massbattle_zhenkou_c.png` | 专属（override） | — | —（已专属） |
| `mingmen_a` | `assets/enemies/battle_mingmen_a.png` | 专属（override） | — | —（已专属） |
| `monan_mazei` | `assets/enemies/monan_mazei.png` | 专属（iconPath 直用；台账漏记） | — | P2 核验（单次主线） |
| `qingshan` | `assets/enemies/battle_qingshan.png` | 专属（override） | — | —（已专属） |
| `qingshan_main` | `assets/enemies/battle_hidden_elder.png` | 专属（override） | — | —（已专属） |
| `ruffian_a` | `assets/enemies/battle_ruffian_a.png` | 专属（override） | — | —（已专属） |
| `seng_huiyi` | `assets/enemies/battle_seng_huiyi.png` | 专属（override） | — | —（已专属） |
| `shafei_a` | `assets/enemies/battle_shafei_a.png` | 专属（override） | — | —（已专属） |
| `shaonian` | `assets/enemies/battle_shaonian.png` | 专属（override） | — | —（已专属） |
| `shiye` | `assets/enemies/battle_shiye.png` | 专属（override） | — | —（已专属） |
| `songshan_daozong_dizi` | `assets/enemies/battle_songshan_daozong_dizi.png` | 专属（override） | — | —（已专属） |
| `songshan_shouguan` | `assets/enemies/battle_songshan_shouguan.png` | 专属（override） | — | —（已专属） |
| `thug_a` | `assets/enemies/battle_thug_a.png` | 专属（override） | — | —（已专属） |
| `thug_b` | `assets/enemies/battle_thug_b.png` | 专属（override） | — | —（已专属） |
| `thug_c` | `assets/enemies/battle_thug_c.png` | 专属（override） | — | —（已专属） |
| `tongguan_shoujiang` | `assets/enemies/battle_tongguan_shoujiang.png` | 专属（override） | — | —（已专属） |
| `tower_boss_05` | `assets/enemies/battle_tower_boss_05.png` | 专属（override） | — | —（已专属） |
| `tower_boss_10` | `assets/enemies/battle_tower_boss_10.png` | 专属（override） | — | —（已专属） |
| `tower_boss_15` | `assets/enemies/battle_tower_boss_15.png` | 专属（override） | — | —（已专属） |
| `tower_boss_20` | `assets/enemies/battle_tower_boss_20.png` | 专属（override） | — | —（已专属） |
| `tower_boss_25` | `assets/enemies/battle_tower_boss_25.png` | 专属（override） | — | —（已专属） |
| `tower_boss_30` | `assets/enemies/battle_tower_boss_30_v2.png` | 专属（override） | — | —（已专属） |
| `umbrella` | `assets/enemies/battle_umbrella.png` | 专属（override） | — | —（已专属） |
| `wulin_bazhu` | `assets/enemies/battle_wulin_bazhu.png` | 专属（override） | — | —（已专属） |
| `xiliang_bazhu` | `assets/enemies/battle_xiliang_bazhu.png` | 专属（override） | — | —（已专属） |
| `xiliang_sandizi` | `assets/enemies/battle_xiliang_sandizi.png` | 专属（override） | — | —（已专属） |
| `xiliangbazhu` | `assets/enemies/battle_xiliangbazhu.png` | 专属（override） | — | —（已专属） |
| `xiliangboss` | `assets/enemies/battle_xiliangboss.png` | 专属（override） | — | —（已专属） |
| `you_hufa` | `assets/enemies/battle_you_hufa.png` | 专属（override） | — | —（已专属） |
| `zhongzhou_lunjian_xianfeng` | `assets/enemies/battle_zhongzhou_lunjian_xianfeng.png` | 专属（override） | — | —（已专属） |
| `zuo_hufa` | `assets/enemies/battle_zuo_hufa.png` | 专属（override） | — | —（已专属） |

## 残留风险

- 本报告判定“共享源”依据生产路径与二进制内容；没有执行 89 图两两轮廓相似度或全量人工目检，因此不能排除不同文件之间的构图/脸型趋同。
- 新增 10 图虽满足透明实物条件，但没有旧 79 图对应的 override、脚底/光学校准条目与 2026-07-17 台账验收证据；本单边界为报告，不修改这些生产文件。
- `stage_07_04`、`stage_08_03` 也标为 `isBossStage: true`，故 P0 合计 4，而非只取每章最后一关。

## 复核命令摘要

- YAML 汇总：89 种 / 130 次。
- 映射解析：79 个 override，10 个直用，0 个缺失生产文件。
- 去重：89 个生产路径、89 个 SHA-256，0 个共享路径组、0 个相同内容组。
- 新增实物：10 / 10 为 1024×1536 RGBA，alpha 0–255，四角 alpha=0。
