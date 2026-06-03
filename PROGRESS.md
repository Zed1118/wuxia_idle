# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> ✅ **2026-06-03 overnight 自主批(P0-2 闭环 + P0-3 ① + P0-4b spec + 敌人 prompt 批2-4 · `c7fb79c`)**:① **P0-2 战斗单位可见化全 9 task 闭环 merge**(玩家立绘接线 / 单位放大 110〔spec 标 150 实测 720p 溢出 120px 改 110+战场 padding16〕+ 死亡 grayscale / 弹道笔触 CustomPainter + 受击闪 + 折叠日志抽屉 + 战场占满宽 + 胜负 vignette 不压暗 · 弹道/受击走 actionLog 边沿**不写 BattleState** 红线 · +13 测 · 全量 **1692 测/0 analyze**)② **P0-3 角色面板 ① 装备外观可视化 merge**(装备槽加 iconPath 图标 + tier 色 _EquipGlyph 占位 + 144px _EquipmentSlotShell 不动共享 _SlotShell · +2 测)③ **P0-4b 仓库格子化 spec** 就绪待实装(列表→网格+部位分组+可装备状态)④ **敌人 MJ prompt 批2-6 = 69 张** backlog 清零(erLiu/yiLiu/jueDing/zongShi/wuSheng 全阶 · 梯度词+唯一身份词避撞车 · 覆盖 known_missing 全部未认领项)⑤ 只读 subagent 对抗式 review:1 BLOCKER「setState during build」**经验证=误报**(Riverpod ref.listen 不在 build 期 + 原 _spawnPopup 已同回调 setState + 1692 测绿),重要/nit 防御性非真 bug。**P0-3 ②③(主观视觉+心魔数据管线)/ P0-4b 实装留用户在场判视觉**。详 `docs/handoff/overnight_2026-06-03_handoff.md` + spec `2026-06-03-p0-{3,4b}-*` + 派单 `codex_visual_{battle_p0_2,character_panel_p0_3}_2026-06-03.md`。**续(装备 detail 图归位 45 件 · 新 mac 迁移后 · `b2e732a`)**:6月「带场景氛围」重出那批源随 Downloads 丢失 + montage 仅 940px 不可用 → 改用 5月28 精修源 45 件(对象清晰 + 水墨场景氛围 + 品阶感,正中需求)按 defId **1:1 双射** + weapon/armor/accessory 三张带标签拼图**肉眼复核零错配**归位 `assets/equipment/<defId>_detail.png`(1024² · 296-500KB · pngquant+oxipng)· 清 allowlist 45 条(82→37 · 剩 37 全敌人图〔35 重出 + 2 补缺〕待冷却)· asset_audit 4 guard 全绿(guard2 反证已补齐)· equipmentDef.detailPath 装备详情大图 **80 件齐**(35 旧 + 45 新)。

> ✅ **2026-06-02 续(P0 工程地基 #2+#3 收尾 · opus high · `baa6070`)**:核心玩法视觉 pass P0 工程地基三项全闭环(门禁 + 本批两项)。**#2 PortraitFrame null 空框 → 首字水墨占位**(加可选 `placeholderText`,null 立绘居中首字 fontSize=size*0.42 textPrimary 沿 battle CharacterAvatar 首字降级体例 + 修注释「不占位」错误声称,4 真实角色调用方传 name·confirm_dialog 被 portraitPath!=null 守跳过)。**#3 装备详情大图 cover→contain**(+padding 8 留白,细长兵器完整展示不裁切 §5.4)。TDD red-green + 只读 review 全 PASS · +3 测(portrait 占位 2/装备 contain 1)· 全量 **1674→1677 测 / 1 skip / 0 analyze** · §20.4 P0 地基段三项全勾。下波 = Phase B 战斗视觉 brainstorm(头号·xhigh·依赖 Phase D 敌人图)或 Phase D enemy MJ prompts(美术线启动)。

> 🔴 **2026-06-02 续(外部 UI 审查 reconcile · 核心玩法视觉 pass 升 1.0 阻塞)**:外部只读 UI 审查 + Phase 0 亲验坐实 —— 出版美术 pass「容易项」(背景/overlay/章节封面/剧情背景)做完即勾绿 §12 门,但「最难项」被推迟:§5.2 战斗单位可见性=玩家仍 80px 首字头像(`battle_state.dart:286` iconPath null) / §5.4 角色面板半成(ProfileHeaderCard 后仍数据块)+仓库未动 / §6.1 敌人图 22/129。**§12 上线门「11/12」系虚高**(按单切片 Codex PASS 累计非整体验收),诚实重评 **~4 真达成**(主菜单/心法/掉落仪式/release 隔离)+**3 部分**(Boss区别/分辨率空洞/旁人可判)+**5 未达成**(战斗截图/角色页/装备详情/音频/截图一致)。资产亲验:敌人 107/129 缺 + 装备 detail 44/160 缺(独立重扫与审查 107+45 吻合)。`skillUsage:6` 受 kDebugMode 守 = 非上线问题。**用户拍两决议**:核心玩法视觉 pass(战斗+面板+仓库)设 **1.0 阻塞** + 敌人图**全补 107 张**。执行 tracker 落 `docs/PUBLISHING_ART_PASS_1_0.md` §20(v1.2),后续按文件推进。**1.0 readiness 从「~99%」回调至「核心玩法视觉 pass 待做」**。本批 0 代码改动(仅 doc reconcile)。

> ✅ **2026-06-02 续(D 性能稳定性验证 · xhigh)**:CHECKLIST D 段「8h 无 crash / 内存 leak / Isar IO 无 ANR」验证。**方法 = Phase 0 侦察 + 亲验**(侦察 3 处不准必亲验:home_feed 显示 feed 实为 `limit20`+`occurredAt` index 非「无 limit」· 挂机 = 闭关 `now-startedAt` 时间差一次性结算无后台 tick · 零同步 IO)→ **逻辑层架构稳健,几无可修真问题**:leak(全资源 dispose,唯 1 个 Timer.periodic 在 battle_screen 且 cancel)/ ANR(零 `getSync/putSync` 同步 IO,全异步)/ 极端时长(`actualHours=min(elapsed,planned,capHours=72)` 截断 + 产出 `clamp(0,999999)` 双防线)/ 连续战斗(balance_simulator 1000 场已覆盖)全已覆盖或证伪。**新增 `test/tools/stress_test.dart`**(A GameEvent 累积 + B 极端时长双防线 · 沿 idle_economy/seclusion_test 体例 · +2 测 · analyze 0):**A 压测证伪 GameEvent 无界隐患** —— 显示 feed(limit20+index)10000 条下 815µs 不退化(O(20) range 扫)· markAllFeedRead 10K 未读仅 63ms(玩家主动按钮可接受)· 写 10000 条 53ms → **cap 不必加,留 1.1(YAGNI · 数据驱动)**;**B 固化 capHours+clamp 双防线**(elapsed=72h 与 100000h 产出全等证截断)。**留实测**(test 测不了):FPS≥60 + 真机渲染崩溃(Pen/beta)+ 30-35 关全路径数值终调(待 beta 数据)。CHECKLIST D 段「Isar IO 无 ANR」勾 ✅,8h/内存逻辑层已验、真机长跑留实测。 · **Mac profile 初步实跑**(本会话 `flutter run -d macos --profile`):build 160.9MB ✅ / 启动 0 exception / idle 内存启动 213MB→**251MB 后 70s 完全持平无 leak** / 运行日志无 jank·overflow·assert / 流畅度肉眼「还可以」→ Mac 端 build·启动·idle 稳定层健康;**FPS 精测 + Windows 目标平台 + 8h 真长跑仍留实测**(Pen art 传输待解决 / beta)。

> ✅ **2026-06-02 续(窗口 min size Pen 实机验收闭环)**:派 Pen Codex 验「窗口最小尺寸约束」**3/3 PASS** — 门1 真实鼠标(SendInput)拖窗锁 1280×720 缩不下去 / 门2 锁定点截图无 RenderFlex overflow 主菜单完整无裁切 / 门3 默认窗口正常 · 日志 0 exception/assertion。**验收有效性已证**:Pen git pull 卡住、基线停 `f0d2e5a` + 手动 apply `3db46b2` patch,但 blob 校验〔`f0d2e5a:win32_window.cpp` == `3db46b2` 父版本,`72366d6` == `3db46b2`〕→ Pen 编出 native runner 逐字节 == `72366d6` 发布版,caveat 不影响结论。**1.0 闭环唯一「待验证」项消除**,剩 ~1% 全卡外部/M15-16。截图 01_initial/02_min_locked 待归档。

> 🔧 **2026-06-02 续(B1 release 收尾 audit + doc 同步 + 窗口 min size)**(`9395af3`→`980861d` 3 commit):B1 audit 头号发现 **doc drift 非真缺口**(出版美术整 Phase 闭环但 CHECKLIST H′ 段全 [ ]、测数停 1602)→ **doc 同步批**(CHECKLIST/ROADMAP v1.13 + CLAUDE v1.17:测数→**1667** · readiness ~98%→**~99%** · §12 上线门 **11/12** · H′ 段按真实勾)。**窗口 min size 工程项**(`win32_window.cpp` 加 `WM_GETMINMAXINFO` 锁 1280×720 DPI 缩放 · §12.9 上线门 · **Pen 实机验收 3/3 PASS**〔2026-06-02 · blob 校验 native runner 逐字节 == 72366d6 发布版〕)。Mac 端 ship 前硬工程清零,剩 ~1% 全卡外部/M15-16(D 性能/closed beta/E 音频/F Steam/G 法律)。0 Dart 改动 · analyze 0/1667 测。

> 📊 **2026-05-31 出版美术阶段启动(1.0 Presentation Pass · `PUBLISHING_ART_PASS_1_0.md`)· Phase A 主菜单视觉切片收口(全屏 bg+题字+双列木牌+锁印 · Codex 验 6PASS/2WARN→双列+木牌迭代闭环 · Mac 本地视觉自验)· B 段心法面板出版美术收口(B1 宣纸底 + B3/B4/B5 秘籍 tile/主修 hero/9 层段位阶梯 + B2 7 阶 cover 卷轴 banner〔素纸→金框装帧梯度〕+ 主菜单门面 bg 换水墨山门 + debug 菜单返回修复 · **Codex 3 轮验收终 PASS**:深色空底 StackFit.expand 治本〔Stack shrink-wrap 露 Scaffold 冷底→撑满〕/seal 印章收敛/cover 完整呈现 · `2426afa`)· **续视觉验收基建**(`0b70bcc`/`3bbf63c` · VISUAL_ROUTE dart-define 直达验收屏 + 武圣满学 7 阶 seed〔关 cover 多 tier 缺口〕+ visual_capture.sh〔含 window_id.py Quartz 取窗,缺 PyObjC/屏录则全屏兜底〕· READY 信号实跑通+1620 测绿+0 analyze · **7 阶 cover Codex 视觉验收 3/3 PASS**(7张加载/素纸→金框梯度逐阶递进/横幅完整不裁切·Mac 本地 app·我多模态亲验传说神功金框 cover 完整呈现·残留 window id 不稳走全屏兜底靠手动裁窗,非阻塞·closeout `codex_visual_tier_cover_2026-05-31.md`+10 截图)·spec/plan 见 docs/superpowers/*2026-05-31-visual-capture*)· **续 sect/recruit 9 NPC 立绘落地**(`66ff299`·出图→选→归位 assets/characters·6 sect_candidate+3 recruit_candidate·山隐子/云寒青重跑去络腮胡撞型·9 portraitPath 缺图全补齐·W4 主角色 sref 同师徒画风)· **techniques cover+立绘 oxipng+pngquant 压缩**(`d8fa182`/`85d2a71` cover 16.4M→4.3M·立绘 20.8M→4.3M·pngquant 4M 档有损·cover 金框已亲验近无损·游戏内 indexed PNG 加载+视觉待 Codex 复验)· **sect 立绘 portrait wiring 闭环**(merge main · 关 Codex B FAIL「生产 UI 未接 portraitPath」· brainstorming→spec→plan→subagent-driven 8 task TDD · 方案A:`Character.portraitPath` 单一真相源〔Isar 0.14→0.15〕+ `PortraitFrame` 共享 widget 3 站点〔成员行 48/dialog 96/debug 列表 40〕+ 祖师弟子 ← MasterDef·NPC ← SectCandidateDef 创建写入 + VISUAL_ROUTE `sect_screen_npc`+`seedSectWithFullNpc`〔祖师+6 NPC 满立绘〕· **Codex 视觉验收全绿**(A 段祖师+6 NPC 成员行立绘 + B 段 dialog 96/debug 列表 40 均 PASS · A 段 R1 FAIL〔seed 未先 _clearAll→真机 legacy 祖师 0.14 存档短路致立绘空框〕→ R2 加 _clearAll 重建带立绘祖师+回归测,重判 PASS · `62ab9d2`)〔recruitment_dialog 第 4 立绘位已迁 PortraitFrame ✅ `8330ed1`〕· 1620→1627 测/0 analyze · **续角色页档案化(出版美术 Phase A 收尾)**:_TopBar→`_ProfileHeaderCard`(立绘 PortraitFrame 110 + 姓名题字 + 境界·层 + 流派名 + 4 属性聚成武侠档案卡 · 删 _AttributesSection 折入)· §5.4「档案不像表格」· 零新美术(复用 portraitPath)· spec/plan/TDD 全流程 · 1627→1628 测/0 analyze · `2a4dba7` · 视觉验收 PASS ✅(Codex 3 截图 + 5 门全 PASS + Mac 多模态亲验祖师/弟子档案卡观感到位:立绘随角色变/流派名+色/4 属性聚卡 · `codex_visual_char_panel_profile_2026-06-01.md`)· 出版美术 Phase A 角色页档案化全闭环 · **续整夜挂机出版美术批**(章节页封面接线〔章节卡封面条+章首插图+关卡列表头 3 处消费 + chapterCoverPath helper + chapter_list VISUAL_ROUTE〕+ 神物/宝物详情差异化〔全周粗边框+题字加大 §5.4〕+ 章节封面 Ch1-4 MJ 水墨入库压缩〔8.1M→1.7M〕 · Phase C 抽组件审计后否决〔Border 用法异构无真重复,避 over-engineer〕 · 1628→1632 测/0 analyze · `9fef948` · Ch5/Ch6 16:9 重跑归位 → 6 章封面齐入库压缩 `06df1a1`)→ **Ch5 封面重做**(原戈壁误图,纠正为 Ch5「征东」中原东归主题→黄河义渡栈桥,Codex 复验 6门全 PASS · `da50395`) · **战斗屏出版美术 B1**(scrim 暗遮罩 0.4 + 47 stage/30 floor 背景 yaml 按 biome 接线 + 胜负仪式全屏 overlay〔金「胜」/绛红「败」+ 印章〕· brainstorm→spec→plan→7 task subagent-driven TDD + 2 漏检 fix〔T16 scoped 漏测 / 验收路由 AI 崩溃〕· 1642 测/0 analyze · Codex 6门全 PASS〔scrim 0.4 合适〕· `599c25a`)· **战斗屏出版美术 B2 全闭环**(大招题字 overlay〔ultimate/jointSkill 非阻塞自动淡出·玩家暖金/敌方绛红·覆盖语义·AnimationController 自管〕 + Boss 头像金边〔EnemyDef.isBoss→14 boss stage 标注·CharacterAvatar 6px bossFrame·inner_demon 7 空队豁免〕· 纯 Flutter **0 出图** · brainstorm→spec→plan 10 task subagent-driven TDD→final review Ready to merge→opacity 魔数 polish · 1642→1661 测/0 analyze · 真机自验 battle_boss_frame READY 零异常 · 静态题字+Boss 场景双验收路由 · `d8ef483` · Codex 视觉验收 PASS(Mac 本地 Codex · 8 门 7P1W · 题字暖金/敌方绛红区分清晰 + Boss 金边辨识度够〔Mac 多模态亲验同意,不必加 8px〕 · 唯一 WARN=battle_scene READY 后自动结算过快未截到严格战斗进行中,门 7 本体已被 02_boss_frame 截图〔背景+scrim+战斗 UI 同屏〕充分覆盖,非视觉缺陷 · closeout codex_visual_battle_b2_2026-06-01.md + 3 截图 2560×1496〔窗口 1280×748〕 · 验收基建可选改进:视觉路由 READY 前冻结/暂停自动结算,留 backlog 非阻塞) · closeout `p_b2_battle_polish_closeout_2026-06-01.md`)**

**2026-06-01 续(剧情阅读屏出版美术基建闭环)**(merge main `e318c28` · 1661→1667 测 / 0 analyze · brainstorm→spec→plan→subagent-driven 6 task TDD):NarrativeReaderScreen 加主线专属水墨背景 —— `stageNarrativePath` helper + `NarrativeSceneBackground`(仿 B1 scrim,`narrativeSceneScrim` 50%)+ 正文墨底浮层(alpha 0.55)+ `backgroundImagePath` 可选参数(沿 topBanner 体例)· `stage_entry_flow` 三处 wire(opening/victory/defeat)· 其余调用方(爬塔/飞升/招降/心魔)走纯色底兜底(errorBuilder 缺图不破)· 验收路由 `narrative_scene` · **30 张 MJ prompt 已交付**(`docs/handoff/mj_prompts_narrative_scene_2026-06-01.md` · 主线 30 关 per-stage · 16:9 横构图留暗区给正文)待用户出图归位 `assets/scenes/narrative_stage_XX_XX.png` → Codex 验 `narrative_scene` 路由 · code review 1 Important fix(Scaffold 无条件 solid 底对齐 battle_screen 防 Windows 首帧闪)· spec/plan docs/superpowers/*2026-06-01-narrative-reader*。**B2 Codex 视觉验收 PASS 已收(8 门 7P1W)** · **2026-06-02 narrative_scene 出版美术验收销账**(`95f7bdc`/`e7031e2` · 30 张剧情背景 pngquant 压缩入库〔1.7MB→448KB/张 · ~50MB→13MB〕+ visual_route_host `narrative_scene` 路由支持 `VISUAL_STAGE` env 抽样任意主线关卡〔真 NarrativeLoader.load〕+ Codex 8 门 7P1W PASS〔6 张抽样无肉眼 banding/质损 · 题材/scrim/正文浮层均达标 · WARN 仅退出时 HardwareKeyboard assertion 非视觉缺陷〕· 1667 测/0 analyze · closeout `codex_visual_narrative_scene_2026-06-02.md`+6 截图)· 出版美术 pass 剧情屏全闭环〔基建+30 图+压缩+验收〕) · **2026-06-02 战斗场景长尾 9 biome 补专属图**(`36a926e`/`82260b5` · 审计:sceneBackgroundPath 接线 100% ready,真缺口=9 长尾 biome〔inn/escortRoad/teaHouse/smithy/alley/temple/desert/bambooForest/cliffWaterfall〕借用近邻兜底 · MJ 出图选片〔各 4 变体多模态挑中部留空+水墨克制+识别度〕+ pngquant/oxipng 压缩归位〔1456×816 · 264-856KB〕+ 11 stage sceneBackgroundPath 改专属〔desert/temple 各 1 图通用 2 stage〕 + wiring test `_map` 同步新映射 + 白名单改 `_map.values` 派生〔单一真相源不写死 7〕 · 1667 测/0 analyze 全绿 · doc `mj_prompts_battle_scene_longtail_2026-06-02.md` · **Codex 验收 9/9 全过 → 战斗场景出版美术 pass 全销账**〔7 验收门 inn/escortRoad/teaHouse/smithy/alley/temple/desert 全 PASS · cliffWaterfall 唯 ⑦风格统一 WARN:笔触比高频图厚/更近景,非必须返工,可选换更留白远景变体 · alley 暗场叠 scrim 后 UI 仍清楚 · bamboo 偏灰青不跳绿 · desert/cliff 无明显 banding · VISUAL_SCENE 抽样路由一轮过 9 图 · closeout `codex_visual_battle_scene_2026-06-02.md`+9 截图〕 · **出版美术 pass 战斗屏(A+B1+B2)+剧情屏+战斗场景背景(7 高频+9 长尾 16 biome 全覆盖)全闭环**)

**2026-05-30 续(G2 step 3/5 上手引导 banner · §5.7 合规裁剪)**(`3790d13` · 1596→1600 测/0 analyze · TDD red-green):承接 H 段文案 polish 候选 1。H1 候选清单复验——G1 产品名/G3 空 feed 引导/A2 飞升 bug/§5.7 未解锁系统门控均已收口,M6 飞升路标 #4④ 已决 0 改动,G4 narrative footer 需 Pen 验 defer → Mac 端唯一干净纯文案项 = G2 step 1-5 上手 banner。**§5.7 设计取舍(用户拍「只补系统解锁锚点」)**:现 banner 基建刻意限 {6,7,8}(指向新解锁系统=§5.7 合规),audit 草拟的 step 1-5 含纯进度祝贺(「首战告捷」)与「不写教程弹窗」基调有张力 → 只补**真有新系统解锁**的两步:**step 3** 心法面板解锁 / **step 5** Ch1 通关(闭关 + 江湖/门派/排行榜同时点亮),跳过 step 1/2/4。实做:strings 2 段古风文案 + TutorialHintDef step3/step5 def(all 升序 [3,5,6,7,8])+ `markHintRead` guard 从写死 {6,7,8} 改**表驱动 byStep!=null**(单一真相源)+ 点击走默认 _onTap 标记已读(菜单同屏无需 onTapOverride)。+4 测(service 2 / main_menu banner 重写 2)+ 顺手删神物 seed test 未用 import 恢复 0 analyze。 **续 G4 剧情阅读区轻点推进**(`0ee3c37` · 1600→1602 测):NarrativeReaderScreen 原仅角落「继续」按钮、大段正文不可点、首读不直觉 → 正文区包 GestureDetector(opaque · onTap=_next)VN 式 tap-to-advance(drag 仍滚动不冲突)+ 首段一次性淡提示「轻点画面，继续往下读」(§5.7 提示一次)+ 继续/完成/跳过按钮保留双轨。+2 测。**Pen 验收 5/5 PASS ✅**(audit 4B 落地·g4_01/02 Mac 多模态亲验:首段淡灰提示可读+轻点推进 1/2→2/2+「完成」进战斗·log 0 异常·手感「直觉」不抢眼无需调强;长正文滚动关卡无样本未验 g4_03,代码结构 tap/drag 不冲突·归档 docs/handoff/g4_narrative_tap_2026-05-30/)。

**2026-05-30 续(V3 神物金掉落验收收口)**(`59f8e58` · 1592→1596 测/0 analyze):承接 §9 待验「神物金色掉落」分支。新增 `seedVisualCheckShenwuDrop` debug seed + 菜单按钮:标 Ch1-5 全通+06_01/02/03 cleared(按 chapterIndex 与 chapterCompleted 自洽)解锁第六章留 stage_06_04 可挑,出阵 3 角色拉满配 wuSheng·dengFeng(满内力 + 神物装备天问剑/玄黄袍/舍利珠 + 传说神功满修 jiJing ×3.0)稳胜 06_04 必掉昆仑佩(dropChance 1.0)。**踩坑**:首版只 boost 祖师 1 人境界标签(内力/血量/攻击/心法字段不联动),Codex 实机打输 BLOCKED → 全员满配 + 写战斗诊断红线测(4 rng seed 全 leftWin 实测防回退)。**Codex Pen 验收 3/3 PASS**:昆仑佩神物金标签 ✅ + 弹窗仪式感 ✅ + 与宝物玄天斧紫色阶区分 ✅(截图 `docs/handoff/v3_shenwu_drop_2026-05-30/` @ Pen)。memory 新增 `feedback_debug_battle_seed_real_power`。

**2026-05-30 续(P5.2 敌人内力按境界对称化)**(`055696b` · 1581→1592 测/0 analyze · xhigh · TDD + brainstorming/writing-plans/executing-plans 全流程):承接 #4⑤ ceiling 真杠杆。敌人内力从扁平 1000 改**按境界查表对称化** — `enemy_defaults.internal_force` 删,新增 `internal_force_scale`;`_enemyToBattle` 查 `getRealm(tier,layer).internalForceMax × scale`(满开局,clamp≤15000 红线),不动 EnemyDef schema(已有 realmTier+layer,118 全覆盖)。抽纯函数 `resolveEnemyInternalForce` 便于单测。**症结**:内力战斗中不恢复(单调递减),改前武圣 Boss 也只 1000 内力 < 传说大招 cost 1600 永久放不出。**scale 调校**(Ch5/Ch6 跨阶红线压测驱动 + sim 复跑):scale=1.0 时 Boss 满内力 13000 狂放 8 次 8000 倍率大招,**满配玩家也被碾压**(Ch6 玩家 3/47 击穿红线上边界)。悬崖二元:scale≤0.245 Boss 放 1 次大招(玩家 35/15 过红线)/ ≥0.27 放 2 次(玩家 5/45 击穿)。**用户拍 0.20**:Boss 内力 2600 放 1 次招牌传说大招(P5.2 目标达成),满配玩家 70% 胜,两红线测过。sim:Ch5-6 难度整体小幅上升,**stage_05_05 on-level ceiling 76→20%**(章末跨阶墙意图 · **2026-05-31 sim 复核已销账**:全 30 关唯一 ceiling<50%,但败局 62% 在 30% 残血内惜败、仅 10% 真碾压、中位敌残 16%→刀锋高方差跨阶墙非 bug · data-confirmed)。+11 测(4 helper/4 scale 校验/3 集成 scale 无关)。spec/plan 见 `docs/superpowers/{specs,plans}/2026-05-30-p5_2-*`。

**2026-05-30 续(#4③ wf_audit 数值迁 yaml)**(`1283487` · 1581 测/0 analyze):Phase 0 复验发现 audit(b882907 base)半数已修——B1 hardcode/B3/B4 均 2026-05-29 P2-a/b/c 修、B9 已 H2 audit S3 注释。实做 4 项:**B2** `NumbersConfig.adventureAttributeLifetimeCap` 接 `EncounterService.attributeGainCap`(消 yaml `lifetime_cap_per_character` 零消费,3 gameplay 构造点 provider/seclusion/hook 注入)· **B5** numbers.yaml 新增 `encounter.fortune_sensitivity`,硬编码 20.0 外置· **B6** `mass_battle_def residualHpThresholdPct` 默认/fallback 0.05→0.30 对齐生产(生产 stage 走 yaml 0.30 不变,仅 fixture 默认调,+1 测同步)· **B7** bonus_per_event 段标注未消费(设计参考)。**跳** B8/A1 纯 cosmetic(无行为)+ B1 扁平值设计部分留 P5.2。**⑤ ceiling 取舍决议**(用户拍):1.0 **接受**满配/活跃玩家 ceiling 普遍 100% 胜(挂机品类 power fantasy + floor 梯度已健康使配装有意义),真杠杆留 P5.2 B1「敌人内力按境界对称化→Boss ult 能放」(纯数值上调会伤 floor + P5.2 重做)。数据 `test/tools/output/balance_summary_2026-05-29.md`。**④ A6 飞升路标定调决议**(用户拍):1.0 **极简/信任玩家**,0 改动 — 现状三层路标已足够(Ch6 epilogue 强叙事「化境门开」+ lineage 面板「飞升渡劫」section 显 missingReasons + 锁/解锁「步入飞升」按钮),写实武侠克制基调不喂路标,符 §5.7。**#4 决策第三层全闭合**(③ 实装 + ④⑤ 决议)。

**2026-05-30 续(文案 polish 三层 · H 段收口)**(`c97c682` · 102 yaml / 59 loader test 全过 / 0 analyze):H 段「文案最终 polish」完成。① **标点规范化** 98 文件 1233 处中文后半角标点→全角(逗号 1146/冒号 71/分号 9/问号 7 · 脚本精确跳过 yaml 注释行/flow mapping 结构逗号/`{source}` 占位符 0 误伤)。② **引号体例** 7 lore 文件半角 `'`→直角「」(天问剑/玄天斧 2 处对话内含强调嵌套作外『内』· 全库 0 残留)。③ **主线深修·元信息穿帮**(玩家可见 P0):chapter_06 + stage_06_02/04/05 正文 4 文件 7 处「Ch4/Ch5/三章」开发标记→叙事化指代(阳关那一夜/嵩山一决/一路行来)。**记账不修**:10 sect_event `choices.text` `(reputation -5)` 经代码核实——声望走独立 reputationDelta 字段、choices 字段未被 service 消费、dialog 按钮硬编码 → 玩家永不可见,属未消费 yaml 清理(架构层非 polish)留 #4。验证:102 yaml 0 损坏 + 59 loader test 全过(含霸气/逆天/史诗黑名单词)。

**2026-05-30 续(doc 重估+Codex triage+A组+V2b+B1 推迟)**(origin `26541cc` · 1581 测/0 analyze · 2 commit push):① **CHECKLIST v1.12+ROADMAP v1.11** release readiness ~97→**98%**(白屏证伪摘风险悬顶+H1 上手 audit 全闭环·`4a21a54`)。② **Codex 视觉验收 triage**(代码核实):§9 实 8/9 正确——**V2b 强化按钮非金=真 bug 已修**(`26541cc`·`enhance_dialog:299` ElevatedButton 补 `resultHighlight`)/ V1 凝练入口绛红=`schoolColor` 流派色 by-design 不改(同「设为主修」体例)/ V2d 胜利「返回菜单」=Codex 截错按钮(主线 `stage_victory_dialog:39` 确金,Codex 截到 `battle_screen:280` 战斗结算中性按钮)/ V3 神物金 BLOCKED(VC-P5+ seed 只 mark stage_06_05 cleared,章节列表 Ch6 仍锁→派单路径错·逻辑+单测已覆盖非阻塞)。③ **#4 A 组死代码清理**(`15966de`·删 `sectMemberCountProvider`(冗余)+`seedSectEventProvider`+notifier·battle_demo 经核=活 test fixture 保留·memory `feedback_git_grep_pathspec_glob_trap` glob 漏顶层)。④ **B1 敌人内力封顶 1000→路A 推迟 P5.2**:坐实 Ch6 终 Boss `chuanshuo_ult`(1600)/`shichuan_ult`(1100) 永久放不出(`battle_ai:105` 内力<cost),抬 2000 修但与刚缓和的 stage_05_05 耦合(on-level ceiling 76→20% 过难)→「敌人内力按境界对称化(方案A)+per-stage 重调」整体推 P5.2·worktree 弃·numbers 仍 1000。

**2026-05-30 白屏证伪收口 + H1 批3 视觉验收 5/5 PASS + #3 凝练态 seed**(main `a262358` · 1581 测):白屏非真 runtime bug(已被 B6 provider invalidate 加固)· 批3 5/5 PASS · 详 `codex_batch3_visual_2026-05-30.md` / `codex_whitescreen_repro_2026-05-30.md`。

**2026-05-30 overnight 自主批**(main `fe23ccb` · 1580 测):Pen H1 批1-3 视觉验收 + 6 批安全清理(硬编码→UiStrings / 文案补 / picker 关闭按钮 / dead-dup 清 / provider invalidate 加固)全 merge · 对抗 review 0 真问题 · 详 `overnight_2026-05-30_handoff.md`。

> **2026-05-30 H1 修复批全闭环已压缩归档**(`58c6f29`→`2dd597b` · 1555→1569 测 / 0 analyze):批1 主菜单 7 未解锁系统 §5.7 门控 + 门派名迁 UiStrings · 批2 `EquipmentService.equip/unequip` 装备穿戴入口(修核心循环断裂 · §5.3 守卫 + picker)· 批3 掉落 dialog 品阶仪式感 + 闭关装备名 bug + 凝练常驻态 + 过场调色 + tick→回合术语 · picker「他人装备中」移装标注。详各 commit/closeout。

> **2026-05-29 详条已压缩归档**(全程 commit/closeout/git log 完整可溯,1534→1555 测):① 方向调整(F/G Steam 搁置 · H 段升主聚焦 · balance_simulator PoC)· H1-Q1 主菜单产品名 P0 清零 · H2/H3/H1 三部曲 audit(`h{1,2,3}_*_audit_2026-05-29.md`)② 外部 review 修复批 P1-a 飞升 auto_swap §5.3 守卫 / P2-a 奇遇招式池空 fail-fast / P2-b 敌人属性抽 numbers / P2-c 战斗公式双路径收敛单一真相源 / P3 三文档血量公式 drift 对齐(commit `559455f`/`f719172`/`62b0b7e`/`2686815`/`1afc888`)③ 根因A 挂机循环重平衡 B1+B2+B3 实装(共鸣双管+闭关 EXP+insightPoints sink · `a359dc2`/`d7ee3f9`)+ B2 低 tier EXP 回 ×1.0 修正 + idle_economy 验证 · 红线值统一 numbers.yaml(`7a1d1e7`)· balance_simulator 升真 build + floor/ceiling bracket + on-level 修正 ④ D 段难度修复:stage_01_05 Ch1 Boss +2 阶硬墙(`781c85b`)+ stage_05_05 跨阶过苛缓和(`24cea80`)→ 过难关清零。

> 2026-05-28 三条(CHECKLIST v1.5+ROADMAP v1.8+R4 派单 / 装备 drop 全覆盖+P2.1 4 批 / P3.2.B+P1.2+P3.x+过夜清理 · 1508→1519 测)已归档,详末尾「2026-05-25/26/27/28 详条归档」段。

---

**2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(7 commit · 1505 测):详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`。

---

**2026-05-25/26/28 归档**:见末尾归档段。

## 已完成(近 W6 起,早期归档见末尾)

> W15 + W17-W18 + P5+ + P3.1+P3.2+心魔+Ch4-6 详条均已归档,详末尾归档段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 / 44 / 45 全销账~~(2026-05-17/18/19/20):详各 closeout
- ~~stage_05_05 on-level ceiling 20%~~ 跨阶墙 **2026-05-31 sim 复核销账**(non-bug · data-confirmed · `test/tools/output/balance_summary_2026-05-31.md`)

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(数值/规则层 · 改前 ask)
- Mac 端写 lib/、data/(顶层)、test/、文案(v1.8 起 DeepSeek 退役)

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 协作:Mac+Opus 单端代码+数值+文案;Codex 桌面 @ Pen 跑视觉验收

## 归档

### 已解决挂账(逆时序)

- **Phase 1-2 + W1-W13 全销账**(2026-05-10..14):#1/5/12-16/19-29/32 + #18 伪挂账

### Phase 1-4 早期详条已迁出

- Phase 1-3 + W4-W11:`phase{1,2,3}_summary.md` + tags `v0.1.0-phase1` / `v0.3.0-w11`
- W14-W15 + Phase 5 #2/#3 销账详条:git log + handoff/各 closeout

### W17-W18 详条迁出 2026-05-19/20

13 段销账(P1 #42-45 / Nightshift 9 task / P0 4 段 / 外部审查 6 项 / 路线图 launched / Codex 视觉)。详 `p1_4{2,3,4}_*` / `nightshift_20260519_handoff.md` / `p0_38_maxhp_rebalance_closeout_2026-05-17.md` 11 closeout。

### P1.1 候选 1-5 详条迁出 2026-05-21

5 候选全收口(4 实装 + 1 doc):候选 1 收徒池 E.1 / 候选 2 祖师爷 sect_wide_buff / 候选 3 共鸣度 4 子任务 + joint_skill / 候选 4 开锋 build / 候选 5 CLAUDE.md §12 对齐 — `p1_1_*_closeout_2026-05-21.md` 5 closeout。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 74/74 + assets 89 张 + stage_audit + #45 Demo §8.4 · 详 art_poc_* / art_assets_integration_* / p1_45_demo_polish_*
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1-2.5 全收口 + 13 narrative ~5,880 字 · 详 p1_x_chapter4_phase2_*

### 2026-05-22/23/24 详条归档

- **2026-05-22 Ch5 + Ch6 飞升 P2 主线全闭环**(2 章 ~12,438 字 · 师父三句遗言完整连通 · 小铜镜+玉佩 hook 闭环 · 详 `p2_x_chapter{5,6}_phase2_full_closeout_2026-05-22.md`)
- **2026-05-23 心魔 Batch 2.1-2.5 + P3.1 轻功对决**(8h overnight worktree · 7+5 关 · 详 `p2_x_inner_demon_final_closeout_2026-05-23.md` + `p3_1_lightfoot_closeout_2026-05-23.md`)
- **2026-05-24 P3.2 群战守城 + P3.1.B 子批 + P5+ 多代飞升 + 真传位 + 8h overnight v2/v3 + nightshift v2 首跑 + UI polish**(git log `efc7604 → b6d8191` 区间 · 详 handoff `p3_2_*` / `p3_1_b_*` / `p5_lineage_full_closeout_2026-05-24.md` / `nightshift_v2_first_run_closeout_2026-05-24.md` / `8h_autonomous_handoff_2026-05-24.md`)
- **2026-05-25 v2.1 工具完善 + T17-T22 cherry-pick + T23/T24 6 关键问题闭环批**(main `74ba519 → b6d8191` · 1458 测 / 0 analyze · 批次质量 A 9.05/10 · P1.2 江湖恩怨+声望 100% + 技术债 3 合一 · 详 `session_closeout_2026-05-25_nightshift_6h_review.md` + `p1_2_jianghu_full.md` + `p3_tech_debt.md`)

### 2026-05-25/26/27/28 详条归档

- **2026-05-25 P4.1+P5.0+audit v2**(1458→1484 测 · 详各 closeout)
- **2026-05-26 P4.1 1.1 四项+audit v3+P5.2+Boss 招降叙事**(1484→1505 测 · 详各 closeout)
- **2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(1505 测 · 详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
