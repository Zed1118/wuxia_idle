# Codex 战斗界面与视觉优化验收单

日期：2026-07-16  
分支：`codex/battle-ui-stage`  
worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/battle-ui-stage`  
基线：`39947967`  
实现头：`c53d050b`（本验收单另有文档提交）

## 1. 建议先看

1. 标准战斗 1440×900：`build/visual_acceptance/final_acceptance_refresh/battle_tap_live/1440x900/battle_tap_live.png`
2. 标准战斗 1280×720：`build/visual_acceptance/final_acceptance_refresh/battle_tap_live/1280x720/battle_tap_live.png`
3. 实战命中轮廓：`build/visual_acceptance/battle_ui_live_vfx_silhouette/frame_45.png`
4. 出战编成阵列：`build/visual_acceptance/team_lineup_formation_final/`
5. 角色全人物档案：`build/visual_acceptance/character_panel_full_standee/1280x720/character_panel.png`
6. 江湖见闻录：`build/visual_acceptance/baike_titlebar_unified/encounter_codex/1280x720/encounter_codex.png`
7. 武学卷册：`build/visual_acceptance/baike_cards_refined/skill_codex/1280x720/skill_codex.png`

## 2. 战斗界面完成内容

- 标准 3v3 改为全身人物水墨舞台；双方同序槽位严格镜像，首席靠近交锋线。
- 新山口长卷背景贯通六个站位；人物按透明图 alpha 有效脚底锚定，并增加接触墨影，消除悬浮贴图感。
- 祖师、两弟子、山贼刀客、山贼弓手、隐世老者、杀手、撑伞高手、塔主等透明全身立绘接入；Boss、心魔、轻功、群战均复用统一舞台。
- 底部改为木案 + 宣纸竖签技能栏 + 战备行囊；技能仍是点按释放，没有拖放。
- 单体技能：点技能进入待发，再点敌人立即释放；唯一合法目标时直接释放。群体技能点击即释放；长按看详情；ESC/空白/重复点选可取消。
- 近战前压后回位，远程留位走水墨弹道；命中闪只染人物非透明轮廓，不再出现矩形亮块。
- 蓄势、破招、破绽脚印、目标高亮、死亡灰化、胜负题字、战后重试均按克制水墨基调收口。
- 五位数状态牌使用 `K` 缩写；不改真实战斗数值。

## 3. 配套页面优化

- 出战编成：三席改为山口阵列预览，点选换席；祖师必须出战但不锁死首席。
- 主线章节/关卡：统一暖墨长卷、居中题字与路线桌面。
- 角色面板：祖师与弟子头像牌改为透明全身人物签。
- 心法、九霄塔、闭关地图：统一宣纸 `WuxiaTitleBar`。
- 江湖见闻录：完整宣纸标题栏与五页签；奇缘验收不再显示内部英文 id；武学条目改为卷册卡。
- 主菜单、装备仓库、商店、桃花岛、藏卷阁完成烟测目检；未擅自改业务逻辑。

## 4. 验证证据

- `flutter test`：4048 项全部通过（战斗 UI、编成、百科以及全项目套件均包含在内）。
- `flutter analyze`：`No issues found`。
- `flutter build macos --debug`：成功生成 `build/macos/Build/Products/Debug/wuxia_idle.app`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过。
- 最终烟测：14 条 1280×720 路由 + 战斗双视口 + 百科复拍，共 19 份日志全部含 `VISUAL_ROUTE_READY` 和窗口级 `VISUAL_CAPTURE`；无 `VISUAL_ROUTE_ERROR`、RenderFlex overflow 或未处理异常。
- worktree 在验收单提交前为 clean。

## 5. 集成边界与冲突提示

- 没有 push、没有 PR、没有合并 main。
- 未改数值 YAML、schema/saveVersion、战斗结算或背包消费；战备行囊仍是视觉预留位。
- 共享文件 `lib/shared/strings.dart` 仅追加 6 条战斗案台文案。
- `GDD.md` 将已拍板的技能拖放口径改为点按；与其他分支合并时应保留该口径。
- `lib/shared/theme/wuxia_tokens.dart` 追加战斗立绘与山口背景路径。
- 与 Claude 分支集成时，优先人工处理 `lib/shared/strings.dart`、`GDD.md`；其余主要改动位于 battle presentation、邻接 UI 与新资产。
- 已对 Claude 当前 `docs/equip-baicao-orchestration@25221323` 执行只读 `git merge-tree --write-tree` 预演，返回成功且无文本冲突；共享文件仍建议合并后人工复核语义，不把“无冲突”当作“无需检查”。

## 6. 9:10 目检顺序

1. 看 1440 战斗构图、双方镜像、主角是否处于靠近中场首席位。
2. 看人物脚底与石滩接触、后排缩放、状态牌是否仍有贴图感。
3. 点单体/群体技能，确认没有拖放，待发与取消符合口径。
4. 看近战前压、远程弹道、受击闪和破绽脚印是否克制。
5. 打开出战编成，交换第一/第二/第三席，再进战斗确认顺序同步。
6. 快速看章节、关卡、角色、心法、九霄、闭关、见闻录的导航视觉是否连续。
