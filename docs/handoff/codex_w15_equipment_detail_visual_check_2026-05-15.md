# Codex W15 装备详情屏视觉验收 closeout

## 1. 一句话结论

7 张目标截图完成,6/7 PASS,1 WARN,0 FAIL。装备仓库、4 件详情屏、强化/开锋按钮分流均可渲染与操作;唯一 WARN 是 `weapon_xiangyang_gang_dao` 主屏只见 1 段典故,与派单预期 2 段不一致。

## 2. 环境与启动记录

- HEAD: `2a4c19a485ee1307594a5fbc25d6a5f02d3b6d36`
- `git pull --rebase --autostash`: fast-forward 到 `2a4c19a`,autostash 已应用。
- `dart run build_runner build --delete-conflicting-outputs`: PASS;新版 build_runner 提示该参数已移除并 ignored;写 0 outputs。
- `flutter build windows --debug`: PASS;产物 `build\windows\x64\runner\Debug\wuxia_idle.exe`。
- 启动命令: `Start-Process build\windows\x64\runner\Debug\wuxia_idle.exe`。
- GUI 可见性: `wuxia_idle` 进程 `MainWindowHandle=3081902`;窗口固定 `1280x900`;截图前用 `SetWindowPos(..., 20, 20, 1280, 900, HWND_TOPMOST)` 保持前台。
- 本轮未跑 widget/unit test,未实际执行强化。

## 3. 截图清单与 PASS/FAIL 评级

| # | tier/操作 | 装备/按钮 | 截图路径 | 评级 | 备注 |
|---|---|---|---|---|---|
| 1 | 仓库列表 | - | `docs/screenshots/w15_equipment_detail/01_inventory.png` | PASS | 4 tier 分组全展开,数量为利器 1 / 好家伙 3 / 像样货 3 / 寻常货 2。 |
| 2 | 利器详情 | `weapon_liqi_long_quan` | `docs/screenshots/w15_equipment_detail/02_liqi_long_quan.png` | PASS | 2 段典故与段间 `· · ·` 可见,底部按钮完整。 |
| 3 | 好家伙详情 | `weapon_haojiahuo_qing_feng_jian` | `docs/screenshots/w15_equipment_detail/03_haojiahuo_qing_feng_jian.png` | PASS | 2 段典故可读,蓝色 tier 映射清楚。 |
| 4 | 像样货详情 | `weapon_xiangyang_gang_dao` | `docs/screenshots/w15_equipment_detail/04_xiangyang_gang_dao.png` | WARN | 布局无截字,但主屏只见 1 段典故,与派单预期 2 段不一致。 |
| 5 | 寻常货详情 | `armor_xunchang_bu_yi` | `docs/screenshots/w15_equipment_detail/05_xunchang_bu_yi.png` | PASS | 1 段典故符合预期,信息卡与底部按钮完整。 |
| 6 | 强化按钮 | `强化` | `docs/screenshots/w15_equipment_detail/06_enhance_tab.png` | PASS | EnhanceDialog 弹起后 `强化` Tab 0 高亮;未点击执行强化。 |
| 7 | 开锋按钮 | `开锋` | `docs/screenshots/w15_equipment_detail/07_forging_tab.png` | PASS | EnhanceDialog 弹起后 `开锋` Tab 1 高亮。 |

## 4. 视觉层问题反馈(给 Mac)

- 信息卡:名称、tier chip、slot chip、流派 chip、遗物 chip 与三围信息层级清楚;4 个 tier 的颜色区分明显。
- 典故段:字号与行距在 1280x900 下可读;龙泉剑/青锋剑段间 `· · ·` 分隔效果稳定。
- 按钮:底部 `强化` / `开锋` 两列等宽,视觉层级清楚,无贴边截字。
- AppBar:tier 色与仓库列表色系一致;利器黄、好家伙蓝、像样货/寻常货低饱和映射可辨。
- 需复核:`weapon_xiangyang_gang_dao` 本轮只渲染 1 段典故;若数据预期为 2 段,建议 Mac 端核 `presetLoreIds.first` 与 lore 段数链路。

## 5. 节奏层问题反馈(给 Mac)

- 仓库列表点击 row 后 `Navigator.push` 到详情屏过渡自然,返回后列表位置稳定。
- 详情屏底部按钮弹出 EnhanceDialog 顺滑;`initialTab=0/1` 分流正确。
- 典故区主屏滚动未见卡顿;本轮抽样内容均能在一屏内看清标题与段落顶部。

## 6. 工程教训(本会话产)

- P5 点击后会进入角色面板,需先点 AppBar 返回到 Phase 2,再返回主菜单进装备仓库。
- 当前环境直接 `Start-Process` 可得到非 0 `MainWindowHandle`;本轮未再走已知 Access denied 的 `schtasks` 路径。
- `CopyFromScreen` 截图包含标题栏;窗口固定在 `(20,20)` 后,Flutter 内容点击仍需用屏幕绝对坐标。
- 过程图 `00_*.png` 已清理,截图目录最终只保留 7 张目标图。

## 7. 下次推荐

- 本轮视觉验收可收口,但建议先确认 `weapon_xiangyang_gang_dao` 段数 WARN 是否是数据预期差异还是 UI 只取首条 lore 的链路问题。
- 3 段典故(重器 / 宝物 / 神物)仍按派单挂账,等下波 stage drop / craft 路径打通后补真机验证。
