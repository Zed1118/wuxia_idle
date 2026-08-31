# M4-G 战斗角色立绘解码预算计划

## 结果合同

- 单一目标：让 `Phase0aBattleScreen` 的角色立绘复用既有 `WuxiaImage` 渲染宽度解码预算，减少 24-active 群战的 build/raster 成本，不改变领域单位、位置、攻击、难度或资产。
- 基线：`4b92d14c8a5547ea01e918c57a6580fcbc569813`；M4-F 六轮 Mac Profile 的 24-active 帧门 6/6 FAIL。
- 实时基线：1280×720 p99 total 46.521–46.930ms；1440×900 44.851–45.899ms；build p99 18.128–18.441ms，raster p99 28.366–29.477ms。角色源图约 965×1672 / 1024×1536，屏上立绘位约 112×118，当前直接 `Image.asset`。
- 分母：M4-G `0/1`；生产屏角色全部走 `WuxiaImage`、机器守卫/破坏证红/独立 Gate 完成后为 `1/1`。性能矩阵是否过线单独按实测记录，不因代码接线自动 PASS。
- 成本上限：一个独立 worktree、一个最小生产文件、一个测试文件、一次 Gate；若同矩阵仍明显超线，停止扩张并登记下一热点，不连带改 LOD/特效/数值。

## 范围与验证

- 只把角色 `Image.asset(visual.assetPath, fit: contain, medium)` 替换为仓库统一 `WuxiaImage(visual.assetPath, fit: contain)`；由实际布局约束与 DPR 计算 `cacheWidth`。
- RED：24-active 生产屏必须存在 25 个 `WuxiaImage`（玩家 + 24 敌人），每个对应 actor 立绘；当前原始 `Image.asset` 必须红。
- 破坏证红：删除 `WuxiaImage` 接线；强制横向无界约束使解码预算为空。两向各失败至少一项并精确还原。
- targeted → analyze → format → macOS profile build → 同参数矩阵诊断 → 持锁全量 → receipt → 独立 Gate。

## 挂账

- 降采样后的 24-active 立绘清晰度、水墨边缘、击中闪白、姿态洗色与动画观感需真人集中目检。
- Windows 与 DPR 2.0 发布矩阵仍挂账；本机矩阵观测 DPR 为 1.0。

## 实施记录

- RED：在原始 `Image.asset` 接线上运行新增守卫，`0/1`、恰好 1 项失败（生产屏找到 0 个 `WuxiaImage`）。
- GREEN：生产立绘改走现有 `WuxiaImage` 后，新守卫 `1/1`；相邻回归 `50/50`。
- 提交前双向破坏证红：撤回生产接线为 `0/1`；用 `UnconstrainedBox` 退化为无解码预算为 `0/1`；均精确还原。
