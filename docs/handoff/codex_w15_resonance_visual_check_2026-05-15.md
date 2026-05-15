# Codex W15 共鸣/强化/开锋视觉验收 closeout

## 1. 一句话结论

11 张主截图完成，9/11 PASS，1 WARN，1 FAIL。共鸣度阶段、强化等级、战斗次数、开锋 0/1/2/3 槽视觉主链路成立；唯一明确 FAIL 是利器·蟠龙刀详情未渲染师承遗物 chip。

## 2. 环境与启动记录

- HEAD: `d0e0266`
- 同步: `git pull --rebase --autostash` 成功，快进到 `d0e0266`，autostash 已应用。
- 生成: `dart run build_runner build --delete-conflicting-outputs` 成功；当前 build_runner 提示该参数已移除并忽略，生成 2 个输出。
- 构建: `flutter build windows --debug` 成功，产物 `build\windows\x64\runner\Debug\wuxia_idle.exe`。
- GUI: `Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe` 后确认窗口可见，首次 `MainWindowHandle=2164408`；后续为重拍单张截图有干净重启。
- 截图规格: 窗口固定 1280x900，截图落 `docs/screenshots/w15_resonance/`。
- 路径: 走真 GUI 路径，未走 widget fallback。

## 3. 截图清单与 PASS/FAIL 评级

| # | 类别 | 装备/操作 | 预期 chip 组合 | 截图路径 | 评级 | 备注 |
|---|---|---|---|---|---|---|
| 1 | 仓库列表 | 15 件 | tier 分组 + fixture 行可见 | `docs/screenshots/w15_resonance/01_inventory_15_eq.png` | WARN | 1280x900 单屏无法同时容纳全部 7 阶与 15 件；截图滚到底部，能看到寻常货与下半段分组，前半段已在导航中确认。 |
| 2 | 详情屏 chip | 寻常货·铁剑 | +0 / 生疏 / 0 次 | `docs/screenshots/w15_resonance/02_xunchang_shengshu_plus0.png` | PASS | 三 chip 清晰。 |
| 3 | 详情屏 chip | 像样货·长剑 | +5 / 趁手 / 200 次 | `docs/screenshots/w15_resonance/03_xiangyang_chenshou_plus5.png` | PASS | 三 chip 清晰。 |
| 4 | 详情屏 chip | 好家伙·宣花斧 | +10 / 默契 / 800 次 | `docs/screenshots/w15_resonance/04_haojiahuo_moqi_plus10.png` | PASS | 三 chip 清晰。 |
| 5 | 详情屏 chip | 利器·蟠龙刀 | +15 / 心剑通灵 / 2500 次 + 师承遗物 chip | `docs/screenshots/w15_resonance/05_liqi_xinjian_plus15_heritage.png` | FAIL | 共鸣/强化/战斗次数正确，但未看到师承遗物 chip。 |
| 6 | 详情屏 chip | 重器·青虚剑 | +19 / 默契 / 1500 次 | `docs/screenshots/w15_resonance/06_zhongqi_moqi_plus19.png` | PASS | 三 chip 清晰。 |
| 7 | 详情屏 chip | 神物·天问剑 | +0 / 心剑通灵 / 5000 次 | `docs/screenshots/w15_resonance/07_shenwu_xinjian_plus0.png` | PASS | 三 chip 清晰。 |
| 8 | 开锋槽 | 铁剑 0 槽 | 3 槽全锁 | `docs/screenshots/w15_resonance/08_aperture_zero_slots.png` | PASS | slot1/2/3 均锁定，解锁条件可读。 |
| 9 | 开锋槽 | 宣花斧 1 槽 | slot1 attack +15%，slot2/3 锁 | `docs/screenshots/w15_resonance/09_aperture_one_slot_attack.png` | PASS | unlocked/locked 对比明确。 |
| 10 | 开锋槽 | 蟠龙刀 2 槽 | slot1 attack / slot2 speed，slot3 锁 | `docs/screenshots/w15_resonance/10_aperture_two_slots.png` | PASS | 两槽已开，第三槽锁定。 |
| 11 | 开锋槽 | 青虚剑 3 槽 | slot1 attack / slot2 speed / slot3 specialSkill | `docs/screenshots/w15_resonance/11_aperture_three_slots_full.png` | PASS | 三槽已开，slot3 显示 `专属技能：--`。 |

## 4. 共鸣度阶段切换反馈(本批重点 A)

- 四阶段文案与 battleCount 对得上：铁剑 0=生疏，长剑 200=趁手，宣花斧 800/青虚剑 1500=默契，蟠龙刀 2500/天问剑 5000=心剑通灵。
- chip 颜色随装备阶颜色走，辨识度足够；同一信息区中共鸣、战斗次数、强化等级没有截字。
- 仓库 row 上也能看到共鸣文案，可作为横向扫视入口。

## 5. 多次强化里程碑反馈(本批重点 B)

- +0/+5/+10/+15/+19 五档均显示成立，颜色跟随装备阶，数字清晰。
- 详情顶部数值区能同时看到强化等级与攻击/血量/速度变化；+19 青虚剑、+15 蟠龙刀、+0 天问剑形成足够明显的对比。

## 6. 开锋槽 build 反馈(本批重点 C)

- 0/1/2/3 槽四档 unlocked/locked 区分明显：已开槽黄框 + `已开锋`，未开槽灰框 + `强化到 +N 解锁`。
- attack/speed/specialSkill 三种 type 文案可读；slot3 `specialSkillId=null` 时显示 `专属技能：--`，符合本批只看占位的要求。
- 开锋 Tab 初始高亮成立，弹窗 3 行完整可见。

## 7. 师承遗物 chip 顺手观察

- 利器·蟠龙刀详情未找到师承遗物 chip。
- 详情信息区仅看到 `利器 / 武器 / 刚猛`、攻击/血量/速度/+15、`心剑通灵 战斗 2500 次`。
- 未看到 `内力上限 +5%` buff 行或同义文案。该项建议作为本批唯一明确视觉缺口处理。

## 8. 工程教训(本会话产)

- Windows `CopyFromScreen` 截图坐标是屏幕绝对坐标；人工读图时是窗口相对坐标，本次多次踩到 80,60 的窗口偏移，需要统一换算。
- Flutter desktop 的 `Esc` 会和路由返回发生交互；在弹窗连续验收时容易从 dialog 退回上级菜单。最终对关键开锋截图采用“干净启动 -> 进入 VC15-res -> 目标装备 -> 截图”的方式稳定完成。
- InventoryScreen ExpansionTile row click 可用，但折叠/滚动状态会影响坐标。开锋截图重拍时，干净启动比长链路连续导航更稳。
- 未走 widget fallback。

## 9. 下次推荐

- 本批三项挂账中，共鸣阶段切换、多次强化里程碑、开锋槽 build 可收口。
- 师承遗物 chip 需要补 UI 渲染或确认 fixture 标记是否未传到展示层。
- 真 GUI 坐标脚本建议封装窗口偏移与截图函数，避免后续手动换算。
