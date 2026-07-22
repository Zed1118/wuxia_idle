# webp 转码清账批 恢复点(2026-07-22)

分支: kimi/webp-stragglers-20260722(基于 main 5396706e)
worktree: .worktrees/webp-batch

## 目标
assets 下残余真 PNG 全量过 `tool/convert_assets_webp.py`(q80·method6·≥10% 收益阈值·原地保 .png 名),由脚本阈值决定转换集。

## 基线(批前实测)
- .png 文件 552 个,已是 WebP 内容 375,真 PNG 177,真 PNG 体积 113.6M
- assets 总量 du: 185M
- 全量测试基线: 4626 通过(派单方口径,批末实测复核)

## 进度
- [x] flutter pub get(+ build_runner build,worktree 缺 .g.dart)
- [x] 复核基线(与派单口径一致: 177 真 PNG / 113.6M)
- [x] 跑 convert_assets_webp.py: 已转码 67 / 保持PNG(无收益) 110 / 已是WebP跳过 375,节省 92.1M
- [x] PIL 安全闸: /tmp/webp_gate.py 复测 20 张 Ch9-Ch12 直用敌立绘全过
      (四角 alpha 全 0;脚底 fraction 对注册值最大偏差 1.54‰ ≤ 2‰;回退清单空)
- [x] targeted 守卫: webp_in_png_decode + asset_audit + art_tone_audit
      + pubspec_asset_declaration 12 测全过(续跑会话复跑仍全过)
- [x] flutter analyze 0 issue(续跑会话复跑仍 0)
- [x] 全量 flutter test --no-pub: 4626 通过 0 fail(与基线 4626 一致)
- [ ] commit + push + gh pr create --draft(§8.2 四证据)

## 续跑会话独立复核(2026-07-22)
- magic byte 全扫: .png 552 个 = WebP 内容 442 + 真 PNG 110(12.5M,即 07-02 拍板保留小图标)
- 67 个改动文件全部 WebP 内容;git 原值对账: 101.1M → 9.0M,省 92.1M(与脚本记录一致)
- PIL 安全闸复跑: 20 张全 OK,失败 0

## 回退清单
(空)

## 实测记录
- assets du: 185M → 92M(转码 67 张,省 92.1M)
- 转换集: 37 敌立绘 + 6 装备图 + 4 章封面 + 20 剧情背景 = 67 张
- 无 dart 改动,无需 dart format
