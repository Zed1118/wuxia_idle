# Codex image_gen 派单:重出我方 3 张战斗立绘(色调代际统一批)

> 自包含派单:读完本文即可干活。你有 image_gen 工具,自主出图。
> 性质:in-place 重出候选——**不许动 assets/ 与任何代码/git**,产物只落指定 dispatch 目录。

## 一 · 任务一句话

按塔批 C 同代「水墨厚涂+冷暖双色相」画风,重出玩家侧 3 张战斗立绘(祖师/大弟子/二弟子),解决「我方灰蒙蒙、色相单一(≥95% 挤在红橙暖土桶)」的代际差;人物身份/面容/发型/体型/兵器/站姿大势与各自身份锚**同人不变**。

## 二 · 输入锚(5 张,全为已解码真 PNG)

**身份锚(必须同人,站姿沿此)**:
1. 祖师:`/Users/a10506/.claude/jobs/1dedbe6d/tmp/anchor_battle_founder_v2.png`(白发长髯老者,宽大道袍,拂袖而立)
2. 大弟子:`/Users/a10506/.claude/jobs/1dedbe6d/tmp/anchor_battle_first_disciple.png`(黑发束发青年,劲装持剑)
3. 二弟子:`/Users/a10506/.claude/jobs/1dedbe6d/tmp/anchor_battle_second_disciple.png`(束发少年,布衣佩剑)

**画风/色相结构锚(厚涂+冷暖双色相参照,勿抄人物)**:
4. `/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/night-songguan-baibu/assets/enemies/tower_boss_zhuifeng_jianyin.png`
5. `/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/night-songguan-baibu/assets/enemies/tower_boss_youming_panguan.png`

## 三 · 每张的色相方案(三人错开,队伍内区分度)

| 张 | 冷色相主块(占非透明像素 ≥15%) | 点缀 |
|---|---|---|
| 祖师 | **青灰**(袍身/大氅主体转青灰调) | 绛红束带或穗一处 |
| 大弟子 | **青绿**(外袍或披风主块) | 绛红一处 |
| 二弟子 | **蓝紫**(衣身主块) | 绛红一处 |

保水墨厚涂写实武侠基调,禁卡通化、禁高饱和荧光色;冷色块要像批 C Boss 那样是「衣饰结构块」,不是滤镜罩染。

## 四 · 硬规格(沿塔批 C 体例,逐张必过)

- 1024×1536 RGBA PNG,**四角 alpha 全 0**(标准绿幕抠图+去绿溢色)
- 单人全身站姿,无文字无水印,枪剑等兵器完整在画布内
- **批次尺度归一(防「矮一截」坑)**:alpha bbox 上沿 ≈70 / 下沿 ≈1480(脚底 fraction ≈0.9635,单张允差 ±0.005),三张纵跨彼此差 ≤30px;参照锚 4/5 实测均为 bbox(*,70,*,1480) 纵跨 1410
- 面容/发型/年龄/体型与对应身份锚同人可辨;站姿大势沿锚,允许衣饰细节为色块服务微调

## 五 · 落盘与自检报告(必做)

- 产物目录:`/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/night-songguan-baibu/build/dispatch/player_standee_20260805/`
- 三个文件名**精确**为:`battle_founder_v2.png` / `battle_first_disciple.png` / `battle_second_disciple.png`
- `report.md` 逐张记:尺寸/四角 alpha/alpha bbox(注明半开区间口径)/脚底 fraction/纵跨/冷色相主块占比自测(HSV,S≥0.15 且色相落青绿蓝紫区间的像素占非透明像素比)/与身份锚同人说明/终版结论
- 自检不过硬规格就重出(每张最多 3 次尝试),报告里写明尝试次数
- **不要**写 assets/、不 checkout、不动代码、不 git 操作
