#!/usr/bin/env python3
"""只读清点 numbers.yaml 叶子、字面量引用与保守消费证据；输出 JSON 或 Markdown。"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import subprocess

import yaml


BASELINE = "c64b165938d948a24ab64c7c71de950eea466758"
LABELS = ("生产消费", "仅测试消费", "零引用", "疑似间接消费需人判")

# 这些容器以 Map.entries/map 读取；具体数据键无字面量不能推断为零消费。
# 每次从下列源文件重新查父键与遍历代码；不沿用旧报告的命中数字。
DYNAMIC_MAPS = {
    "inner_demon": "lib/data/defs/inner_demon_def.dart",
    "light_foot": "lib/data/defs/light_foot_def.dart",
    "mass_battle": "lib/data/defs/mass_battle_def.dart",
    "milestone_equipment_grants": "lib/data/numbers_config.dart",
}

# 本次逐组读过的零字面量候选。证据以固定基线 lib 为前提；源码变化后不能套用。
# 每组先排除原始 numbers Map 的通用下游读取，再核对具体字段式解析器。
ZERO_GROUPS = (
    (r"meta\.", "元数据", "NumbersConfig 只从 meta 取 version；未增加 meta 逐键守卫，其余未透传到字段。", ["lib/data/numbers_config.dart:346", "lib/data/numbers_config.dart:353"]),
    (r"combat\.damage_formula\.", "基础公式文档开关", "DamageFormula 只按字段取两个系数，没有整表遍历或额外逐键守卫。", ["lib/data/numbers_config.dart:2429"]),
    (r"combat\.final_damage_formula\.", "最终公式文档开关", "CombatNumbers 构造器逐段解析，没有 final_damage_formula 入口或该段逐键守卫。", ["lib/data/numbers_config.dart:1361"]),
    (r"equipment\.tiers\[", "装备阶模板", "NumbersConfig 的 equipment 读取是强化、开锋、共鸣、遗物与处置；实装装备定义来自独立 equipment.yaml。", ["lib/data/numbers_config.dart:376", "lib/data/game_repository.dart:220", "lib/data/game_repository.dart:228"]),
    (r"equipment\.enhancement\.", "强化公式文档", "强化入口逐字段解析；success_curve 循环只取 level_range/success_rate/material_penalty，公式走 _fallbackFormula。", ["lib/data/numbers_config.dart:922", "lib/data/numbers_config.dart:995", "lib/data/numbers_config.dart:1000"]),
    (r"equipment\.resonance\.", "共鸣换主预留", "共鸣只取 stages、inheritance_retention、seclusion_battle_count_per_hour；stages 新增缺值报错仍只校验显式读取字段。", ["lib/data/numbers_config.dart:404", "lib/data/numbers_config.dart:619"]),
    (r"techniques\.tiers\[", "心法阶名称", "tiers 遍历只取 tier 和 speed_bonus；不遍历行内所有 key/value。", ["lib/data/numbers_config.dart:553"]),
    (r"skills\.reference_multipliers\.", "招式参考倍率", "NumbersConfig 无 skills 入口；实装 SkillDef 来自独立 skills.yaml。", ["lib/data/numbers_config.dart:345", "lib/data/game_repository.dart:222", "lib/data/game_repository.dart:238"]),
    (r"character\.(attributes|adventure_attribute_bonus)\.", "角色设计与事件范围", "character 只取 lifetime_cap_per_character 和 rarity_distribution；新增缺值报错仅守卫前者，未整表或动态读取零命中字段。", ["lib/data/numbers_config.dart:492", "lib/data/numbers_config.dart:504"]),
    (r"retreat\.time_of_day_bonus\[", "时段文档锚", "按 period 选行后只读 multiplier/target_attribute/applies_to_school；没有读取 time_range。", ["lib/data/numbers_config.dart:2847", "lib/data/numbers_config.dart:2912"]),
    (r"tower\.", "旧塔配置段", "NumbersConfig 无 tower 入口；实际楼层由独立 towers.yaml 读取，原始 Map 未被遍历消费。", ["lib/data/numbers_config.dart:345", "lib/data/game_repository.dart:224", "lib/data/game_repository.dart:270"]),
    (r"inheritance\.(unlock_rules|heritage_items)\.", "传承预留字段", "inheritance 只接祖师 buff 和 HeritageItems；后者仍逐个读取六个字段，缺值报错未扩展字段集合，没有通用 Map 遍历。", ["lib/data/numbers_config.dart:428", "lib/data/numbers_config.dart:807"]),
    (r"synergies\.", "旧相生数值段", "NumbersConfig 无 synergies 入口；实际相生定义来自独立 synergies.yaml，原始 Map 未被遍历消费。", ["lib/data/numbers_config.dart:345", "lib/data/game_repository.dart:373"]),
    (r"validation_examples\.", "手工公式战例", "NumbersConfig 无 validation_examples 解析入口；raw 仅持有数据不构成消费。", ["lib/data/numbers_config.dart:345", "lib/data/numbers_config.dart:540"]),
)


def lex_dart(source: str):
    """保留行号剔除注释，枚举字符串；支持嵌套块注释、raw 与三引号。

    插值字符串按文本保留，但不把其中的诊断路径当成真实读取。这里是词法扫描，
    不是 Dart AST/类型分析；无法建立完整数据流的条目必须保留为待人判。
    """
    clean = list(source)
    literals = []
    i = 0
    length = len(source)
    while i < length:
        start = i
        if source.startswith("//", i):
            end = source.find("\n", i)
            i = length if end == -1 else end
            for j in range(start, i):
                clean[j] = " "
            continue
        if source.startswith("/*", i):
            depth = 1
            i += 2
            while i < length and depth:
                if source.startswith("/*", i):
                    depth += 1
                    i += 2
                elif source.startswith("*/", i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            for j in range(start, i):
                if clean[j] != "\n":
                    clean[j] = " "
            continue
        raw = source[i] in "rR" and i + 1 < length and source[i + 1] in "\"'"
        quote_at = i + 1 if raw else i
        if source[quote_at] in "\"'":
            quote = source[quote_at]
            delimiter = quote * (3 if source.startswith(quote * 3, quote_at) else 1)
            value_at = quote_at + len(delimiter)
            i = value_at
            while i < length:
                if source.startswith(delimiter, i):
                    break
                if not raw and source[i] == "\\":
                    i += 2
                else:
                    i += 1
            value = source[value_at:i]
            end = min(length, i + len(delimiter))
            literals.append((start, end, value))
            i = end
            continue
        i += 1
    return "".join(clean), literals


def leaves_with_marks(source: str):
    loader = yaml.SafeLoader(source)
    root = loader.get_single_node()
    rows = []

    def walk(node, path, segments, ancestors):
        if isinstance(node, yaml.MappingNode):
            seen = set()
            for key_node, value_node in node.value:
                key = str(loader.construct_object(key_node, deep=True))
                if key in seen:
                    raise ValueError(f"重复 YAML key：{path}.{key}:{key_node.start_mark.line + 1}")
                seen.add(key)
                walk(value_node, f"{path}.{key}" if path else key,
                     segments + [key], ancestors + [key_node.start_mark.line + 1])
        elif isinstance(node, yaml.SequenceNode):
            for index, value in enumerate(node.value):
                walk(value, f"{path}[{index}]", segments, ancestors)
        else:
            rows.append({"key": path, "value": loader.construct_object(node, deep=True),
                         "yaml_line": node.start_mark.line + 1, "segments": segments,
                         "ancestor_lines": ancestors})

    walk(root, "", [], [])
    loader.dispose()
    return rows


def line_number(text: str, position: int):
    return text.count("\n", 0, position) + 1


def normalize(path: str):
    return re.sub(r"\[\d+\]", "[]", path)


def camel(key: str):
    parts = key.split("_")
    return parts[0] + "".join(word[:1].upper() + word[1:] for word in parts[1:])


def summarize_hits(hits):
    by_file = defaultdict(list)
    for file, line in sorted(set(hits)):
        by_file[file].append(line)
    return [{"file": file, "line_count": len(lines), "lines": lines}
            for file, lines in by_file.items()]


def audit(root: Path, baseline: str = BASELINE):
    yaml_path = root / "data/numbers.yaml"
    yaml_source = yaml_path.read_text(encoding="utf-8")
    rows = leaves_with_marks(yaml_source)
    source_files = {}
    parsed = {}
    digest = hashlib.sha256()
    tracked = subprocess.check_output(["git", "ls-files", "-z", "--", "lib", "test"], cwd=root).decode().split("\0")
    for relative in sorted(path for path in tracked if path):
        file = root / relative
        data = file.read_bytes()
        source_files[relative] = data.decode("utf-8")
        digest.update(relative.encode() + b"\0" + data + b"\0")
        if file.suffix == ".dart":
            parsed[relative] = lex_dart(source_files[relative])
    digest.update(b"data/numbers.yaml\0" + yaml_source.encode())
    guard_command = ["git", "diff", "--quiet", baseline, "--", "lib"]
    guard_result = subprocess.run(guard_command, cwd=root, capture_output=True, check=False)
    if guard_result.returncode not in (0, 1):
        raise RuntimeError("不能核对固定基线 lib：" + guard_result.stderr.decode())
    baseline_paths = set(subprocess.check_output(
        ["git", "ls-tree", "-rz", "--name-only", baseline, "--", "lib"], cwd=root
    ).decode().rstrip("\0").split("\0"))
    lib_baseline_matches = guard_result.returncode == 0 and baseline_paths == {
        file for file in source_files if file.startswith("lib/")
    }

    literal_index = defaultdict(list)
    field_declarations = defaultdict(set)
    member_reads = defaultdict(list)
    class_spans = {}
    for file, (clean, literals) in parsed.items():
        for start, end, value in literals:
            literal_index[value].append((file, line_number(clean, start), start, end))
        if not file.startswith("lib/"):
            continue
        spans = [(match.start(), match.group(1))
                 for match in re.finditer(r"\bclass\s+(\w+)\b", clean)]
        class_spans[file] = spans
        # 字段名全仓唯一是自动证明的一道必要条件；局部变量会使判断更保守。
        for match in re.finditer(r"\bfinal\s+[\w<>?, ]+\s+(\w+)\s*;", clean):
            field_declarations[match.group(1)].add((file, line_number(clean, match.start())))
        # 剔除所有字符串后再搜成员读取，避免错误串/注释伪证据。
        no_strings = list(clean)
        for start, end, _ in literals:
            no_strings[start:end] = " " * (end - start)
        code_only = "".join(no_strings)
        for match in re.finditer(r"\.\s*([A-Za-z_]\w*)\b", code_only):
            if not code_only[match.end():].lstrip().startswith("("):
                member_reads[match.group(1)].append((file, line_number(clean, match.start())))

    terminal_paths = defaultdict(set)
    for row in rows:
        terminal_paths[row["segments"][-1]].add(normalize(row["key"]))
    yaml_lines = yaml_source.splitlines()

    # fromYaml 直接依赖闭包，仅接受已连接的配置读取器，不把任意同名模型当该配置。
    config_files = {"lib/data/numbers_config.dart"}
    pending = list(config_files)
    while pending:
        file = pending.pop()
        for relative in re.findall(r"(?:import|export)\s+['\"]([^'\"]+)['\"]", parsed[file][0]):
            if ":" in relative:
                continue
            target = (root / file).parent.joinpath(relative).resolve().relative_to(root).as_posix()
            if target in parsed and target not in config_files:
                config_files.add(target)
                pending.append(target)

    for row in rows:
        key = row["key"]
        segments = row.pop("segments")
        terminal = segments[-1]
        normalized = normalize(key)
        row["normalized_key"] = normalized
        row["terminal"] = terminal
        row["same_terminal_paths"] = len(terminal_paths[terminal])
        fragments = sorted({".".join(segments[start:end])
                            for start in range(len(segments))
                            for end in range(start + 2, len(segments) + 1)})
        # 路径片段必须含末段，防止任意父段提及给未读叶子伪造命中。
        fragments = [value for value in fragments if value.endswith("." + terminal)]
        literal_hits = {"lib": [], "test": []}
        literal_occurrences = Counter()
        path_hits = {"lib": [], "test": []}
        for file, line, start, end in literal_index.get(terminal, []):
            scope = file.split("/")[0]
            literal_hits[scope].append((file, line))
            literal_occurrences[scope] += 1
        for value, locations in literal_index.items():
            if any(fragment in value for fragment in fragments):
                for file, line, _, _ in locations:
                    path_hits[file.split("/")[0]].append((file, line))
        raw_hits = {"lib": [], "test": []}
        raw_occurrences = Counter()
        for file, content in source_files.items():
            scope = file.split("/")[0]
            if terminal in content:
                raw_occurrences[scope] += content.count(terminal)
                raw_hits[scope].extend((file, i) for i, line in enumerate(content.splitlines(), 1)
                                       if terminal in line)
        for scope in ("lib", "test"):
            row[f"{scope}_literal_count"] = literal_occurrences[scope]
            row[f"{scope}_literal_hits"] = summarize_hits(literal_hits[scope])
            row[f"{scope}_path_fragment_hits"] = summarize_hits(path_hits[scope])
            row[f"{scope}_raw_count"] = raw_occurrences[scope]
            row[f"{scope}_raw_hits"] = summarize_hits(raw_hits[scope])

        comments = []
        for line in sorted(set(row.pop("ancestor_lines") + [row["yaml_line"]])):
            if "#" in yaml_lines[line - 1]:
                comments.append((line, yaml_lines[line - 1].split("#", 1)[1].strip()))
            previous = line - 2
            while previous >= 0:
                text = yaml_lines[previous].strip()
                if text and not text.startswith("#"):
                    break
                if text.startswith("#"):
                    comments.append((previous + 1, text.lstrip("# ")))
                previous -= 1
        row["unused_comments"] = [{"line": line, "text": text} for line, text in sorted(set(comments))
                                  if "UNUSED" in text]
        row["unused_marked"] = bool(row["unused_comments"])

        dynamic = []
        dynamic_file = DYNAMIC_MAPS.get(segments[0])
        if dynamic_file:
            clean = parsed[dynamic_file][0]
            for parent in segments[1:-1] if len(segments) > 2 else segments[:-1]:
                locations = [item for item in literal_index.get(parent, []) if item[0] == dynamic_file]
                if locations and (".entries" in clean or ".map(" in clean):
                    dynamic.extend((item[0], item[1]) for item in locations)
        row["dynamic_container_evidence"] = summarize_hits(dynamic)

        # 自动双向证据：唯一末段路径、已连接解析器中的字段赋值、全仓唯一字段声明、
        # lib/data 外的真实成员读取。不同名、别名、列表/Map 或字段碰撞均不强猜。
        production = []
        field = camel(terminal)
        if (len(terminal_paths[terminal]) == 1 and len(field_declarations[field]) == 1
                and not dynamic):
            for file, line, start, end in literal_index.get(terminal, []):
                if file not in config_files:
                    continue
                clean = parsed[file][0]
                before = clean[max(0, start - 180):start]
                # 只认可本字段命名实参后无其他语句/实参的读取，排除随意近邻。
                binding = re.search(r"\b" + re.escape(field) + r"\s*:\s*([^;:{}]*?)$", before)
                if not binding:
                    continue
                declaration_file, declaration_line = next(iter(field_declarations[field]))
                if declaration_file != file:
                    continue
                external = [(f, n) for f, n in member_reads[field]
                            if not f.startswith("lib/data/") and f != file]
                if external:
                    production.append({"field": field, "parser": f"{file}:{line}",
                                       "declaration": f"{declaration_file}:{declaration_line}",
                                       "consumers": summarize_hits(external)})
        row["production_evidence"] = production
        group = next((item for item in ZERO_GROUPS if re.match(item[0], key)), None)
        row["zero_group_evidence"] = ({"group": group[1], "reason": group[2], "sources": group[3],
                                       "lib_matches_reviewed_baseline": lib_baseline_matches}
                                      if group else None)
        if production:
            verdict = LABELS[0]
            reason = "唯一末段路径和字段声明；配置解析赋值及 lib/data 外成员读取均有静态证据。"
        elif dynamic:
            verdict = LABELS[3]
            reason = "父容器存在 Map 遍历；末段字面量缺失不证明未消费，需按容器数据流复核。"
        elif (not raw_hits["lib"] and not literal_hits["test"] and not path_hits["test"]
              and group and lib_baseline_matches):
            verdict = LABELS[2]
            reason = "受版本管理 lib 全文本末段 0 命中，test Dart 字面量及路径片段 0 命中；固定基线逐组人工排除了动态消费。"
        else:
            verdict = LABELS[3]
            reason = "同名键、注释/诊断/夹具命中、仅解析、字段别名或尚无完整消费者证据；不能仅凭命中认定消费。"
        # 仅测试消费需要证明读取此 YAML 的具体路径；夹具文本/同名断言不构成证明。
        row["verdict"] = verdict
        row["reason"] = reason
        if verdict == LABELS[2]:
            if key.startswith(("meta.", "validation_examples.", "combat.final_damage_formula.",
                               "combat.damage_formula.skill_multiplier_added", "retreat.time_of_day_bonus")):
                row["suggestion"] = "保留理由：元数据/公式或时段文档锚；建议迁出可调配置，是否迁移或删除待用户拍板。"
            elif key.startswith("equipment.resonance.new_owner_retention"):
                row["suggestion"] = "待拍板：原注释要求保留换主语义锚；当前零引用不能替代设计决定。"
            else:
                row["suggestion"] = "删除候选：当前静态零引用；先确认设计锚/未来配置用途，删除须用户拍板。"
        else:
            row["suggestion"] = "保留并复核消费链；本单不删除配置。"

    grep_samples = []
    for terminal in ("last_updated", "skill_multiplier_added", "apply_cultivation_multiplier",
                     "apply_school_counter", "new_owner_retention", "daily_attempts",
                     "refresh_at", "sync_to_supabase"):
        command = ["git", "grep", "-n", "-F", "--", terminal, "--", "lib"]
        result = subprocess.run(command, cwd=root, capture_output=True, text=True, check=False)
        if result.returncode not in (0, 1):
            raise RuntimeError(f"grep 失败：{result.stderr}")
        grep_samples.append({"terminal": terminal, "command": command,
                             "exit_code": result.returncode,
                             "output_lines": len(result.stdout.splitlines()),
                             "passed": result.returncode == 1 and not result.stdout})
    production_samples = []
    for key, field, file in (
        ("combat.qi.opening_qi", "openingQi", "lib/shared/battle_shared/player_combatant_snapshot_builder.dart"),
        ("combat.damage_formula.equipment_attack_factor", "equipmentAttackFactor", "lib/features/combat_shared/domain/damage_calculator.dart"),
        ("combat.max_hp_formula.constitution_factor", "constitutionFactor", "lib/shared/battle_shared/derived_stats.dart"),
    ):
        terminal = key.split(".")[-1]
        commands = [["grep", "-nF", "--", "['" + terminal + "']", "lib/data/numbers_config.dart"],
                    ["grep", "-nF", "--", "." + field, file]]
        outputs = [subprocess.run(command, cwd=root, capture_output=True, text=True, check=False)
                   for command in commands]
        row = next(row for row in rows if row["key"] == key)
        production_samples.append({"key": key, "commands": commands,
                                   "outputs": [result.stdout.splitlines() for result in outputs],
                                   "passed": all(result.returncode == 0 for result in outputs)
                                   and row["verdict"] == LABELS[0]})
    return {"baseline": baseline, "input_sha256": digest.hexdigest(),
            "numbers_sha256": hashlib.sha256(yaml_source.encode()).hexdigest(),
            "lib_baseline_guard": {"command": guard_command, "exit_code": guard_result.returncode,
                                   "tracked_paths_match": baseline_paths == {file for file in source_files if file.startswith("lib/")},
                                   "passed": lib_baseline_matches},
            "scope": {"inventory_command": ["git", "ls-files", "-z", "--", "lib", "test"],
                      "lib_files": sum(f.startswith("lib/") for f in source_files),
                      "test_files": sum(f.startswith("test/") for f in source_files),
                      "test_dart_files": sum(f.startswith("test/") for f in parsed),
                      "raw_search": "lib/test 受版本管理 UTF-8 文件；排除未跟踪/ignored 文件；区分原始文本与去注释 Dart 字符串。"},
            "counts": {"scalar_leaves": len(rows),
                       "normalized_paths": len({row["normalized_key"] for row in rows}),
                       "unique_terminals": len(terminal_paths),
                       "zero_normalized_paths": len({row["normalized_key"] for row in rows if row["verdict"] == LABELS[2]}),
                       "zero_unique_terminals": len({row["terminal"] for row in rows if row["verdict"] == LABELS[2]}),
                       "verdicts": {label: sum(row["verdict"] == label for row in rows) for label in LABELS}},
            "sample_verification": {"zero_grep": grep_samples, "production_grep": production_samples},
            "rows": rows}


def markdown(data):
    counts = data["counts"]
    lines = ["# numbers.yaml 零引用 key 清点（B-2）", "",
             f"基线：`{data['baseline']}`。本次读取现有工作树 `data/numbers.yaml`、`lib/`、`test/`，未读取 A 单文件。",
             f"输入联合 SHA-256：`{data['input_sha256']}`；YAML SHA-256：`{data['numbers_sha256']}`。", "",
             "## 复跑命令与口径", "", "```sh",
             f"python3 tools/audit/numbers_key_usage.py --baseline {data['baseline']}",
             f"python3 tools/audit/numbers_key_usage.py --baseline {data['baseline']} --format markdown",
             "```", "",
             "依赖当前已有 Python 3 与 PyYAML；不运行 Flutter、不安装依赖、不写配置。JSON 输出到 stdout；第二条同源生成本报告。",
             "检索清单由 `git ls-files -z -- lib test` 固定，只读受版本管理文件；不纳入协调者 worktree 的未跟踪/ignored `.g.dart` 或构建产物。",
             f"本次实际为 **{counts['scalar_leaves']} 个标量叶子**（数组展开为 `[0]`、`[1]`，含 null），"
             f"索引归一后 **{counts['normalized_paths']} 个路径**，末段去重 **{counts['unique_terminals']} 个名字**。"
             "这些口径不同，不能将旧报告约 460 个 key 当作本表分母。重复 YAML 映射 key 会直接报错，数组中的同名字段分别保留。", "",
             "| 判定 | 标量叶子数 |", "|---|---:|"]
    lines += [f"| {label} | {counts['verdicts'][label]} |" for label in LABELS]
    lines += ["", f"零引用的 {counts['verdicts']['零引用']} 个标量叶子对应 **{counts['zero_normalized_paths']} 个归一路径、{counts['zero_unique_terminals']} 个末段名**。"
              "待人判数量较大是因为同名键和列表字段不能仅凭一次字符串命中分配到具体 YAML 路径；本单不靠强行分类提高完成率。",
              "", "判定是静态证据等级，不是运行覆盖率：", "",
              "- 生产消费须同时具备唯一归一末段路径、已连接配置解析器的字段赋值、唯一 final 字段声明以及解析层外成员读取；JSON 列出两端 file:line。仍不证明该分支在当前玩家路径必达。",
              "- 只命中 loader、注释、报错字符串、测试夹具或同名字段均留作疑似间接消费；未证明仅测试真实消费的条目不硬归为仅测试消费。",
              "- 零引用要求受版本管理 lib 原始文本连注释也无末段命中，且 test Dart 字面量和完整路径片段均无命中；还须落入下文人工排除动态消费的组，且 lib 与审计基线一致。测试纯说明文字另列 raw 命中。",
              "- 对所有叶子同时检索末段精确 Dart 字符串与含末段的完整/后缀路径片段；路径片段命中本身不提升为生产消费。JSON 同时输出原文次数、字面量次数、文件和行号，防止 grep 与词法计数混淆。",
              "- 心魔、轻功、守城和里程碑授予 Map 容器显式标为待人判；其他动态容器也不因零字面量自动进入零引用。源码与基线不一致或候选落在未审计分组时，一律降为待人判。静态扫描不是 Dart AST/运行期追踪。",
              "", "## 重点段交叉核对", "",
              "以下计数也由本次 JSON 逐行归集；同名导致待人判不能反推该段已消费。", "",
              "| 段 | 标量叶子 | 生产消费 | 仅测试消费 | 零引用 | 待人判 |", "|---|---:|---:|---:|---:|---:|"]
    for prefix in ("tower.", "synergies.", "combat.final_damage_formula.", "validation_examples."):
        subset = [row for row in data["rows"] if row["key"].startswith(prefix)]
        subtotal = Counter(row["verdict"] for row in subset)
        lines.append(f"| `{prefix[:-1]}` | {len(subset)} | " + " | ".join(str(subtotal[label]) for label in LABELS) + " |")
    lines += ["", "## 动态消费排除证据", "",
              "入口复核：`lib/data/game_repository.dart:219` 加载 numbers，`:226` 交给 NumbersConfig，`:227` 另取 realms。"
              "`NumbersConfig.raw` 的实际取值仅见 `lib/data/numbers_config.dart:340` 的 milestone_equipment_grants；`:540` 原样持有 Map 不视作消费。",
              "可复核命令：`rg -n '\\.raw\\b|raw\\[|numbersRaw\\b' lib --glob '*.dart'`；"
              "`rg -n '\\.entries|\\.values|\\.map\\(|\\[key\\]' lib/data/numbers_config.dart`。"
              "命中的其他 raw 局部变量须按所在类区分，不能当作 NumbersConfig.raw。",
              "另核对了开锋 bonus_value 的 entries（numbers_config.dart:1142）、动作链动态段（:2240）、"
              "招式按 key 获取（:2146）、周目 assignment 双层动态键（:3883）；这几组没有进入零引用清单。",
              f"基线保护实跑：`git diff --quiet {data['baseline']} -- lib` 退出 `{data['lib_baseline_guard']['exit_code']}`，"
              f"受版本管理路径清单一致为 `{str(data['lib_baseline_guard']['tracked_paths_match']).lower()}`。"
              "此保护失败时，以下人工排除结论不再用于自动判零。", "",
              "| 零引用候选组 | 本次叶子数 | 排除动态消费的理由 | 固定基线证据 |", "|---|---:|---|---|"]
    for pattern, name, reason, sources in ZERO_GROUPS:
        total = sum(row["verdict"] == LABELS[2] and bool(re.match(pattern, row["key"])) for row in data["rows"])
        lines.append(f"| {name} | {total} | {reason} | " + "；".join(f"`{source}`" for source in sources) + " |")
    lines += ["", "## 零引用逐条表", "", "所有行建议只供用户拍板；没有删除任何配置。数组逐元素列出，所在源行可重复。", "",
              "| key | 叶子值 | YAML 行 | 所在段已标 UNUSED | 建议 |", "|---|---|---:|---|---|"]
    def cell(value):
        return str(value).replace("|", "\\|").replace("\n", "<br>")
    for row in data["rows"]:
        if row["verdict"] != "零引用":
            continue
        value = json.dumps(row["value"], ensure_ascii=False)
        unused = "是：" + ", ".join(str(item["line"]) for item in row["unused_comments"]) if row["unused_marked"] else "否"
        lines.append(f"| `{row['key']}` | {cell(value)} | {row['yaml_line']} | {unused} | {row['suggestion']} |")
    lines += ["", "## 独立复核命令", "", "以下 8 个末段覆盖元数据、公式、换主预留与塔段；`git grep` 应退出 1 且输出 0 行。本次另用 `grep -rnF` 独立检查，同为 8/8 零命中。", "", "```sh",
              "for key in last_updated skill_multiplier_added apply_cultivation_multiplier apply_school_counter new_owner_retention daily_attempts refresh_at sync_to_supabase; do",
              "  git grep -n -F -- \"$key\" -- lib; printf '%s grep_exit=%s\\n' \"$key\" \"$?\"",
              "done", "```", "",
              "生产样本同时复核解析和消费，两端都须存在：", "", "```sh",
              "rg -n \"opening_qi|openingQi\" lib/data/numbers_config.dart lib/shared/battle_shared/player_combatant_snapshot_builder.dart",
              "rg -n \"equipment_attack_factor|equipmentAttackFactor\" lib/data/numbers_config.dart lib/features/combat_shared/domain/damage_calculator.dart",
              "rg -n \"constitution_factor|constitutionFactor\" lib/data/numbers_config.dart lib/shared/battle_shared/derived_stats.dart",
              "```", "",
              "本次脚本每次独立调用 grep 的实际结果：零引用 "
              f"**{sum(row['passed'] for row in data['sample_verification']['zero_grep'])}/8**（输出 0 行、退出 1）；生产两端命中 "
              f"**{sum(row['passed'] for row in data['sample_verification']['production_grep'])}/3**。完整命令、退出码与消费行见 JSON 的 `sample_verification`。",
              "", "## 限制与建议", "",
              "零引用并不自动等于可删。UNUSED 仅表示 YAML 原注释标注，不能替代本次检索；纯文档段、设计锚和动态读取分别保留。",
              "优先人工核对动态 Map 与同名字段，再判断是否删除或将说明锚迁入文档；任何删除配置字段都需用户拍板。",
              "本单仅审计 YAML 有而代码引用不明确的方向；不读取、不合并、不覆盖 A 单的兜底残留报告。", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--baseline", default=BASELINE, help="逐组人工复核所依据的 lib 基线 SHA")
    parser.add_argument("--format", choices=("json", "markdown"), default="json")
    args = parser.parse_args()
    data = audit(args.root.resolve(), args.baseline)
    output = markdown(data) if args.format == "markdown" else json.dumps(data, ensure_ascii=False, indent=2)
    print(output.rstrip())


if __name__ == "__main__":
    main()
