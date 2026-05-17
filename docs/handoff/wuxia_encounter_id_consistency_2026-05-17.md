# encounter id 一致性扫描(2026-05-17)

> Nightshift T01 产出。当前基线:encounters.yaml ↔ events/*.yaml ↔ _archive/ 三集合一致性快照。

## 0. 扫描范围
- 工作树:`/Users/a10506/Desktop/wuxia-idle-T01`(基于 main HEAD `fc25207`)
- 输入 1:`data/encounters.yaml`
- 输入 2:`data/events/*.yaml`
- 输入 3:`data/events/_archive/*.yaml`

## 1. 统计

| 集合 | 数量 |
|---|---|
| encounters.yaml id | 40 |
| data/events/*.yaml | 40 |
| data/events/_archive/*.yaml | 6 |

### encounters.yaml 完整 id 列表(按定义顺序)

```
bamboo_listen_rain
cha_ting_dui_ju
du_ke_wen_dao
gu_jian_zhong_yin
cang_jing_ge_wu
shan_lin_qi_yu
xuan_ya_pu_bu_li_lian
duan_ya_chui_lian
shan_dao_wu_zhe
xiao_zhen_wen_yi
ye_xing_xun_dao
du_kou_chun_yu
qun_xia_tu
lu_pang_xian_xian
gu_dao_xue_ji
xue_ye_gu_qin
feng_xue_gu_dian
ye_du_gu_chuan
han_mei_ying_xue
xing_chen_wu_dao
qiu_ye_wei_qi
shi_dao_shou_hu
mu_chan_dui_yin
huang_sha_ke_zhan
xiang_ye_shen_ji
luo_hua_jian_yuan
shan_ya_can_bei
jue_ding_feng_qi
huang_miao_jiu_seng
jiu_lou_jue_yin
chun_jie_shou_sui
yuan_xiao_guan_deng
duan_wu_du_long_zhou
qi_xi_xi_qiao
zhong_qiu_yue_xia_du
chong_yang_deng_gao
chu_xi_ci_sui
qing_ming_yu_si
huang_yuan_yi_zhong
jiang_xin_ye_hua
```

### data/events/*.yaml 完整文件 id 列表(字母序)

```
bamboo_listen_rain
cang_jing_ge_wu
cha_ting_dui_ju
chong_yang_deng_gao
chu_xi_ci_sui
chun_jie_shou_sui
du_ke_wen_dao
du_kou_chun_yu
duan_wu_du_long_zhou
duan_ya_chui_lian
feng_xue_gu_dian
gu_dao_xue_ji
gu_jian_zhong_yin
han_mei_ying_xue
huang_miao_jiu_seng
huang_sha_ke_zhan
huang_yuan_yi_zhong
jiang_xin_ye_hua
jiu_lou_jue_yin
jue_ding_feng_qi
lu_pang_xian_xian
luo_hua_jian_yuan
mu_chan_dui_yin
qi_xi_xi_qiao
qing_ming_yu_si
qiu_ye_wei_qi
qun_xia_tu
shan_dao_wu_zhe
shan_lin_qi_yu
shan_ya_can_bei
shi_dao_shou_hu
xiang_ye_shen_ji
xiao_zhen_wen_yi
xing_chen_wu_dao
xuan_ya_pu_bu_li_lian
xue_ye_gu_qin
ye_du_gu_chuan
ye_xing_xun_dao
yuan_xiao_guan_deng
zhong_qiu_yue_xia_du
```

### data/events/_archive/*.yaml 完整文件 id 列表(W17 #37 永封档)

```
duan_qiao_can_yue
gu_chuan_deng_ying
huang_cun_yao_ren
lao_jing_hui_xiang
qing_lou_can_meng
yu_zhong_qiao_men
```

## 2. 双向对账

### 2.1 encounters.yaml id → events/ 文件
- **全部命中**。40 个 id 在 `data/events/` 下均有同名 `.yaml` 文件，0 个 missing。

### 2.2 events/ 文件 → encounters.yaml id
- **全部命中**。40 个 events/ 文件在 `encounters.yaml` 中均有对应 entry，0 个 orphan。

### 2.3 _archive/ → encounters.yaml id(应 0)
- **0 个 orphan-but-referenced**。6 个 archive 文件均不在 `encounters.yaml` id 集合中，符合永封档预期。

## 3. 结论

**0 漂移。基线建立成功。**

三集合当前状态：
- `encounters.yaml`(40 id) ↔ `data/events/`(40 文件) 严格 1:1 对齐
- `data/events/_archive/`(6 文件) 与 `encounters.yaml` 零交集，W17 #37 永封档状态锁定

本快照可作为 W18+ 新增 encounter 的对账基线。

## 4. 后续维护建议

- **新增 encounter**：`encounters.yaml` 加 entry 的同时，`data/events/<id>.yaml` 同步创建，id 字段严格匹配，加载层 `GameRepository._enforceEncounterRedLines` 会强校验
- **永封档 encounter**：
  1. `mv data/events/<id>.yaml data/events/_archive/`
  2. 从 `encounters.yaml` 删对应 entry
  3. 重跑本扫描逻辑(grep `^  - id:` + ls diff)确认 0 漂移后再 commit
- **定期扫描命令**（可加入 CI 或 nightshift verify）：
  ```bash
  # encounters.yaml id 集合
  enc=$(grep '^  - id:' data/encounters.yaml | sed 's/  - id: //' | sort)
  # events/ 文件集合
  evts=$(ls data/events/*.yaml | xargs -I{} basename {} .yaml | sort)
  # diff 应为空
  diff <(echo "$enc") <(echo "$evts") && echo "OK: 0 漂移" || echo "FAIL: 漂移检测到"
  ```
- **archive 反向核查**（确保永封档不被重新引用）：
  ```bash
  for f in data/events/_archive/*.yaml; do
    id=$(basename "$f" .yaml)
    grep -q "^  - id: $id$" data/encounters.yaml && echo "FAIL: $id 被重引用" || true
  done
  echo "archive 反向核查完毕"
  ```
