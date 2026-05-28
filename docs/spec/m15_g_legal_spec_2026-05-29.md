# M15-16 G 段:法律商业 spec

> 起草:2026-05-29 · 目标 M15-16 · 对应 RELEASE_CHECKLIST §G
> 关联 Q1-Q5 拍板:**Q1 海外 only(国内放 1.x)** · ICP 备案 / 版号本 spec 不列

## 1. 目标

CHECKLIST G 5 子项 0/5 → 5/5(因 Q1 海外 only,ICP 备案此版本砍,实际 4/5 即闭环)。
- ~~中国 ICP 备案~~(Q1 砍,1.x 评估国内发行时再启动)
- AI 出图版权声明(自训练 LoRA · 风格独立 · 非 IP 仿冒)
- 字体可商用授权
- BGM/SFX 来源清单
- 隐私政策 + EULA(Steam 模板适配)

## 2. 拆 Batch

| Batch | 内容 | Claude 推 | 用户办 | 估时 |
|---|---|---|---|---|
| **G1 AI 出图版权声明** | doc 起草:LoRA 自训练 / 风格独立证明 / 训练集来源 / 非 IP 仿冒声明 / 衍生作品权属 | 100% | 拍板最终措辞 | ~2h |
| **G2 字体可商用清单** | 全项目使用字体审计(grep `fontFamily` + assets/fonts/)+ 每字体可商用证明 / 授权类型 / fallback 方案 | 80% | 字体采购($) | ~2h Claude + 用户买字体 |
| **G3 BGM/SFX 来源清单** | E 段素材授权清单(Epidemic Sound 月订 / CC0 / 配音员合约)+ LICENSE.txt 体例 + 衍生作品权属 | 100% | E 段素材落定后填 | ~1h |
| **G4 隐私政策** | Steam 模板适配 + 数据收集声明(Sentry crash report / 无个人数据)+ 中/英双语 | 90% | 律师 review(可选) | ~3h |
| **G5 EULA** | Steam 模板适配 + 单机买断 / 不可退款 / 衍生作品 / 版权归属 + 中/英双语 | 90% | 律师 review(可选) | ~2h |
| **G6 ~~ICP 备案~~** | ~~Q1 海外 only 砍~~ | — | — | — |

**总 Claude 推:~10h · 用户操作:字体采购($50-200)/ 可选律师 review($300-800)**

## 3. 决策点

| # | 问题 | 推荐默认 | 影响 |
|---|------|---------|------|
| G-Q1 | AI 出图声明强度:轻度(仅标 LoRA)/ 详细(训练集 + 版权链)/ 律师审核版? | **详细自述版**(Steam tag 必须 AI-Generated 标 · 律师 1.0 release 前 review)| G1 工作量 |
| G-Q2 | 字体方案:全部用思源 / 思源黑体(Apache 2.0 商用)/ 商用字体如方正北魏楷书? | **思源黑体 + 思源宋体**(开源 Apache 2.0 / 完全免费可商用)| G2 预算 |
| G-Q3 | BGM 来源(联动 E 段 Q1):Epidemic Sound 月订 / 永久授权? | **月订**(Demo 期)+ **1.0 release 转永久授权**($30-50/track) | G3 长期成本 |
| G-Q4 | 隐私政策律师:0 律师 / Termly 自动生成($10/月)/ 找律师? | **Termly 自动生成 + 自我适配**(Demo 期)+ **1.0 律师 review** | G4 成本 |
| G-Q5 | EULA 模板:Steam 默认 / 自定义? | **Steam 默认 EULA + 1 段自定义补充**(衍生作品声明)| G5 复杂度 |
| G-Q6 | 中英双语:全双语 / 中文为主 + 英文摘要? | **全双语**(Steam 海外 region 必需) | G4-G5 工作量 ×2 |

## 4. 子任务粒度

- **G1.1**:`docs/legal/ai_disclosure.md` 起草 · 包含:
  - LoRA 训练数据来源(MJ v7 sref 用户原图 / 公共域武侠插画 / 自绘草稿)
  - 风格独立性证明(独有 sref code + 7 阶配色矩阵 + 武侠水墨基调 audit)
  - 非 IP 仿冒声明(不涉及金庸 / 古龙 / 温瑞安等 IP 角色 / 招式名)
  - 衍生作品权属(玩家截图 / 直播 / Mod / fan art 授权范围)
- **G2.1**:`grep -rn "fontFamily" lib/` 字体审计 + `pubspec.yaml fonts:` 段 audit
- **G2.2**:`docs/legal/font_license.md` 思源黑体 + 思源宋体 + (备选)源界明朝体 全 Apache 2.0 / SIL OFL 1.1 LICENSE 文件归位 `assets/fonts/LICENSES/`
- **G2.3**:fallback 方案(如 OS 系统字体缺失时使用 default)
- **G3.1**:`docs/legal/audio_license.md` E 段素材清单(BGM 3 + SFX 36 + 配音 10 = 49 条目)+ 每条目附:来源 / 授权类型 / 使用范围 / 衍生范围
- **G3.2**:`assets/audio/LICENSES/<id>.txt` 单素材 LICENSE
- **G4.1**:Termly 模板生成中文隐私政策 + 自我适配(Sentry crash report / Isar 本地存储 / Steam 成就同步)
- **G4.2**:英文版隐私政策 + 同步翻译
- **G4.3**:游戏内「设置 → 法律 → 隐私政策」入口 widget
- **G5.1**:Steam EULA 默认 + 自定义补充段(衍生作品 / 单机买断 / 不可退款 / 版权归属)
- **G5.2**:中/英 EULA + 游戏内「设置 → 法律 → EULA」入口
- **G5.3**:首次启动 EULA 弹窗 + 同意按钮 + Isar 持久化已同意状态

## 5. 红线 / 风险

- **AI 出图声明缺失** → Steam 商品页有 AI-Generated tag 必填要求(2024+ 政策)→ G1 必备
- **字体侵权风险**:思源黑体 Apache 2.0 商用免费但**思源宋体 Adobe 联合 SIL OFL 1.1 略不同**,LICENSE 文件必须独立归位
- **Demo 期素材授权过期**:Epidemic Sound 月订断订后已发布 Demo 内素材失去授权 → 1.0 release 前必转永久授权
- **隐私政策 region 适配**:Q1 海外 only → 美国 CCPA / 欧盟 GDPR 必备 · 国内 PIPL 暂砍
- **EULA 不可退款条款 vs Steam 退款政策冲突**:Steam 强制 14 天 / 2h 退款,EULA 不可凌驾 → EULA 写「除 Steam 退款政策外不可退款」
- **AI 出图玩家二创**:玩家用游戏截图 fan art 是否需授权 → G1 衍生作品段需明确「玩家个人非商业 fan art 允许」

## 6. 验收

- [ ] G1 `docs/legal/ai_disclosure.md` 起草完成 + Steam 商品页 AI-Generated tag 勾
- [ ] G2 字体审计完成 + 思源 LICENSE 归位 `assets/fonts/LICENSES/` + pubspec.yaml fonts 段对齐
- [ ] G3 audio 来源清单完成 + 49 条 LICENSE 归位 `assets/audio/LICENSES/`
- [ ] G4 隐私政策中/英双语 + 游戏内入口 + 首次启动展示
- [ ] G5 EULA 中/英双语 + 游戏内入口 + 首次启动同意弹窗
- [ ] ~~ICP 备案~~ Q1 砍,1.x 评估

## 7. 依赖 / 阻塞关系

- G1 AI 出图声明 必须在 F2 Steam 商品页提交前完成(商品页填 AI 标签需声明依据)
- G3 BGM/SFX 来源清单 依赖 E5-E7 素材落定后填
- G4-G5 隐私+EULA 依赖 F1 Steam 账号 + F5 Sentry 项目创建(才能写清 crash report 收集范围)
- D / E / F 三段并行,G 段为 doc 类不阻塞工程

## 8. closeout / 验收 doc

- 每 Batch:`docs/handoff/m15_g_<batch>_closeout_<date>.md` ≤80 行
- 最终段:`docs/handoff/m15_g_full_closeout_<date>.md` + CHECKLIST §G 4/5 全勾(ICP 砍)+ PROGRESS 顶段对齐
