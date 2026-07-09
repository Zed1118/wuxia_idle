# 首通战斗体感验收记录 2026-07-09

## 目标

验证主线首通战斗不再以 1-3 秒瞬间结束，至少能稳定进入可观察的起手状态，并给后续逐拍体感验收留出直达入口。

## 本轮入口

- `VISUAL_ROUTE=mainline_first_clear_battle`
  - 真 `stage_01_03`
  - `readableFirstClearTuning=true`
  - `BattleScreen.startPaused=true`
  - `BattleScreen.readablePacing=true`
- `VISUAL_ROUTE=mainline_first_clear_battle_auto`
  - 同一套战斗配置
  - 起手暂停后延迟自动单步，用于后续脚本化截图辅助

## 真机观察

- 稳定可复现的起手截图：
  - `/tmp/wuxia_idle_battle_manual/t00_start.png`
  - 画面停在 `战斗 1 v 1 / 节拍 0`，双方血条、内力条、技能栏、首通提示均可读。
- `mainline_first_clear_battle` 可作为主验收入口：即使 `flutter run` 构建和终端轮询较慢，画面仍停在起手态，不会自行结算。
- macOS 自动点击单步按钮时，`System Events` 返回 `-25200`，当前机器没有足够辅助功能权限，所以本轮未用系统点击完成逐拍截图。
- `mainline_first_clear_battle_auto` 在本机 shell 截图链路里仍容易被构建/轮询耗时影响。已把自动单步起手缓冲拉长，但它只能作为辅助入口，不应替代人工/测试驱动的首通体感验收。

## 结论

本轮修复的价值在于把首通战斗拆出稳定直达入口：先能停住起手，再观察动作。当前可确认“首通战斗验收不再只能截到胜利结算”。真正的自动逐拍截图还需要一个不依赖 macOS 辅助功能权限的测试驱动方式。

## 后续建议

- 下一批优先做一个 Flutter 内部的 visual driver：通过 route 参数或 debug overlay 控制第 N 拍，而不是依赖外部鼠标点击。
- 如果继续调伤害爽感，建议基于同一入口取第 1/3/5/9 拍固定帧，再比较普攻黑字、暴击朱红笔触、击杀题字的层级。
- 生产战斗节奏暂不再加慢，先避免为截图工具问题误伤玩家实际战斗速度。
