# Phase 0A 断魂庄单角色续传 · Mac 实机目检

- 日期：2026-08-22
- 分支：`codex/phase0a-gauntlet-main-0822`
- 构建：macOS debug，五个 Phase 0A 灰度门开启编译
- 数据隔离：visual route 专用 Isar 临时目录，未使用玩家存档
- 裁决：`MAC_ENGINEERING_AND_VISUAL_PASS`

## 目检结果

1. 1280×720 Boss 蓄力预警：通过；顶部“蓄力可破”、Boss 身旁“蓄力可破 3”均清晰。
2. 可打断反馈：通过；按 R 后显示“破！”、1960 伤害、Boss HP 12000→10040、玩家真气 100→75。
3. 破招/硬直：通过；打断后 Boss 明确显示“踉跄 3”，墨爆反馈与状态标签不互相遮挡。
4. vulnerability window：通过；蓄力及踉跄态均显示“破绽·全力”，窗口语义可读。
5. 1440×900：通过；上述预警、破招、硬直和 HUD 全部复验，无裁切或异常缩放。
6. 键盘：通过；W/A/S/D、J、Q、R、Esc、Tab/Enter 均可响应；R 清场进入冷却并扣真气。
7. 鼠标：通过；点击 Q 技能印后真气 100→75、技能显示 4.7 秒冷却；点击“再战”可完整重置。
8. 暂停：通过；暂停时 HP/真气冻结且 W/J/Q/R 被屏蔽；恢复后继续推进。
9. 终局/恢复：通过；败退封签、倒地技能态和“再战”入口完整，鼠标及键盘均可重开。
10. 溢出/卡死：通过；两档窗口、终局重开及 5 次暂停恢复循环均无 Flutter exception、RenderFlex overflow 或无响应。

## 自动验收补强

- 断魂庄测试族 183/183。
- 历史多人兼容分流 7/7；相关失败、恢复、奖励、门票事务 59/59。
- 生产单成员入口在 1280×720 widget 环境实际挂载 `Phase0aBattleScreen`，无溢出。
- 全仓 5403/5403，`flutter analyze lib test` 0 issue，五灰度 macOS debug build 成功。

## 边界

本裁决只覆盖本批 Mac 单角色断魂庄纵切。Windows 实机 Gate、六人主观 Gate 及最终旧 3v3 原子拆除仍未执行。
