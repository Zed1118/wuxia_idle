# M4 PoC #46 · Stage 0 风格 Ref 探索 Spec(2026-05-20)

> M4(美术里程碑)PoC 流程 Stage 0:用 MJ v7 出 12-20 张候选 ref,挑 1-2 张当后续生产用 `--sref`。

## §0 决策溯源

2026-05-20 主对话 opus xhigh 4 维度技术选型讨论后 4 项拍板:

1. **风格基调**:**暗黑厚涂水墨**(GDD §1 水墨克制 + 用户 ChatGPT 11 张样图审美北极星 + 风格家族 卧龙 × 黑神话 × 一念逍遥 × Sekiro)
2. **AI 工具链**:**MJ v7 Standard $30 月付**(主出图)+ **ChatGPT Plus**(用户已订,副工具辅助 prompt 翻译 / 风格分析,**不出生产图**)
3. **装备 icon 风格**:**混合双轨**(列表 icon 清晰白底 + 详情大图厚涂氛围,2 套 prompt 模板)
4. **节奏**:**Stage 0**(ref 探索)→ **Stage 1**(PoC 5 装备)→ **Stage 2**(量产 35 装备 + 3 角色 + 5 场景 + UI)

**重大改向**:推翻"用 ChatGPT 11 张当 MJ `--sref`",改"MJ 自己跑一组 ref 候选"(**工具同源原则**:风格 ref 工具 = 生产工具,一致性最强)。ChatGPT 11 张降级为**审美北极星**,归档 `docs/art_ref/chatgpt_baseline/`(详该目录 README)。

## §1 ChatGPT Baseline 11 张归档清单

详 `docs/art_ref/chatgpt_baseline/README.md`。

| 类 | 张数 | 路径 | 关键候选 |
|---|---|---|---|
| characters | 5 | `chatgpt_baseline/characters/` | 斗笠剑客 / 女剑客 / 流星锤客 / 武僧 / 老宗师 |
| ui | 1 | `chatgpt_baseline/ui/` | 江湖行主菜单结构 |
| environments | 5 | `chatgpt_baseline/environments/` | 山村客栈 / 水乡夜雨 / 山门寺庙 / **雪中亭阁 ⭐** / 山岩栈道 |

⭐ 用户上轮主对话选定 `environments/04_xuezhong_tingge.png` 为**首选风格 ref baseline**,Stage 0 MJ 候选评估时以此为主参照。

## §2 风格关键词锁定

| 维度 | 锚点 |
|---|---|
| 色调 | 灰墨黑(主)+ 宣纸米黄(底)+ 暗红/铜橙(腰带/灯笼/衣边点缀 5-10%) |
| 饱和度 | 极低,接近水墨黑白 |
| 画法 | 厚涂(主)+ 国画意境混合,非线描非赛璐璐 |
| 氛围 | 重雾 / 重雨 / 重水反射 / 湿冷山林 |
| 构图 | 留白多 / 远景虚化 / 前景重笔 / 单角色站姿居中 / 环境横屏宽幅 |
| 质感 | 衣摆破布飘逸 / 撕裂感 / 武器抽象不装饰过度 |
| 风格家族 | 卧龙苍天陨落 × 黑神话悟空 × 一念逍遥早期立绘 × Sekiro 中式宣发图 |

## §3 3 套 MJ 候选 Prompt(Stage 0 跑这 3 套)

> 每套跑 4-6 次 `/imagine`,每次 MJ 出 4 张 grid,合计 16-24 张候选。**推荐用 web app**(https://www.midjourney.com,2026 年已支持完整功能 + 文件管理友好);Discord 备选。

### 套 A · 极致水墨克制(偏《长安三万里》《一念逍遥》)

```
/imagine prompt: A Chinese wuxia swordsman, ink wash painting style, thick brush strokes, muted grey-black palette with rice paper beige base, misty rainy atmosphere, generous negative space composition, subtle warm lantern accent, weathered cloth robes with frayed edges, standing in foggy bamboo forest, solitary contemplative pose --ar 2:3 --stylize 250 --v 7
```

- **预期**:克制水墨感强,色彩极简,适合长期作为风格 ref
- **风险**:可能过于"国画"失去厚涂沉重感

### 套 B · 暗黑沉郁(偏 Sekiro / 卧龙 / 黑神话)

```
/imagine prompt: A wandering ronin warrior in ancient China, dark ink thick paint, rice paper underlay, rain-drenched bamboo grove at dusk, warm orange sash accent, cold wet atmosphere, tattered long robe, silent menacing presence, cinematic lighting with deep shadows --ar 2:3 --stylize 400 --v 7
```

- **预期**:暗黑氛围最重,沧桑感强,接近 ChatGPT baseline 那 11 张味道
- **风险**:饱和度可能略偏暖,需调 `--stylize` 验证

### 套 C · 山水意境(国画山水 + 人物结合)

```
/imagine prompt: A wuxia martial artist in a misty mountain landscape, Chinese ink and wash painting fused with thick oil paint, distant mountains in soft grey wash, pine trees in foreground, pale ink tonality, ultimate color restraint, figure as small focal point in vast composition, jianghu poetic mood --ar 2:3 --stylize 200 --v 7
```

- **预期**:意境优先,人物在山水中,氛围最雅
- **风险**:人物太小可能不适合做角色立绘 ref,但适合环境/地图 ref

### Prompt 调优指引(给 ChatGPT 当副工具用)

跑出后觉得不对劲,把图 + 问题描述贴 ChatGPT,让它建议改 prompt:
- 太彩色 → 加 `monochrome ink wash` / 降 `--stylize`
- 太干净不沧桑 → 加 `weathered, tattered, dust streaks`
- 缺暖色点缀 → 加 `single warm amber lantern accent`
- 人物太小 → 改 `medium close-up shot, character centered`

## §4 用户 MJ 操作手册(Standard 起步)

### 4.1 订阅

1. 浏览器开 https://www.midjourney.com
2. 右上角登录(Google / Discord 任选,建议 Google 简单)
3. Subscribe → **Standard Plan $30/月 月付**(已确认拍板)
4. 完成后右上角应显示 Standard 标识

### 4.2 出图流程(推荐 Web App)

1. 登录 https://www.midjourney.com/imagine(直接进 imagine 页)
2. 顶部输入框贴 prompt(套 A / B / C 的整段)
3. 按 Enter 提交,等 1-2 分钟出 4 张 grid
4. 喜欢的图 → 点 **Upscale (U1-U4)** 出独立大图(默认 2048×3072)
5. 接近但想调微 → 点 **Vary (V1-V4)** 出变体
6. 鼠标 hover 图 → 右上角下载图标 → 存到本地
7. 自建文件夹 `~/Desktop/MJ_Stage0_Ref/` 存,命名建议:`A_001.png` `A_002.png` `B_001.png` `C_001.png` ...

### 4.3 Discord 备选(如 web app 体验差)

1. 加入 MJ 官方 Discord:https://discord.gg/midjourney
2. 任意 `#general-*` 频道发 `/imagine prompt: <整段 prompt>`
3. 同样 Upscale / Vary,Discord 内右键图 Save Image As

### 4.4 用量监控

输入 `/info` 命令查 Fast time 剩余。**Standard 15h Fast + 无限 Relax**,Stage 0 全程 ≤ 1h Fast 绰绰有余。

## §5 候选 Ref 评估清单

### 5.1 主观维度(1-10 评分,你+我联合)

- [ ] 与 ChatGPT baseline 风格一致度(参照 `04_xuezhong_tingge.png` 主标杆)
- [ ] 武侠氛围(沉浸感)
- [ ] 厚涂水墨感(笔触质感)
- [ ] 暖色点缀比例(过多 / 适中 / 缺失)
- [ ] 留白构图(国画意境)

### 5.2 客观维度(全 pass)

- [ ] 无明显 AI 瑕疵(多余手指 / 鬼画文字 / 构件错乱 / 透视失真)
- [ ] 单一主体(适合做 `--sref` 复用,人物背景元素简洁)
- [ ] 高分辨率清晰(MJ Upscale 后 2048×3072 起)
- [ ] 风格家族符合(暗黑 / 水墨 / 武侠 三标签全中)

### 5.3 通过标准

- 至少 **1 张** 满足"主观全维度 ≥ 7 分" + "客观全 pass" → 锁定为 Stage 1+ `--sref` baseline
- **2 张** 都达标 → 一张作主 ref(人物用),一张作备 ref(环境用)
- 全部不达标 → 调 prompt 重跑(我帮你优化),或转 fal.ai Flux LoRA 训练路径(详 §6.2)

## §6 Stage 0 → Stage 1 路径

### 6.1 验收通过(预期路径)

1. 锁定 1-2 张 ref → 用户上传到 Discord 自己私信 / Imgur 拿到稳定 URL(MJ `--sref` 需要 URL)
2. 我起草 `docs/handoff/art_poc_stage1_5_equipment_2026-05-20.md`,含:
   - 5 件装备清单(寻常货 / 好家伙 / 利器 / 宝物 / 神物 跳采样)
   - 每件 2 张 prompt(列表 icon 白底 + 详情大图厚涂带 `--sref`,**混合双轨**)
   - 验收标准(7 阶视觉梯度 / icon 128×128 可读 / 风格一致度)
3. 用户照 spec 跑 10 张,提交验收
4. 通过 → Stage 2 量产(35 装备 + 3 角色 + 5 场景 + UI = ~150 张)
5. 不通过 → 调 prompt / 换 ref / 评估转 fal.ai

### 6.2 验收失败(降级路径)

如果 Stage 0 反复跑都不达标(主要风险:MJ 抓不到 ChatGPT 那种厚涂湿润感):

| 方案 | 路径 | 成本 |
|---|---|---|
| **X 接受 MJ 风格** | 放弃 ChatGPT baseline 复现目标,重新校准审美,接受 MJ 自然出图风格 | $0 |
| **Y 转 fal.ai Flux LoRA** | 用 ChatGPT 11 张当 LoRA 训练数据集,codify 风格,后续 fal.ai 推理 | $5 训练 + $0.05/张推理 |

决策由我+用户根据 Stage 0 结果对比 baseline 后联合拍板。

## §7 副本工具角色(ChatGPT)

| 阶段 | ChatGPT 用法 |
|---|---|
| Stage 0 跑图前 | 让 ChatGPT 帮你优化 prompt:"我想让 MJ 出一张更湿润感的水墨剑客,prompt 怎么改" |
| Stage 0 跑图后 | 把 MJ 出图 + ChatGPT baseline 一起丢给 ChatGPT,让它做风格对比分析,辅助主观评分 |
| Stage 1+ | 同上,每次出图后用 ChatGPT 反思 prompt 调优 |
| **❌ 不要做** | **不要让 ChatGPT 出最终生产素材**(漂移问题就是为什么我们不选它当主出图工具),它的角色是**翻译 / 分析 / 讨论** |

### 后期处理免费补充(Stage 1+ 用)

| 工具 | 用途 | 成本 |
|---|---|---|
| Photopea(https://www.photopea.com)| web 版 Photoshop,去背 / 拼合 / 调色 / 裁切 | 完全免费 |
| remove.bg | 一键去背,装备 icon 必备 | 50 张/月免费,够 Stage 1 PoC |

## §8 时间规划

| 时间 | 动作 | 负责 |
|---|---|---|
| 2026-05-20 当天 | Spec 落地 + assets 归档 + 用户订阅 MJ | 我 ✅ + 用户 |
| 2026-05-20 / 21 | 用户入 MJ + 跑 Stage 0 12-20 张候选 | 用户 |
| Stage 0 跑完后 | 我+用户验收 + 决策 Stage 1 路径 | 我 + 用户 |
| Stage 1 PoC | 5 装备 × 2 = 10 张 | 用户跑 + 我评 |
| Stage 2 量产 | 35 装备 + 3 角色 + 5 场景 + UI ≈ 150 张 | 用户跑 + 我评 |

**预计 Stage 0+1 完工**:2026-05-22~05-25 之间(取决于用户出图速度)。

## §9 硬约束

- **GDD §1 水墨克制**(色调/饱和度上限不破)
- **不进 Flutter build**(`docs/art_ref/` 不在 `pubspec.yaml flutter: assets:`,30MB 仅 git 归档)
- **黑名单词**(不要在 prompt 写):`legendary` / `epic` / `fantasy game art` / `RPG icon` / `anime` / `Genshin Impact style` / `Honkai` / `mobile game art` — MJ 见到会拉成网游卡通风,直接违反 GDD §1
- **`--sref` 风险**:用环境图当 sref 可能污染装备图(剑长出小松树/雪花),Stage 1 验收时注意检查
- **Cost cap**:Stage 0+1 在 MJ Standard $30 月费内,Stage 2 量产前重新评估订阅(可能升 Pro $60 for Stealth mode + 30h Fast,1.0 阶段长期可考虑)
- **Riverpod / Isar / Flutter 代码层不动**(美术 PoC 与代码无关,本 spec 完全在 docs 层)

## §10 验证清单(本 spec 落地)

- [x] `docs/art_ref/chatgpt_baseline/` 归档 11 张 + README.md(本 commit)
- [x] 本 spec doc 起草完(本 commit)
- [x] PROGRESS.md 加 M4 #46 顶段(本 commit)
- [ ] [等用户] MJ Standard $30 月付订阅完成
- [ ] [等用户] Stage 0 跑 12-20 张候选
- [ ] [等用户提交] 验收 + 决策 Stage 1 路径

## §11 下波候选(Stage 0 完工后)

| # | 任务 | 触发 |
|---|---|---|
| 1 | Stage 1 PoC 5 装备 spec 起草 + 用户跑图 | Stage 0 验收通过 |
| 2 | 调 prompt 重跑 Stage 0 | Stage 0 候选全不达标但有方向 |
| 3 | 转 fal.ai Flux + LoRA 训练 spec | Stage 0 反复不达标且想锁 ChatGPT 风格 |
| 4 | 同步起手 候选 3 心法相生 §4.5 重设计(sonnet 1-2h)| Stage 0 等用户跑图期间 Mac 端空档,可顺手做 |

候选 4 备注:Stage 0 用户跑图期间我可能空档 30min-1h,可以同步起手非阻塞的代码任务。等 Stage 0 启动后再拍板。
