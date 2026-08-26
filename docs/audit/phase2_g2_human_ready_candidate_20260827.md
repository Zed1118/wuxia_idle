# Phase 2 G2 统一候选机器预检(2026-08-27)

## 核心结论

- 交付状态:`G2-HUMAN-READY`。正式 G2 状态仍为 `BLOCKED`,只等用户在真人试玩后对八项逐项签字;本记录不宣称 M2/G2 或二阶段完成。
- 候选 worktree:`/Users/a10506/Desktop/Projects/挂机武侠-p2-g2-ready-20260827`;分支:`codex/p2-g2-human-ready-20260827`;基线:`049fce083417077ed178f7b50294f4fdadc7a97a`。
- 已统一接入:姿态候选 B(`14 / 4 / recover-to-4 / boss×3`)、破防 A(在同一姿态累计上按 skill `defenseBreakPct` 放大)、攻击令牌 A(`1/1/1/1`,总预算 4)。三者仍是 `TUNING`,不是冻结定值。
- 未接入 T2(`2/1/1/0`),因它与用户已选的 `1/1/1/1` 冲突。未改 main / origin/main,未 push,未改 schema / migration / GDD / PROGRESS。

## G2 八项预检表

| G2 项 | 机器预检 | 正式状态 | 证据与待人检点 |
|---|---|---|---|
| 1. 持续移动/普攻无漏拍 | PASS | BLOCKED | 生产纵切观测到移动+普攻命令真实解算;Profile 6 轮无连续重帧。待键鼠人检手感。 |
| 2. 35–45 总敌连续清杂 | PASS | BLOCKED | 真实 `stage_01_03` 在最大 tick 前胜利,击杀 40 个唯一敌人,无软锁。数量仍属 TUNING,待人检“爽感”。 |
| 3. 8–16 active 且威胁可读 | 数量 PASS / 观感 REVIEW | BLOCKED | 生产运行观测 `maxActive=12`,双视口黑风岭实战截图无 overflow。守势压力 fixture 的 Boss/姿态/杂兵标签在贴身时有叠压,需人检判断是否 REWORK。 |
| 4. 护盾/化解/闪避各有用 | 功能 PASS / 手感 REVIEW | BLOCKED | 防御纵切、破防姿态生产接线与双视口 guardian 图均通过;是否形成真实选择仍须玩家判断。 |
| 5. Boss 可学且破绽可利用 | 规则 PASS / 学习性 REVIEW | BLOCKED | 生产 `stage_01_05` 姿态/蓄力/破招接线在 targeted+全量通过。一次 R 按新合同只累计架势,不直接破势;独立复核发现旧 visual driver 停在此处后,已增加可执行驱动测试,用同一真实 reducer 继续普攻至 `posture.isVulnerable` 并冻结。学习性与利用手感仍待人检。 |
| 6. 胜利到下一关无阻塞 | PASS | BLOCKED | 生产结算返回 `leftWin`,下一关为 `stage_01_04`;待真实 UI 点击人检。 |
| 7. manual/auto/headless 同规则 | PASS | BLOCKED | 同 seed 下三路径的 ticks、events、final state 精确相等;仍待物理手动输入签字。 |
| 8. 双视口性能+水墨 | 指标 PASS / 审美 REVIEW | BLOCKED | `1280×720` 与 `1440×900` 各3轮 Profile 全绿;12 张 battle suite + 黑风岭生产图尺寸正确、无异常。水墨表现仍由用户审美签字。 |

## 验证证据

- 直接 targeted:姿态 10、姿态 production wiring 5、破防 3、防御纵切 5、战斗屏 28、Boss/guardian 机制表现 5、G2 生产纵切 2、G2 矩阵 5、视觉 route 8、route runner 13、令牌/目录/候选/调参 28,均通过。Boss driver 测试先在驱动器缺失时编译报红,实现后验证真实破绽态与冻结不再推进。
- 令牌 break-red:把生产值临时改回旧 B(`2/2/1/1`)后,精确候选断言和方案 `[2,4]` 总预算断言同时报红(总和 6); 还原 A 后 6/6 通过。
- format:`1621 files / 0 changed`;有效 analyze:`No issues found`。首次 analyze 因 fresh worktree 中嵌套 `tools/phase0minus_probe` 缺 package config 产生 1943 项级联环境错误;在该独立 package 执行 `flutter pub get` 后归零。
- 最终全量:`5621 passed / 0 failed`,exit 0,真实墙钟 276 秒;log SHA-256 `ddda45ad4702e0ab371af096fa736e416d3f574c459a69b62e3db6246bac813c`。
- 性能:共6轮/21,598 有效帧;p99 total span 全局 `4.541–5.808ms`,最大连续严重帧 1,GC 全部 `COLLECTED`,RSS 复合门全过。Profile AOT SHA-256 `524bb2b1995c40fae5a87ea54c3bcbb9009329d0a8e400b85e68c5790f4d7e5a`。
- 证据目录(未跟踪 build 产物):`build/g2_candidate_profile_20260827/`、`build/g2_candidate_visual_20260827/`、`build/g2_candidate_battle_visual_20260827/`、`build/g2_candidate_boss_break_visual_20260827/`。截图 manifest 均记录 tested commit `90553140b17c776d4908e0fdcb4581b39b33ccc9`、tree `e4d3fb16d5cbfbcf90da801460054dcbbe494f78`、`dirty=false`。

## G0 只读对账与非本批阻塞

- 用户原始签字“按推荐方案执行 G0”确实存在,覆盖重打参与者 C、连续关 A/B/B、听剑占用 A/成长对象 B、心魔修炼度 B、AI C 暂缓、解锁 C 暂缓、生态 B 分批。
- 它不等于签署听剑具体比例/上限、七关 AI 具体矩阵、渐进解锁精确章点或后续生态批次。`INNER-DEMON-LEGACY-01` 在 decision registry 中还缺原始 ID;COLLAB-WIP registry 与当前 Mac 单端长寿文档也存在冲突。
- 上述事项不影响本批 G2 战斗候选的运行验证,但继续阻塞 M0 形式闭环或 M5/M6/M7 扩面;本批未越界修复。

## 恢复/人检入口

1. 保留本 worktree 与分支,不要先合 main。
2. 用当前候选进入真实主线 `stage_01_03` 与 `stage_01_05`,按上表逐项填 `PASS / REWORK / BLOCKED`。
3. 八项全 PASS 或用户明确豁免后,另行授权才能将 G2 改为通过并讨论 main 合并/push。
