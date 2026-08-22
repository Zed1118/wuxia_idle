# Phase 0A Boss 反馈纵切计划

日期：2026-08-22

## 目标

在 Phase 0A 单角色战斗屏中完成 Boss 蓄力、破招、踉跄与脆弱窗口的可触发、可读、可自动验证闭环，并完成 macOS 实机 Gate。

## 边界

- 复用既有 `Phase0aBossChargeStarted` / `Phase0aBossChargeInterrupted` 与运行态字段，不改伤害公式。
- 新增专用 debug fixture / visual route，不借旧 3v3 静态路由验收。
- 表现层只消费事件和 actor 运行态，不反向改战斗状态。
- 不处理 guardian ward、surviveTicks、高周目 cycleVulnerability。

## 切片

1. Boss fixture：稳定产生蓄力、破招、踉跄与 vulnerability 开闭。
2. 事件反馈：蓄力预警、破招题字进入 Phase 0A VFX 映射。
3. 持续状态：Boss 标签显示护体减伤、破绽全力、踉跄与倒计时。
4. 自动验证：事件映射、widget 状态、fixture 真实事件链、analyze。
5. 实机 Gate：1280×720 + 当前桌面视口，键鼠、溢出、卡死、窗口开闭。

## 恢复点

- RP1：事件映射与角色持续状态实现，targeted tests 通过。
- RP2：Boss fixture / visual route 可直达并稳定触发。
- RP3：自动验证与实机 Gate 完成，可进入下一批。
