# Phase 0A AB 内测包烟测记录

## 结论

`PASS_FOR_INTERNAL_HUMAN_SMOKE`

本记录只签“对照包可启动、可操作、隔离成立”，不代签 2–3 人内部真人
smoke、6 人主观 Gate 或 Windows Gate。

## 冻结产物

- runtime commit：`2dd21018b621d60eac412a503778b6dc5fbbd857`
- 包：`/Users/a10506/Desktop/挂机武侠_Phase0A_AB内测包_2dd21018`
- scenario checksum：`9694a17d6e5eb301ad0b80de0492786e38f1355c946c381fe62ba8eeb71274ba`
- 对照 binary checksum：`2da422024d99d65fe9ca7f0efac0b38aae84b8ae15917a798e9d31dc5bff0b08`
- 对照 route / seed：`battle_tap_live` / `20260719`

## 实机烟测

### 当前点招对照

1. 从包内 `1_启动当前点招对照.command` 启动成功。
2. 日志输出 `VISUAL_ROUTE_READY: battle_tap_live`。
3. Isar 路径为 app sandbox 下的 `tmp/wuxia_idle_visual_routes`，不是正式 Documents / save slot。
4. 初始顶栏真实显示“继续”和“单步”；点单步后节拍从 `0` 到 `1`，没有自动播完。
5. 点“断流”进入待发，出现三个可选敌人；选“隐世老者”后立即出手，
   目标 HP `7820 → 4283`，祖师真气 `68 → 43`，并出现“断流 3537 伤”。

### Phase 0A 灰盒

1. 从包内 `2_启动Phase0A灰盒.command` 启动成功。
2. 标题、HP/QI、波次、键位提示和 10 敌人场面正常。
3. `PLAY AGAIN` 可重置到 HP `100` / QI `40` / Wave 1。
4. LMB 普攻命中后 QI `40 → 55`，证明真实鼠标输入和命中产气链路可用。
5. 烟测操作者故意不持续移动，被围攻击败；这与已冻结的弱策略 Gate 一致，
   不是启动或输入失败。

## 进入下一步的条件

- 2–3 名不计入正式样本的内部测试者完成 AB/BA smoke；
- 内部 smoke 不发现崩溃、输入丢失或流程无法完成；
- 随后才冻结 6+2 测试者名单、人类裁决人和 3/3 AB/BA 排期。
