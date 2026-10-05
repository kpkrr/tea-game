import numpy as np, sys
from PIL import Image, ImageFilter
ART='/Users/kpkr/WebstormProjects/tea-game/prototypes/art-preview/art/'
src=Image.open('/Users/kpkr/WebstormProjects/tea-game/art-source/plate/plate-v9-cold-bright.png').convert('RGB')
def bake(cell, levels=40, crisp=0.5, ink=0.18):
    W,H=src.size; w,h=W//cell,H//cell
    small=src.resize((w,h),Image.BOX)
    a=np.asarray(small).astype(np.float32)/255
    blur=np.asarray(small.filter(ImageFilter.BoxBlur(1))).astype(np.float32)/255
    a=a+(a-blur)*crisp
    l=a@np.array([.299,.587,.114])
    pad=np.pad(l,1,mode='edge')
    nb=np.maximum.reduce([pad[1:-1,2:],pad[1:-1,:-2],pad[2:,1:-1],pad[:-2,1:-1]])
    j=nb-l; a*= (1-ink*np.clip((j-0.12)/0.12,0,1))[...,None]
    a=np.round(np.clip(a,0,1)*levels)/levels
    return Image.fromarray((a*255+.5).astype(np.uint8)).resize((w*cell,h*cell),Image.NEAREST).crop((0,0,W,H)) if w*cell>=W else Image.fromarray((a*255+.5).astype(np.uint8)).resize((w*cell,h*cell),Image.NEAREST)
for cell in (4,6,8):
    im=bake(cell)
    if im.size!=src.size:
        full=src.copy(); full.paste(im,(0,0)); im=full
    im.save(f'{sys.argv[1]}/plate_px{cell}.png')
