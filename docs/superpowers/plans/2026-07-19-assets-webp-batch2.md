# assets 全域 WebP 幂等转码批恢复计划

## 目标与边界

- 在 `codex/assets-webp-batch2` 分支对 `assets/` 全域运行既有 `python3 tool/convert_assets_webp.py`。
- 文件名与 `.png` 引用保持不变；仅当 WebP q80 体积小于原图 90% 时原位替换内容。
- 零新图、零改名、零删除；不改 `lib/`、`data/`、`pubspec.*`、`tool/`、数值、schema、saveVersion、叙事文案、strings、GDD、PROGRESS。
- 入库实质变化只允许 `assets/`；本文件作为 `CLAUDE.md §8.0` 明令要求的恢复点元数据一并提交。截图只留 `build/visual_acceptance/`，不入库。

## 分支与工作区

- 基点：`main@43df2d10b56364aa319cd14394c80dd45012f524`
- 分支：`codex/assets-webp-batch2`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/assets-webp-batch2`

## 验收标准

- [x] 生产接线：原路径、文件名与 pubspec 声明不变，生产 `Image.asset` 消费方通过 magic bytes 解码转码内容。
- [x] 转码边界：`assets/` 外无生产文件变化；零改名、零删除、零新资产；脚本本身不改。
- [x] targeted：`test/data/webp_in_png_decode_test.dart`、`test/tools/asset_audit_test.dart`、pubspec 声明守卫共 9/9 通过。
- [x] 全量：批末 `flutter test --no-pub` 并发执行 4417/4417 通过。
- [x] 静态检查：开工基线及批末 `flutter analyze --no-pub` 均为 0 issues。
- [x] 规格：82/82 张转码敌人立绘与 Git 基线相比尺寸不变、RGBA 保留、alpha 范围 0–255、四角 alpha=0；`file` 抽查两类 magic 正确。
- [x] 画质：8 张立绘使用转码前/后版本合成到生产山口战场底图，完成 1280×720、1440×900 双视口目检；截图位于 `build/visual_acceptance/assets_webp_batch2/` 且不入库。
- [x] 对账：记录总量及各一级目录转码前后字节数、转码/跳过/已转张数和净节省。
- [x] 红线：确认零触及数值硬红线、三系锁死、在线=离线、反主流项、Dart 中文/数值硬编码。
- [x] 残留风险：列明未抽验图；抽验样本无单张画质存疑，未触发整类跳过。
- [ ] 冻结：全部允许改动已提交、工作树干净、tip commit 以 `[READY]` 开头。

## 任务切片

1. 建立 worktree，复制 Isar 动态库，执行 `flutter pub get`、build_runner 与 analyze 基线。
2. 记录全 assets 格式、体积、尺寸、色彩模式、alpha 与 PNG 原图快照清单。
3. 全域运行幂等脚本并核验仅发生允许的同路径内容替换。
4. 完成目录体积对账、格式/规格抽查和真实场景双视口合成目检。
5. 运行 targeted 守卫、全量测试、末轮 analyze 与 Git 边界检查。
6. 更新本恢复点四证据，中文动宾提交并追加 `[READY]` 冻结标记。

## 转码清单

脚本实测：`已转码 89 张 / 保持PNG(无收益) 110 张 / 已是WebP跳过 295 张`。Git 仅显示以下 89 个原路径内容修改，状态全部为 `M`。

### characters（4）

```text
assets/characters/battle_first_disciple.png
assets/characters/battle_founder.png
assets/characters/battle_founder_v2.png
assets/characters/battle_second_disciple.png
```

### enemies（82）

```text
assets/enemies/battle_anye.png
assets/enemies/battle_balian.png
assets/enemies/battle_bandit_archer.png
assets/enemies/battle_bandit_b.png
assets/enemies/battle_bandit_blade.png
assets/enemies/battle_bandit_c.png
assets/enemies/battle_bandit_head.png
assets/enemies/battle_black_killer.png
assets/enemies/battle_caobang_duozhu.png
assets/enemies/battle_elder_grey.png
assets/enemies/battle_fu_zhaizhu.png
assets/enemies/battle_guard_a.png
assets/enemies/battle_guntou.png
assets/enemies/battle_guntou_zhu.png
assets/enemies/battle_hidden_elder.png
assets/enemies/battle_huanghe_yuantou_yufu.png
assets/enemies/battle_huiyi.png
assets/enemies/battle_jianghu_a.png
assets/enemies/battle_jianghu_b.png
assets/enemies/battle_jianghu_qianbei.png
assets/enemies/battle_kunlun_waimen_shouguan.png
assets/enemies/battle_lightfoot_changfeng_a.png
assets/enemies/battle_lightfoot_changfeng_b.png
assets/enemies/battle_lightfoot_changfeng_c.png
assets/enemies/battle_lightfoot_pubu_a.png
assets/enemies/battle_lightfoot_pubu_b.png
assets/enemies/battle_lightfoot_pubu_c.png
assets/enemies/battle_lightfoot_shuikou_a.png
assets/enemies/battle_lightfoot_shuikou_b.png
assets/enemies/battle_lightfoot_shuikou_c.png
assets/enemies/battle_lightfoot_yexun_a.png
assets/enemies/battle_lightfoot_yexun_b.png
assets/enemies/battle_lightfoot_yexun_c.png
assets/enemies/battle_lightfoot_zhuke_a.png
assets/enemies/battle_lightfoot_zhuke_b.png
assets/enemies/battle_lightfoot_zhuke_c.png
assets/enemies/battle_liukou_a.png
assets/enemies/battle_lunjian_sanchang_xunluo.png
assets/enemies/battle_massbattle_canbu_a.png
assets/enemies/battle_massbattle_canbu_b.png
assets/enemies/battle_massbattle_canbu_c.png
assets/enemies/battle_massbattle_cunfei_a.png
assets/enemies/battle_massbattle_cunfei_b.png
assets/enemies/battle_massbattle_cunfei_c.png
assets/enemies/battle_massbattle_guanqi_a.png
assets/enemies/battle_massbattle_guanqi_b.png
assets/enemies/battle_massbattle_guanqi_c.png
assets/enemies/battle_massbattle_xianjie_a.png
assets/enemies/battle_massbattle_xianjie_b.png
assets/enemies/battle_massbattle_xianjie_c.png
assets/enemies/battle_massbattle_zhenkou_a.png
assets/enemies/battle_massbattle_zhenkou_b.png
assets/enemies/battle_massbattle_zhenkou_c.png
assets/enemies/battle_mingmen_a.png
assets/enemies/battle_qingshan.png
assets/enemies/battle_ruffian_a.png
assets/enemies/battle_seng_huiyi.png
assets/enemies/battle_shafei_a.png
assets/enemies/battle_shaonian.png
assets/enemies/battle_shiye.png
assets/enemies/battle_songshan_daozong_dizi.png
assets/enemies/battle_songshan_shouguan.png
assets/enemies/battle_thug_a.png
assets/enemies/battle_thug_b.png
assets/enemies/battle_thug_c.png
assets/enemies/battle_tongguan_shoujiang.png
assets/enemies/battle_tower_boss_05.png
assets/enemies/battle_tower_boss_10.png
assets/enemies/battle_tower_boss_15.png
assets/enemies/battle_tower_boss_20.png
assets/enemies/battle_tower_boss_25.png
assets/enemies/battle_tower_boss_30.png
assets/enemies/battle_tower_boss_30_v2.png
assets/enemies/battle_umbrella.png
assets/enemies/battle_wulin_bazhu.png
assets/enemies/battle_xiliang_bazhu.png
assets/enemies/battle_xiliang_sandizi.png
assets/enemies/battle_xiliangbazhu.png
assets/enemies/battle_xiliangboss.png
assets/enemies/battle_you_hufa.png
assets/enemies/battle_zhongzhou_lunjian_xianfeng.png
assets/enemies/battle_zuo_hufa.png
```

### scenes（3）

```text
assets/scenes/battle_innerrealm_cool_v2.png
assets/scenes/battle_mountain_pass_stage_cool_v3.png
assets/scenes/battle_mountain_pass_stage_v2.png
```

## 体积对账

`du -sk` 实测（KiB，占用块口径）：

| 目录 | 转码前 | 转码后 | 净省 |
|---|---:|---:|---:|
| assets 总计 | 174,440 | 86,804 | 87,636 |
| audio | 15,744 | 15,744 | 0 |
| characters | 5,084 | 2,916 | 2,168 |
| enemies | 105,220 | 25,508 | 79,712 |
| equipment | 19,316 | 19,316 | 0 |
| images | 2,128 | 2,128 | 0 |
| maps | 1,020 | 1,020 | 0 |
| scenes | 16,004 | 10,260 | 5,744 |
| ui | 9,908 | 9,908 | 0 |

文件逻辑字节精确口径：

| 目录 | 转码前 bytes | 转码后 bytes | 净省 bytes |
|---|---:|---:|---:|
| assets 总计 | 177,546,716 | 87,829,439 | 89,717,277（85.56 MiB） |
| characters | 5,177,368 | 2,956,488 | 2,220,880 |
| enemies | 107,367,447 | 25,750,348 | 81,617,099 |
| scenes | 16,254,702 | 10,375,404 | 5,879,298 |
| 其余目录合计 | 48,747,199 | 48,747,199 | 0 |

转码前 494 个 `.png` 路径中，magic 为 WebP 295、真 PNG 199；转码后为 WebP 384、真 PNG 110、其他 0。文件总数保持 530。

## 验收证据

- **生产接线**：89 个路径及扩展名均未改变，`pubspec.*` 零改；`webp_in_png_decode_test.dart` 从 `rootBundle` 读取 `.png` 路径并经 Skia 解码成功。
- **规格**：对全部 82 张转码敌人立绘用 PIL 比较 Git 基线与现文件，82/82 尺寸相同，前后均为 RGBA，alpha 范围均含 0–255，四角 alpha 均为 0。`file` 确认转码样本为 `RIFF ... Web/P image`，无收益样本 `assets/equipment/accessory_baowu_long_gu_lian.png` 仍为真 PNG。
- **视觉**：抽验 `bandit_archer`、`bandit_head`、`tower_boss_30`、`huanghe_yuantou_yufu`、`massbattle_cunfei_a`、`lightfoot_zhuke_c`、`hidden_elder`、`you_hufa`；前后均合成到生产 `battle_mountain_pass_stage_v2` 底图，1280×720 与 1440×900 目检未见白边、alpha 破口、块状纹理、细线断裂或暗部明显糊损。合成后 PSNR 46.77–48.94 dB。截图不入库，位于 `build/visual_acceptance/assets_webp_batch2/`。
- **targeted**：`flutter test --no-pub test/data/webp_in_png_decode_test.dart test/tools/asset_audit_test.dart test/data/pubspec_asset_declaration_test.dart` → 9/9 通过。
- **全量**：`flutter test --no-pub` → 4417/4417 通过，0 fail。
- **静态与边界**：开工及批末 `flutter analyze --no-pub` 均 0 issues；`git diff --check` 通过；边界脚本统计 90 个工作区条目（89 资产 + 本恢复点），0 violation；资产状态只有 `M`，无 A/D/R。
- **红线影响**：纯资产编码替换；零触及数值硬红线、三系锁死、在线=离线、§5.1 反主流项、Dart 中文/数值硬编码、schema、saveVersion、叙事文案或配置。
- **残留风险**：82 张转码敌人中视觉抽验 8 张，余 74 张未逐张肉眼对比；4 张角色立绘与 3 张场景图未做逐张前后目检，但均通过解码/格式与全量测试。抽验样本无单张存疑文件；110 张无收益真 PNG 未发生变化。

## 当前恢复点

- 状态：转码批验收完成，待中文动宾提交并追加 `[READY]` tip 冻结；冻结后按 2026-07-19 追加派单续跑两个只读报告目标。
- 最后完成：全域脚本落盘、89 张变更边界与体积对账、82 张立绘规格核验、8 张双视口目检、targeted、全量与末轮 analyze 全部完成。
- 下一步：显式暂存 89 张 `assets/` 变化和本恢复点，提交后追加 `[READY]` 空提交；确认树干净后开始立绘专属化现状盘点。
- 已跑验证：targeted 9/9；全量 4417/4417；开工/批末 analyze 均 0 issues；`git diff --check` 通过；规格 82/82；边界 0 violation。
- 生产接线证据：原路径/文件名/pubspec 均不变；rootBundle→Skia magic-bytes 解码端到端测试通过。
- 红线影响：纯资产转码，零生产代码、配置、数值、schema、saveVersion、叙事文案、strings、GDD、PROGRESS 或 pubspec 改动。
- 残留风险：74/82 转码敌人、4 张角色立绘、3 张场景图未逐张前后肉眼对比；抽验无存疑文件，最终画质仍由 Claude 端终审。
- 阻塞项：无。
