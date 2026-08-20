# 新会话开局清单

> 更新时间：2026-08-20 · Phase 0A 正式桌面控制与真实六技能收账
> 在途分支：`codex/phase0a-real-skill-bindings-0820`（READY，待合并）

## 当前结论

- 战斗终态不变：Phase 0A 单角色 ARPG 按路线 C 替换旧 3v3，不做长期双轨。
- Phase 1 Ch1 的内容、live/headless、真实结算、奖励、成长、伤势和进度全链已成立。
- 正式控制已从灰盒 J/Q/R 升级：鼠标左键按点击世界方向普攻并支持按住连击，J 仅兼容；数字 1–6 对应真实装配槽并可点击技能印。
- 六技能主链使用真实 SkillDef id/power/Qi/CD/targetType/proficiency；空槽和暂不支持机制 fail-closed，账本不写内部 hotkey/kind。
- Q 聚怪/R 失衡因 SkillDef 尚无 behavior/geometry 字段暂留迁移 Adapter；正式替换仍锁六人主观 Gate、Windows 实机 Gate 与其余消费面迁移。

## 本批完成

1. 新增 screen→world 逆变换和 stage pointer layer；primary click/hold 普攻，secondary/HUD/技能印/暂停/终局不冒泡，J 沿 facing 兼容。
2. neutral snapshot 新增明确七槽身份与真实主修 basic；数字顺序固定 main1/main2/assist/resonance/ultimate/encounter，key 破招槽不挤数字栏。
3. 新增 numeric binding 深 Module、generic skill intent/reducer/event；single/aoe、正负 Qi、CD 和真实 DamageCalculator 全链成立。
4. 数字键与六枚真实技能名水墨印同路；空槽保位禁用，顶部数字键与 numpad 均支持。
5. bot 开始按 ready 顺序使用真实数字技能；真实 Isar → mapping → bot → settlement e2e 证明熟练度账本只含真实技能 id。
6. unsupported interrupt/defenseBreak/qiDrain 构造期 fail-fast；extension 审计棘轮保持 16 不放宽。

## 验证快照

- `flutter analyze`：0 issue。
- Phase 0A domain/application/presentation + 主线：296/296。
- 鼠标/焦点/暂停/音效/headless 相关回归：86/86。
- 最终全量：`flutter test --no-pub --reporter=compact` = **5244 pass / 0 fail**。
- 文档扫描：1316 个 md、8340 引用、dead 65，基线守恒。

## 下一步任务（依赖顺序）

### P0 · 合并与清理

1. `--no-ff` 合入 `main`；合并态复跑 analyze、关键输入/技能 targeted、全量与文档扫描；删除已合 worktree/分支。

### P1 · 真实技能版 Ch1 校准

1. 跑 Ch1 五关多 seed headless 胜率、耗时、末态 HP/Qi、各技能使用率画像；再结合真人试玩判断难度。
2. 为 Q pull/R stagger 设计显式 `Phase0aSkillBehavior`/geometry schema，迁入真实技能后删除固定 gather/clear Adapter。
3. 决定第七 key 破招槽的上下文触发（鼠标右键/蓄力窗口自动提示），不挤占数字 1–6。
4. 校准稳定后按 ADR 迁远征、断魂庄单主角续传与扫荡 headless 直结。

### 依赖锁死 · 不提前执行

1. Phase 0A 六人主观 Gate：与 BACKLOG 一#19/#4/#5/#6 合并试玩局，需用户排期。
2. Windows 实机 Gate：正式替换前必须人工完成。
3. 旧 3v3/65 路由原子拆除：消费面迁移、六人 Gate、Windows Gate 全过后同次 merge。
4. Phase 0B `MANUAL_RIG_PENDING`：人工美术工作。
