# 桃花岛 v1 背景图接线实装批(2026-08-18)

> 分支 `feat/taohua-island-bg-v1-0818` · 基于 main `5e49211f`
> 用户已拍板:一#17「采用 v1」(2026-08-18 目检)
> 证据夹 `~/Desktop/Projects/挂机武侠素材/桃花岛美术候选_20260807/`

## 实装内容

1. **资产入库**:证据夹 `entry_taohua_island_v1.png`(C 类原图 1456×816 RGB)
   → `assets/scenes/taohua_island_v1.png`。**幅面拍 C 原图不用 D 扩幅**:
   D 为 2448×1224(2:1),桌面窗口 1280×720/1440×900 下 cover 上下裁切过狠;
   C 16:9 与主验收视口零裁切,1440×900 仅左右微裁(建筑区居中,复检图已证)
2. **不 webp 转码**:scenes/ 现状 147 png 零 webp,沿现状体例
3. **屏接线**:`TaohuaIslandScreen` Scaffold body 底铺 `Image.asset`
   `BoxFit.cover` + scrim `ColoredBox(Color(0x380F0E0B))`(phase0a 同体例同值),
   原内容层叠上;AppBar ink 底与 Scaffold paper 底不动
4. **测试**:`taohua_island_screen_test.dart` 新增背景接线测(find image asset
   路径 + scrim 精确断言),破坏证红=撤接线必红
5. **视觉验收**:visual route `taohua_island` 已有,拍 1280×720 目检可读性
   (建筑网格文字在 scrim 上可读)

## 验收标准

- [ ] 资产入库恰 1 文件,`git status` 零杂散
- [ ] 新测绿 + 破坏证红精确命中 + 还原复绿
- [ ] `taohua_island_screen_test` 既有全绿(零回归)+ analyze 0
- [ ] 视觉路由拍图目检通过(可读性)
- [ ] 全量 flutter test 基线 +1(5161)或 CI 守恒核
- [ ] PROGRESS 登记守 ≤100 行 · BACKLOG 一#17 销行

## 红线

- 不写中文文案硬编码(本批零文案);不动数值;commit 中文动宾
- 可读性存疑时降级方案=scrim 加深或回退,不硬上

## 当前恢复点

- **状态**:RP0,计划档冻结中
- **最后完成**:分支已建,摸底完成(scenes 全 png / visual route 已有 /
  screen test 696 行体例清楚 / phase0a scrim 体例 `0x380F0E0B`)
- **下一步**:资产入库 → 接线 → 红绿测
- **阻塞项**:无
