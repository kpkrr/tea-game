"""Export the station item masks (phone frame 720x1600 = noguests-360x800-t52, device px) as cropped PNGs + offsets,
so the game can hide sign legs behind the painted items exactly like the mockup (mock10.base3 restore)."""
import sys, json, numpy as np
from PIL import Image
S=sys.argv[1]; OUT=sys.argv[2]
meta={}
for n in ('cup','leaf_green','leaf_black','iced_tea','lemon','water_100','water_80'):
    m=np.load(f'{S}/ui/mask_{n}.npy'); ys,xs=np.where(m); y0,y1,x0,x1=ys.min(),ys.max()+1,xs.min(),xs.max()+1
    Image.fromarray((m[y0:y1,x0:x1]*255).astype('uint8'),'L').save(f'{OUT}/mask_{n}.png')
    meta[n]=[int(x0),int(y0)]
json.dump({'frame':[720,1600],'viewport':[360,800],'offsets':meta},open(f'{OUT}/masks.json','w'),indent=1)
print(meta)
