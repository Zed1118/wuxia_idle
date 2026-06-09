import os,json,glob
import numpy as np, cv2
from PIL import Image, ImageFilter

SRC='/Users/a10506/Desktop/Projects/挂机武侠/assets/equipment'
OUT='/Users/a10506/.claude/jobs/74c6fb8e/tmp/cut_out'
PAP='/Users/a10506/.claude/jobs/74c6fb8e/tmp/cut_paper'
man=json.load(open('/Users/a10506/.claude/jobs/74c6fb8e/tmp/manifest.json'))
PAPER=(0xEF,0xE3,0xC7)

def cut_one(path):
    rgb=np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    h,w=rgb.shape[:2]; s=max(8,min(h,w)//20)
    refs=np.array([rgb[:s,:s].reshape(-1,3).mean(0),rgb[:s,-s:].reshape(-1,3).mean(0),
                   rgb[-s:,:s].reshape(-1,3).mean(0),rgb[-s:,-s:].reshape(-1,3).mean(0)])
    ref=refs.mean(0)  # 主 bg 色(四角均匀时代表性强)
    # 1) 软斜坡:到最近 bg-ref 的欧氏距离 → alpha ramp(柔边)
    dist=np.min(np.stack([np.sqrt(((rgb-r)**2).sum(2)) for r in refs]),0)
    lo,hi=34.0,74.0
    ramp=np.clip((dist-lo)/(hi-lo),0,1)         # 0=bg .. 1=前景
    # 2) 投影感知:像素 ≈ k*ref(同色等比变暗,k∈[0.5,1.15])且色相贴近 → bg/投影
    rn=ref/ (np.linalg.norm(ref)+1e-6)
    proj=(rgb*rn).sum(2)                          # 在 ref 方向投影长度
    perp=np.sqrt(np.maximum((rgb**2).sum(2)-proj**2,0))  # 垂直分量=偏色程度
    reflen=np.linalg.norm(ref); k=proj/(reflen+1e-6)
    shadowlike=(perp<26)&(k>0.5)&(k<1.18)         # 同色系、亮度0.5~1.18倍=bg或其投影
    # 3) 连通域:外背景+大环洞 硬删
    bgbin=((ramp<0.5)|shadowlike).astype(np.uint8)
    n,lab,st,_=cv2.connectedComponentsWithStats(bgbin,connectivity=4)
    hard0=np.zeros((h,w),bool); minhole=int(h*w*0.0012)
    for i in range(1,n):
        x,y,bw,bh,area=st[i]
        if x==0 or y==0 or x+bw>=w or y+bh>=h or area>minhole:
            hard0|=(lab==i)
    # 4) 红朱印
    R,G,B=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    hard0|=((R-G>32)&(R-B>32)&(R>80))
    # 5) alpha = ramp，但 shadowlike & hard0 处压 0
    alpha=ramp.copy(); alpha[shadowlike]=np.minimum(alpha[shadowlike],0.0); alpha[hard0]=0
    # 6) 角落小孤立块(题字印)删
    fgbin=(alpha>0.35).astype(np.uint8)
    n2,lab2,st2,cen=cv2.connectedComponentsWithStats(fgbin,connectivity=8)
    if n2>1:
        areas=st2[1:,4]; mainarea=areas.max(); bb=int(min(h,w)*0.20)
        for i in range(1,n2):
            if st2[i,4]==mainarea: continue
            cx,cy=cen[i]
            incorner=(cx<bb or cx>w-bb) and (cy<bb or cy>h-bb)
            if st2[i,4]<mainarea*0.04 and incorner:
                alpha[lab2==i]=0
    a8=(np.clip(alpha,0,1)*255).astype(np.uint8)
    am=Image.fromarray(a8).filter(ImageFilter.GaussianBlur(0.5))  # 仅轻羽化,不 MinFilter(保柔边)
    out=Image.open(path).convert('RGBA'); out.putalpha(am)
    return out,(a8>128).mean()

for bn in man['cut']:
    im,_=cut_one(os.path.join(SRC,bn))
    im.save(os.path.join(OUT,bn))
    base=Image.new('RGBA',im.size,PAPER+(255,)); base.alpha_composite(im)
    base.convert('RGB').save(os.path.join(PAP,bn))
print("v3 重出",len(man['cut']),"张")
