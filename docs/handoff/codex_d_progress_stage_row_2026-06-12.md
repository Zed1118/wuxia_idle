# D 四类养成进度「五要素」标准化 · Codex 视觉验收派单（2026-06-12）

验收对象：`build/macos/Build/Products/Debug/wuxia_idle.app`（commit `39e2532a` 快照，已合 main + push）

二进制：`/Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app/Contents/MacOS/wuxia_idle`

## 启动方式（direct binary + 1280×720）

```bash
VISUAL_WINDOW_W=1280 VISUAL_WINDOW_H=720 \
"/Users/a10506/Desktop/Projects/挂机武侠/build/macos/Build/Products/Debug/wuxia_idle.app/Contents/MacOS/wuxia_idle"
```

窗口显示「验收总入口」（hub），点路由按钮进屏 → 截图 → 左上返回 → 下一个。
**所有判定截图须在 `System Events` 确认窗口 size = `1280, 720` 后截取。**

截图目录：`docs/handoff/codex_d_progress_stage_row_2026-06-12/`

## 改动背景（验收要点）

新增纯表现层基元 `StageProgressRow`（五要素 = 当前阶段名 + 进度条 + 当前效果 + 下一阶效果 + 来源/标记）。
本批把**修炼度 / 共鸣度**两类此前缺失或散落的进度展示，统一到与**熟练度**相同的布局语言。

**核心判定（spec 闸门）= 四类一致性**：三条路由里出现的 `StageProgressRow` 应视觉一致——
同一套「标题/阶段名行 → 青灰进度条(MeridianBar) → 当前效果(柔灰左) ↔ 下一阶效果(金字右)/进度(柔灰)」骨架，
水墨 token 统一（墨字/青进度/金下一阶），无 Material 饱和色、无溢出截断。

---

## 路由 1：技法面板·主修 hero（修炼度倍率行）

hub 按钮：**心法面板·主修 hero 打坐内丹态**（`technique_panel_hero`）
seed：主修圆满（yuanMan）progress=1500。

判定要点：
- 9 层阶梯图保留（流派色/金当前/灰未到），层名徽章「圆满」+「5 / 9 层」。
- **徽章下新增一行倍率**：`伤害 ×1.75 · 下一阶 ×2.00`（当前层 / 下一层伤害倍率）。
- 倍率行字号小、柔灰，不喧宾夺主；阶梯视觉未被替换。

截图：`01_technique_panel_hero.png`
判定：（PASS / FAIL）
现象：

---

## 路由 2：角色页·主修心法卡（修炼度五要素 Row）

hub 按钮：**角色页·档案头验收**（`character_panel`）
seed：主修圆满（yuanMan）progress=1500。**可能需向下滚动到「主修」心法卡**。

判定要点：
- 主修卡内（顶部大字心法名 + 品阶徽章下方）= 一个完整 `StageProgressRow`：
  - 阶段名领头「圆满」（卡内子段不重复心法名）。
  - 青灰进度条（约 1500/N 比例，非空非满）。
  - 左下当前效果 `伤害 ×1.75`，右下金字 `下一阶 ×2.00` + 柔灰进度 `1500 / N`。
- 进度条由原 Material `LinearProgressIndicator`（流派色细条）换成水墨 `MeridianBar`（青灰墨迹），属预期变化。

截图：`02_character_panel_main_technique.png`
判定：（PASS / FAIL）
现象：

---

## 路由 3：装备详情·共鸣度 Row（新增进度条）

hub 按钮：**装备详情页·水墨包装验收**（`equipment_detail_screen`）
seed：神物天问剑 battleCount=1240（默契阶）。

判定要点：
- 共鸣段 = 一个 `StageProgressRow`：
  - 阶段名领头「默契」。
  - **新增青灰进度条**（此前共鸣段无进度条，约 1240→2000 阶内比例）。
  - 左下当前效果 `当前属性加成 +20%`，右下金字 `下一阶 +30%` + 柔灰 `战斗 1240/2000`。
- 进度条下方保留解锁招标记行 `✦ 已解锁「人剑合一」招式`（默契阶解锁；剑鸣此阶无，不显）。

截图：`03_equipment_detail_resonance.png`
判定：（PASS / FAIL）
现象：

---

## 一致性总判（spec 闸门核心）

对比三张截图的 `StageProgressRow`：骨架 / 字号 / 配色（墨字·青条·金下一阶·柔灰进度）是否一致。
截图：`04_consistency_compare.png`（可选，并排或说明）
判定：（PASS / FAIL）
现象：

---

## 已知未覆盖（低风险，告知）

- **藏经阁（熟练度 `SkillProficiencyRow` + 残页 `FragmentProgressRow`）无专属 VISUAL_ROUTE**。
  熟练度本批仅重构委托同一基元、可见文案未变（视觉等价）；残页仅标题字号 13→14 w600。
  二者与上述三路由共用同一 `StageProgressRow` 基础 → 一致性由构造保证。
  如需 Codex 眼验藏经阁，回报 Claude 端加一条 `cangjingge` 视觉路由（需 1 次代码改 + 重编包）。

## 硬约束

- 窗口固定 1280×720（判定前 System Events 确认）。
- 此包 = commit `39e2532a` 快照；代码再改须 `./tool/build_acceptance.sh` 重编。
- 截图存 `docs/handoff/codex_d_progress_stage_row_2026-06-12/`，文件名按上方约定。
- FAIL 项写清现象 + 截图，回报 Claude 端逐项根因复核（沿 R1→R2 体例）。
