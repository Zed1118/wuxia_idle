# Spec: 爆品展示内容化 + 印章重设计 + tagline 字段（A+B 批）

> 2026-06-12 · xhigh · 长线打磨期「爆品展示体验」波
> 前置：reward/uiPaperOpen 音效已落位合 main(`cd85728a`)；本波解决印章遮文字 + 爆品缺信息量。

## 背景与 prototype 定稿
- 真玩反馈：①爆品印章盖在装备名正中(印章与名同挤 Stack center → 文字漏出)；②爆品展示太素、缺"得宝"信息量与仪式感。
- Web prototype 迭代定稿(throwaway demo，job tmp，已答即弃)：**A 角落落款**——图标+名居中清晰、墨团染 tier 色作氛围、**印章 78px 移右下角盖落作落款**(不遮主体) + **属性行** + **典故金句**(印章定后渐入)。
- 本 spec 覆盖 **A(数据层 tagline) + B(爆品展示重构)**。**C 时序重排(爆品取代结算 overlay)留下波**单独 spec(跨 battle_screen/mainline/tower)。

## A · 数据层 tagline
### A1 schema（equipment_def.dart:6-94）
- 加 `final String? tagline;`(可选，缺省 null) → 构造 + fromYaml `tagline: y['tagline'] as String?`。
- `data_schema.md` §5.1 装备表补 tagline 行(爆品典故金句，tier≥重器必填)。
### A2 校验红线（新增测）
- 遍历所有 EquipmentDef，`tier.index ≥ treasureDrop.minTier.index`(重器+)者 `tagline` 必非空非纯空白。
- 理由：仅爆品(tier≥重器)走印章展示用 tagline，低 tier 不展示无需填。约束语义式红线(非具体值)，35 件全覆盖防漏。
### A3 文案（35 件：重器12/宝物12/神物11）
- 全部已有 presetLoreIds → 从各自 lore **提炼一句凝练金句**(非凭空)，写入 equipment.yaml `tagline:`。
- 体例：≤22 字，器物题记/点睛句口吻(参天问剑「剑身刻十七问，皆屈子问天未答之句」)，水墨克制、禁网游腔。

## B · 爆品展示重构
### B1 TreasureHighlight 扩字段（treasure_highlight.dart:4-17）
- 加 `final int attack; final int health; final int speed; final String? tagline;`(attack/health/speed 来自掉落 roll 实例 baseAttack/Health/Speed；tagline 来自 def)。
### B2 caller 接线（treasure_drop_overlay.dart:175-196 playTreasureDropIfAny）
- 当前从 drops.equipments 仅取 def 字段。改：每件 Equipment 实例取 `baseAttack/baseHealth/baseSpeed`(已 roll) + `getEquipment(defId).tagline` → 构造完整 highlight。
### B3 TreasureDropContent 布局（treasure_drop_overlay.dart:17-117）
- crest 区(墨团染 glow + 图标64+名 居中 + **印章78右下角落款盖落**) + extra 区(属性行 ⚔攻击/❤血量/⚡速度 + 典故句斜体暗金)。
- 印章：64→78，从 Stack center 移右下角(right/bottom 锚定)，盖落动画保留(translateY-90+rotate 归位)。
- 内容渐入：属性+典故在印章定后(t>0.34)opacity 0→1。
- tagline null 兜底不渲染典故区(实际爆品恒有，A2 保证)。
- 720p 校验：暗幕全屏，竖排总高 <720(memory feedback_visual_size_min_resolution)。
### B4 widget test（treasure_drop_content_test.dart:8-10 _h）
- `_h()` 补 attack/health/speed/tagline 参数；加属性文本 + 典故文本断言；tagline null 分支断言不显典故区。

## 红线守护
- 数值红线不动(普伤/血/内力/装备攻击)；只展示既有 roll 值，不改公式。
- 不动 numbers.yaml / GDD / 战斗公式；data_schema.md 仅补 tagline 行(字段已获用户授权)。

## 闸门
- flutter analyze 0；全量测全过(+tagline 红线测 + TreasureDropContent 新断言)；widget test 绿。
- 视觉验收：重编 macos 真玩(打 stage_04_05 必掉神物)或 Codex 截图(TreasureDropContent 静态)。

## 实现顺序（TDD）
1. A1 schema(加字段，analyze 绿) → 2. A2 红线测(先红) → 3. A3 文案 35 句(红线转绿)
4. B1 highlight 扩字段 → 5. B2 caller 接线 → 6. B3 布局(widget test 先红后绿) → 7. B4 test
8. 闸门 + 视觉验收
