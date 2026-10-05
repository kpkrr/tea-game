"""Cut s7 sheets (cups x9, station signs x7 (named signA_*), order plaques A/B/C + rope tiles) -> art/ui_s7/."""
from PIL import Image
import numpy as np
from scipy import ndimage
R='/Users/kpkr/WebstormProjects/tea-game'; OUT=R+'/prototypes/art-preview/art/ui_s7/'
import os; os.makedirs(OUT,exist_ok=True)
def load(p):
    a=np.array(Image.open(p).convert('RGBA')); a[...,3]=np.where(a[...,3]>=128,255,0); a[a[...,3]==0]=0; return a
def comps(a,close=8,minarea=3000):
    m=ndimage.binary_closing(a[...,3]>0,iterations=close); lab,n=ndimage.label(m)
    out=[]
    for s in ndimage.find_objects(lab):
        b=(s[0].start,s[1].start,s[0].stop,s[1].stop)
        if (b[2]-b[0])*(b[3]-b[1])>minarea: out.append(b)
    return out
def save(a,b,name):
    y0,x0,y1,x1=b; im=Image.fromarray(a[y0:y1,x0:x1]); im=im.crop(im.getbbox()); im.save(OUT+name+'.png'); return im.size
def rows(bs,n_rows):
    bs=sorted(bs,key=lambda b:(b[0]+b[2])/2); k=len(bs)//n_rows
    return [sorted(bs[i*k:(i+1)*k],key=lambda b:b[1]) for i in range(n_rows)]
CUPS=['empty','leaf_black','leaf_green','black_tea','green_tea','black_tea_lemon','green_tea_lemon','cold_tea','ruined']
a=load(R+'/art-source/ui/ui-s7-cups-55c6b1ee.png'); bs=comps(a,12); assert len(bs)==9,len(bs)
for b,n in zip(sum(rows(bs,3),[]),CUPS): print('cup_'+n,save(a,b,'cup_'+n))
STEPS=['cup','lemon','leaf_green','leaf_black','water_80','water_100','iced_tea']
a=load(R+'/art-source/ui/ui-s7-station-signs-239220e1.png'); bs=[b for b in comps(a,4) if b[2]-b[0]>300]; assert len(bs)==7,len(bs)
for r,v in zip(rows(bs,1),'A'):
    for b,n in zip(r,STEPS): print(f'sign{v}_{n}',save(a,b,f'sign{v}_{n}'))
a=load(R+'/art-source/ui/ui-s7-order-plaques-3ed35b18.png'); bs=comps(a,3)
big=sorted([b for b in bs if b[3]-b[1]>300],key=lambda b:b[1]); thin=sorted([b for b in bs if b[3]-b[1]<=300],key=lambda b:b[1])
assert len(big)==3 and len(thin)==3,(len(big),len(thin))
for b,v in zip(big,'ABC'): print('plaque'+v,save(a,b,'plaque'+v))
for b,v in zip(thin,'ABC'): print('rope'+v,save(a,b,'rope'+v))
