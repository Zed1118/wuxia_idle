# G2 八项真人试玩 runbook(2026-08-27)

> 仓内此前**没有**针对这 8 项的操作手册,08-24 那次只留了 run ID 和截图、没留步骤。
> 本文键位与关卡锚点均为 2026-08-27 从集成分支代码现读,带 `file:line`。

## 0. 在哪跑

```bash
cd /Users/a10506/Desktop/Projects/挂机武侠-p2-integration   # 集成 worktree
git log --oneline -1     # 应为 870f9832 [BLOCKED] G2候选集成态待8项真人试玩
flutter run -d macos
```

分支 `integration/p2-g2-candidate-20260827`,树 `fd2a9ed3`。
**不要在主 checkout 跑**——主 checkout 是 main,没有 posture 接线,试的不是这个候选。
**环境已由协调者预热完毕**(2026-08-27 11:21-11:22 实测):`pub get` 完成、
`build_runner` 实写 **128 个输出**(fresh worktree 的 `.g.dart` 本来是缺的,不预热直接 run 必撞编译错)、
`flutter build macos --debug` **退出码 0**,产物 `build/macos/Build/Products/Debug/wuxia_idle.app` 已就位。
预热不弄脏工作树(`.g.dart` 被 gitignore),树哈希仍是 `fd2a9ed3`,Gate 结论有效。
所以直接 `flutter run -d macos` 即可。**不要设 `DEVELOPER_DIR`**,它会让 `flutter build macos` 报 xcodebuild 找不到。

## 1. 要打哪两关(这条最容易搞错)

| 项 | 关卡 |
|---|---|
| 1 / 2 / 3 / 4 / 6 / 7 / 8 | `stage_01_03` **黑风岭**(第一章第 3 关) |
| **5** | `stage_01_05` **风雨渡口**(第一章第 5 关) |

第 5 项锚点见 `test/support/phase2_g2_acceptance_harness.dart:220`:
「证据锚点为既有生产 `stage_01_05`;`stage_01_03` 是非 Boss 伏击关,**不承担本项**」。
黑风岭没有 Boss,在那儿是验不了第 5 项的。

关卡顺序解锁:打黑风岭需先过 01_01 山门之外、01_02 荒山野店;打风雨渡口需 01_01–01_04 全过。
生产入口路径:主菜单 → 继续江湖 / 章节地图 → 第一章 → 选关。
方案 `:1265` 硬性要求 **G2 必须从生产入口可玩,不走 debug/demo 路由**,所以别用 `--dart-define=VISUAL_ROUTE=...` 抄近路取证。

## 2. 键位(2026-08-27 现读 `phase0a_battle_screen.dart`)

| 操作 | 键 | 行 |
|---|---|---|
| 移动 | `W` `A` `S` `D`(按住) | `:475-478` |
| 普攻 | `J`(按住)或鼠标左键按住+移动瞄准 | `:480-483` |
| 护盾 | `E` | `:488-490` |
| 招架/化解 | `F` | `:491-493` |
| 闪避 | `Z` | `:494-496` |
| 聚怪 | `Q` | `:497` |
| 破招/清场 | `R` | `:498` |
| 技能位 | `1`–`6`(含小键盘) | `:499-510` |
| 暂停 | `Esc` | `:466-472` |
| 终局再战 | `Enter` | `:457-461` |

**`docs/phase0/phase0a-playtest-keycard.md` 已过期,别照它跑**——那是 Route C 时期的键位卡
(写着鼠标左键=普攻、`Space`=身法),当前代码没有 `Space` 身法、普攻主键是 `J`。

## 3. 试玩前必须知道的三条

1. **`phase0a_battle_screen.dart:486-487` 有条注释说「E/F/Z are currently unused by battle input」——该注释是错的。**
   2026-08-27 复核:三个键正下方就是接线,链路为
   `screen:488` → `controller:113` 合并 → `input_adapter:127` 取值 → `reducer:480/493/508` 分支处理
   (时长映射 `:526-528`)。防御**是生效的**,注释后半句「不是最终手感」才是真的。
2. **E/F/Z 三个键零测试覆盖**(`grep -rn "LogicalKeyboardKey.key[EFZ]" test/` 零命中;
   对照 W/A/D/J/Q 均有测)。所以第 4 项的机器预检只能给到「功能 PASS」,
   **绑定层唯一的检查就是你这次手打**。若 E/F/Z 按下去没反应,那是真 bug,不是手感问题。
3. **本轮真正在验的靶子**是三组仍为 `TUNING` 的值:
   `data/numbers.yaml` 的 posture 五值(`capacity: 14` / `vulnerability_ticks: 4` /
   `recovery_policy: recover` / `post_vulnerability_accumulated: 4` / `boss_conversion_factor: 3`)、
   破防方案 A、攻击令牌 A(`1/1/1/1`)。试玩结论直接决定 `forbidden_files` FAIL 怎么裁。

## 4. 八项逐条 + 看什么

语义以 `test/support/phase2_g2_acceptance_harness.dart:177-246` 为准(被 `ch1_g2_acceptance_matrix_test.dart:27` 钉死)。

| # | 判据原文 | 手打时重点看 |
|---|---|---|
| 1 | 连续移动与普攻输入在固定 tick 中无丢失 | 按住 `J` 边走边打,有无漏拍/吞输入 |
| 2 | 连续清除 35–45 个敌人且无软锁 | 机器已测到击杀 40 个唯一敌人无软锁;你判「连续清杂爽不爽」 |
| 3 | active 数量处于 8–16 且威胁可读 | 机器测到 `maxActive=12`;**贴身时 Boss/姿态/杂兵标签有叠压**,判是否 REWORK |
| 4 | 盾反、招架、闪避均能改变可观测战斗结果 | `E`/`F`/`Z` 逐个试,先确认有反应(见 §3.2),再判三者是否形成真实选择 |
| 5 | Boss 规律可学习,破绽可被玩家利用 | **在风雨渡口打**。注意:一次 `R` 按新合同只累计架势、不直接破势 |
| 6 | 胜利结算后可无阻塞进入下一关 | 黑风岭打赢 → 能不能顺畅进 `stage_01_04` |
| 7 | manual、auto、headless 同规则同事件语义 | 机器已证同 seed 下三路径 ticks/events/final state 精确相等;你只签「手打观感无漂移」 |
| 8 | 双视口性能证据 + 水墨视觉过线 | 性能 6 轮已跑(21,598 帧,p99 4.541–5.808ms);**水墨审美归你签** |

## 5. 填哪张表

`docs/audit/phase2_g2_human_ready_candidate_20260827.md:11-22`(**只在候选分支上有**)。
该表已把每项拆成「机器预检 / 正式状态 / 待人检点」三栏,8 项当前全为 `BLOCKED`。
逐项改成 `PASS` / `REWORK` / `BLOCKED` 并写备注。

## 6. 签完之后的顺序(不能跳)

1. 在集成分支上填表并 commit
2. `git merge main`(main 期间前进了纯文档提交)
3. **重跑 Gate**(裁决 3C:merge 后旧 Gate 结论作废)
4. 为新 HEAD 补 `[READY]` 或 `[BLOCKED]` 标记 commit
5. `forbidden_files` 的 A/B/C 裁决落定
6. 快进 main

## 附:08-24 那次签字为什么不算数

`test/tools/output/phase2_g2_stage_01_03_acceptance_record.md:4` 记 `overall: 8/8 PASS`,
`:5` 绑定 candidate commit `811256300f`(08-24)。**那是对 08-24 代码态的签字**;
此后 POSTURE 接线等改动是否影响其成立没人回答过,所以本轮重跑。
