import glob,os,json
from PIL import Image
import numpy as np
SRC='/Users/a10506/Desktop/Projects/挂机武侠/assets/equipment'
def corner_spread(f):
    a=np.asarray(Image.open(f).convert('RGB')).astype(np.float32)
    h,w=a.shape[:2]; s=max(4,min(h,w)//20)
    ms=np.array([a[:s,:s].reshape(-1,3).mean(0),a[:s,-s:].reshape(-1,3).mean(0),
                 a[-s:,:s].reshape(-1,3).mean(0),a[-s:,-s:].reshape(-1,3).mean(0)])
    return ms.std(0).mean(), ms.mean(0)
scene=[];cut=[];border=[]
for f in sorted(glob.glob(SRC+'/*.png')):
    bn=os.path.basename(f); sp,mean=corner_spread(f)
    if sp>18: scene.append((bn,round(sp,1)))
    else:
        cut.append(bn)
        if sp>11: border.append((bn,round(sp,1)))   # 临界 11-18 重点核
json.dump({'scene':[x[0] for x in scene],'cut':cut,'border':[x[0] for x in border]},
          open('/Users/a10506/.claude/jobs/74c6fb8e/tmp/manifest.json','w'),ensure_ascii=False)
print(f"scene(不抠): {len(scene)}   cut(抠): {len(cut)}   临界 11-18 待核: {len(border)}")
print("\n=== SCENE(不抠)===");  [print("  ",b,sp) for b,sp in scene]
print("\n=== 临界 11-18(归 cut,sheet 重点核)==="); [print("  ",b,sp) for b,sp in border]
