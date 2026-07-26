# 全局视觉收口第二阶段实施计划

> 日期：2026-07-26  
> 分支：`codex/global-visual-polish-phase2`  
> worktree：`.worktrees/global-visual-polish-phase2`  
> 基点：`fb5a8851 [READY] 完成全局内容与视觉收口`

## 一、目标

在上一阶段 125 条视觉 route 全量收口基础上，继续处理复查发现的系统性视觉债：

1. 增强战斗人物脚底落地感和状态牌归属；
2. 让远征、断魂庄、档案/图鉴等长尾深色页面共享同一套水墨层级；
3. 修复装备详情重复素材，建立详情素材规格与重复门禁；
4. 补齐场景安全裁切、用途级头像裁切和颜色 token；
5. 保持既定水墨风格、页面几何、信息顺序和操作路径不变。

## 二、明确边界

### 本阶段允许

- 调整颜色、描边、纹理、接触影、状态标记、局部间距和共享视觉组件；
- 补充透明素材、安全区、焦点元数据与资产门禁；
- 把既有页面级样式迁入语义 token；
- 新增确定性视觉 route 与 widget/资产测试。

### 本阶段不做

- 不扩宽存档、设置、归来、藏卷阁、兵器详情等固定窄宽结构；
- 不重排战斗 HUD、技能槽、阵位或案台；
- 不把仓库筛选改为侧栏、页签或折叠信息架构；
- 不增加 `rejected_task_registry.md` 中已否玩法或提示；
- 不擅自引入正式 CJK 字体文件：字体授权与包体预算需先拍板；
- 不把普通带背景人物画冒充透明战斗站姿；
- 不修改战斗数值、经济、掉落、存档 schema 或三系锁死规则。

## 三、任务切片

### Slice 1：战斗人物落地与状态归属

- 强化现有脚底接触墨影的核心、扩散和近景适配；
- 在状态墨拓顶部加入克制的小型归属指针/印记；
- 暴击红迁入战斗颜色 token；
- 补 `CharacterAvatar`、`DamagePopup` 和常规战场 widget 测试；
- 跑 1280×720 / 1440×900 战斗 route smoke，重点目检塔 13/14。

### Slice 2：长尾深色页面共享视觉语言

- 新建或扩展共享的深色档案题签、身份印记、分区和选择态组件；
- 先接入远征总览、断魂庄装载、门派谱/图鉴代表页；
- 保留原最大宽度、卡片排列、滚动和交互；
- 补生产路径 widget tests 与双视口截图。

### Slice 3：装备详情素材规格与重复门禁

- 为三组 icon/detail 完全重复的装备补专用详情画面；
- 定义详情图最小尺寸、透明边界、主体占比和暗/浅底可见性；
- 增加精确重复与感知重复检测，允许清单必须显式登记；
- 验证仓库、详情页和审计 gallery。

### Slice 4：场景焦点、头像用途与颜色 token

- 为四张尺寸离群场景补焦点/安全裁切元数据并接入生产背景组件；
- 为生产圆形头像增加可选 focus/crop，不改变站姿素材；
- 将高复用深底状态色和暴击色收口到 token；
- 将合理的特效/透明渐变例外登记到 allowlist。

### Slice 5：终验与复查

- `flutter analyze`；
- 所有直接相关 targeted tests；
- 批末并发全量 `flutter test --no-pub`；
- 1280×720、1440×900 全量/重点 visual smoke；
- 复查水墨基调、布局未漂移、交互语义未丢失；
- 更新本文件恢复点并冻结 `[READY]`。

## 四、需外部输入的后续切片

以下不阻塞本阶段代码和素材管线，但不能冒充已完成：

1. 正式跨平台中文字体：需要字体授权和包体预算拍板；
2. 九名候选透明战斗站姿：需要独立美术产出与角色一致性验收；
3. AI 题字/印章边界：需要用户确认允许规则；
4. Windows 100% / 125% / 150%：需要发布目标机实机终验。

## 五、验收标准（CLAUDE.md §8.2）

### 生产接线

- 战斗接触影、状态归属和暴击色由正式 `BattleField` / `CharacterAvatar` / `DamagePopup` 消费；
- 长尾视觉组件接入真实页面，不停在 gallery 或 fixture；
- 装备详情与场景焦点由生产资产路径消费。

### Targeted tests

- 每个 Slice 至少有直接相关 widget/asset test；
- 测试命令、通过数和异常记录写入恢复点；
- 交互组件若改动，补 semantics、focus、键盘和 mouse cursor 验证。

### UI/UX

- 1280×720、1440×900 两个常规桌面视口均 READY；
- 不以 1024×2400 等超高视口替代常规验收；
- 不新增 Material 默认饱和色；
- 不改变既有布局、信息顺序或操作路径。

### 红线影响

- 数值硬红线：不触及；
- 三系锁死：不触及；
- 在线 = 离线：不触及；
- 反主流清单：不触及；
- Dart 中文文案/数值硬编码：不新增，玩家文案继续走 `UiStrings`。

### 残留风险

- 未产出的字体、九张透明站姿、Windows 实机和伪文字拍板必须明确保留；
- 调试 gallery 问题不得误报为生产 P0；
- 截图、日志和临时生成物不得提交。

## 六、当前恢复点

- 状态：Slice 1、Slice 2 已完成并提交前验收；Slice 3 待开始；
- 最后完成：
  - 从 `fb5a8851` 建立独立分支/worktree；
  - `flutter pub get`；
  - `dart run build_runner build` 生成 gitignored 代码；
  - 基线 `flutter analyze` 0 issue；
  - 已读取 `CLAUDE.md`、`rejected_task_registry.md` 和工作树/视觉技能；
  - 已通过 CodeGraph 与源码定位战斗生产入口、长尾页面和相关测试。
  - 脚底接触墨影扩大安全覆盖并增加实心接触核；
  - 状态墨拓增加流派/首领色归属指针，不移动信息板；
  - `damage_popup.dart` 唯一中风险高饱和硬编码色迁入战斗绛红 token；
  - 高/中风险美术色调问题纳入测试硬门禁；
  - `battle_tower_floor_14` 双视口真窗口截图目检通过，布局与战位未漂移。
  - Slice 1 已提交：`fb8de088 增强战斗落地感与状态归属`；
  - 新增 `InkPageHeader`、`InkSectionLabel`、`InkListCard` 三个长尾深色页面共享视觉件；
  - 远征总览、断魂庄装载统一为宣纸标题栏、身份题头、枯笔分区与墨底选择卡；
  - 门派谱及人物纪事共享卡面和分区题签，顶部动作入口、内容顺序和满宽卷轴布局不变；
  - 远征、断魂庄、门派谱各自 1280×720、1440×900 真窗口目检通过，无溢出或异常日志。
- 下一步：
  - 提交 Slice 2；
  - 修复三组装备 icon/detail 完全重复素材；
  - 建立详情素材规格、精确重复和感知重复门禁。
- 已跑验证：
  - `flutter analyze`：0 issue（代码生成后，2026-07-26）。
  - `flutter test --no-pub test/features/battle/presentation/character_avatar_test.dart test/features/battle/presentation/damage_popup_test.dart test/tools/art_tone_audit_test.dart`：29 pass / 0 fail。
  - `flutter analyze`：0 issue（Slice 1 修改后）。
  - `battle_tower_floor_14` × 1280×720、1440×900：2/2 READY，异常日志 0。
  - `flutter test --no-pub test/shared/widgets/wuxia_ui/ink_archive_chrome_test.dart test/features/expedition/expedition_overview_screen_test.dart test/features/boss_gauntlet/gauntlet_loadout_screen_test.dart test/features/character_panel/presentation/lineage_panel_screen_test.dart`：20 pass / 0 fail。
  - `flutter test --no-pub test/features/character_panel/lineage_character_detail_screen_test.dart`：8 pass / 0 fail。
  - `flutter analyze`：0 issue（Slice 2 修改后）。
  - `expedition_overview`、`gauntlet_loadout`、`lineage_codex` × 1280×720、1440×900：6/6 READY，异常日志 0。
- 阻塞项：
  - 无；正式字体、九张透明站姿、Windows 实机和伪文字规则属于后续外部输入，不阻塞 Slice 2。
