# -*- coding: utf-8 -*-
import re, collections
txt = open('data/skills.yaml', encoding='utf-8').read()
blocks = re.split(r'\n\s*- id:', txt)[1:]
rng = {'powerSkill': {1: (1000, 1800), 2: (1000, 1800), 3: (1500, 2500), 4: (1500, 2500), 5: (2000, 3000), 6: (2000, 3000), 7: (2500, 3500)},
       'ultimate': {1: (3000, 4500), 2: (3000, 4500), 3: (4500, 6000), 4: (4500, 6000), 5: (5500, 7000), 6: (5500, 7000), 7: (6500, 8000)}}
stats = collections.defaultdict(list); viol = []; notier = collections.Counter()
for b in blocks:
    sid = b.split('\n', 1)[0].strip()
    t = re.search(r'^\s*type:\s*(\w+)', b, re.M); m = re.search(r'^\s*powerMultiplier:\s*([\d.]+)', b, re.M); tr = re.search(r'^\s*tier:\s*(\d+)', b, re.M)
    if not (t and m): continue
    typ = t.group(1); mult = float(m.group(1))
    if typ not in rng: continue
    if not tr: notier[typ] += 1; continue
    tier = int(tr.group(1)); lo, hi = rng[typ][tier]; stats[(typ, tier)].append(mult)
    if not (lo <= mult <= hi): viol.append((sid, typ, tier, mult, (lo, hi)))
for k in sorted(stats): v = stats[k]; print(k, 'n=%d min=%g max=%g' % (len(v), min(v), max(v)))
print('no tier field:', dict(notier)); print('violations:', len(viol))
for x in viol[:14]: print(' ', x)
