# 挂机流停止快照 2026-08-07(用户要求停下检查)

> main `4be60432` · 与 origin 同步 · CI 上一轮绿(run 31162901058)
> 全部执行端已停;5 个 worktree 工作区**全部干净**,无未提交改动。

## 一、已合入 main 并推送(可直接检查)

| 内容 | 端 | commit |
|---|---|---|
| L1-A 核心文档路径失修修复(12 处修/3 处保留) | pi | 合并 `d4faa328` |
| L1-B docs/spec 路径失修(14 文件,3 处 [BLOCKED]) | codebuddy | 合并于 L1-B merge |
| L1-C 历史文档归档档头(63 文件,三变体 10/11/42) | pi | 合并于 L1-C merge |
| N1 numbers.yaml 4 段字段处置注释 | Claude | `22686c5a` |
| `docs/PATH_MIGRATION_MAP.md` 路径迁移映射表(新建) | Claude | `60484881` + 2 次订正 |
| `docs/spec/rarity_wiring_gap_2026-08-07.md` 稀有度现状 spec(二稿+补节) | Claude | `4be60432` |

## 二、[READY] 待评审分支(未合,供检查)

| 分支 | 端 | 内容 | 我的验收状态 |
|---|---|---|---|
| `qoder/config-bypass-audit` | qoderclicn | Q2 配置声明 vs 生产硬编码背离扫描:背离 8 / 部分背离 7 / 休眠 21 | **未复核**(执行端自报,数字待复跑) |
| `pi/dead-field-audit` | pi | A1 实体只写不读字段:44 只写不读 + 14 仅 debug 读 | **未复核** |
| `cb/doc-link-scan-tool` | codebuddy | L1-D `tools/doc_link_scan.py` 死链扫描器入仓 | **未复核** |

## 三、被中途停止的分支(工作区干净,可 resume)

| 分支 | 端 | 进度 | 说明 |
|---|---|---|---|
| `kimi/night-goals-0807` | kimi | 12 commit / 12 测试文件。**7 目标完成约 6 个**:T1 全(3 文件)· T2 全(2)· T6 全(extension 棘轮新建)· T7 全(2)· T3 部分(3 文件中做了 coop_chain)· T4 部分(top8 中做了 3)· **T5 宗门+奇遇域未开工** | 未打 [READY],**按 §8.3 属 WIP 不可合** |
| `codex/taohua-art-0807` | codex | 3 commit(报告)。**25 张规格完成 23 张**:A 类图标 7 建筑×2 变体=14 · B 类卡背景 7 · C 类入口图 2;**D 类背景候选 2 张未做** | 图落 `build/art_candidates/taohua_2026-08-07/`(gitignored,未进 git),含中间件共 27 文件 |

> ⚠ 本节初稿低报了两端进度(写成「kimi 做到 T4」「codex A 类+部分 B 类」),2026-08-07 停止后按 git 与产出目录实测订正如上。

## 四、Claude 自己的分支(全绿,待你决定合不合)

`worktree-claude-rarity` — 3 commit / 13 文件,稀有度派生实装:
- `NumbersConfig.rarityForTotalPoints` 从 `character.rarity_distribution` 派生 + 红线测(含破坏证红)
- 三处创建点改派生 + 奇遇加点后同步重算
- 六档档名进 `EnumL10n.rarityTier`;角色档案页加资质档位 chip(**视觉为临时版,待你终拍**)
- `Character.rarity` 补默认值(此前 `late` 无默认,65 处构造点读它即抛,含生产 `visual_route_host.dart:3182`)

**验证(本会话实测)**:analyze 0 · 全量 **4892 通过 / 0 失败**(基线 4886 + 本批新增 6 测,数字自洽)· 破坏证红成立(改坏 yaml 区间表 → 2 测红,报错精准指出「总点数 22 应派生为 ziYou」)

## 五、本夜代拍决策清单(供推翻)

1. 时长按 8h 默认(用户未报时长,问过一次未再阻塞)—— **事后看这条判断错了**,用户全程在线
2. C2 重定义:候选池「岛景背景+7 建筑立绘只换皮」前提错误(背景已是成品且被测试锁尺寸;热区是 152×94 信息卡、图标位 18-21px)→ 改出四类图
3. 背景图不替换但出高分辨率候选
4. 新增 Q2 单(不在候选池,由 N1 发现催生)
5. L1 大幅缩范围(原计划会毁掉迁移账本 + 删除验收证据索引)
6. 稀有度按 A 路线(叙事角色,不做投胎随机化)—— 详 spec §四
7. 稀有度字段保留不移除(照 `level`/`levelExp` 的「留待统一 schema cleanup」惯例;且移除需改 153 处测试调用,会与 kimi 在途的 test/ 改动撞车)

## 六、遗留 / 未做

- 池单 P2 真机录屏验收(塔 42)、P3 checklist E 段 reconcile —— **未开工**
- Q2 报出的 8 条背离(supply_cap / stage_boss_recruit_prob / enabledInDemo / 飞升传承 4 字段)—— 未复核未处置
- A1 报出的 44 个只写不读字段 —— 未复核未处置
- 稀有度 spec §四 的分布问题(12 人池天才 17% / 绝世 17% vs 目标 5% / 2%)—— 待拍
