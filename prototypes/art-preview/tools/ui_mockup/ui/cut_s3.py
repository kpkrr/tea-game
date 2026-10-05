"""Cut the s3 Higgsfield UI sheets into separate PNGs (alpha threshold 128, tight bbox)."""
from PIL import Image
import numpy as np
from scipy import ndimage
R='/Users/kpkr/WebstormProjects/tea-game'
OUT=R+'/prototypes/art-preview/art/ui_s3/'
STEPS=['cup','lemon','leaf_green','leaf_black','water_80','water_100','iced_tea']
def load(p):
    a=np.array(Image.open(p).convert('RGBA')); a[...,3]=np.where(a[...,3]>=128,255,0); a[a[...,3]==0]=0; return a
def boxes(a):
    m=ndimage.binary_closing(a[...,3]>0,iterations=6); lab,n=ndimage.label(m)
    out=[]
    for s in ndimage.find_objects(lab):
        y0,y1,x0,x1=s[0].start,s[0].stop,s[1].start,s[1].stop
        if (y1-y0)*(x1-x0)>1500: out.append((y0,x0,y1,x1))
    return out
def save(a,b,name):
    y0,x0,y1,x1=b; im=Image.fromarray(a[y0:y1,x0:x1]); im=im.crop(im.getbbox()); im.save(OUT+name+'.png'); return im.size
A=load(R+'/art-source/ui/ui-s3-sheet-a-icons-9b5c3442.png')
bb=boxes(A); rows=[[],[],[]]
for b in bb: rows[min(2,int(((b[0]+b[2])/2)//550))].append(b)
for r,prefix in zip(rows,('icon_lg_','icon_sm_','station_sign_')):
    assert len(r)==7,(prefix,len(r))
    for b,s in zip(sorted(r,key=lambda b:b[1]),STEPS): print(prefix+s,save(A,b,prefix+s))
B=load(R+'/art-source/ui/ui-s3-sheet-b-structure-6e3c3a05.png')
bb=sorted(boxes(B),key=lambda b:(b[2]-b[0])*(b[3]-b[1]),reverse=True)
named={}
for b in bb:
    h,w=b[2]-b[0],b[3]-b[1]
    if w>1500: named['hud_bar']=b
    elif w>800: named['order_sign_full']=b
    elif w<100: named['rope_tile']=b
    elif h<150: named.setdefault('gauges',[]).append(b)
    else: named.setdefault('bubbles',[]).append(b)
for k in ('hud_bar','order_sign_full','rope_tile'): print(k,save(B,named[k],k))
for b,n in zip(sorted(named['gauges']),('gauge_empty','gauge_half','gauge_full')): print(n,save(B,b,n))
for b,n in zip(sorted(named['bubbles'],key=lambda b:b[1]),('bubble_warn','bubble_urgent')): print(n,save(B,b,n))
# order sign split: board (9-slice body) + ring knot piece
full=np.array(Image.open(OUT+'order_sign_full.png')); w=(full[...,3]>0).sum(1)
top=int(np.argmax(w>0.9*full.shape[1])); print('board top row',top)
Image.fromarray(full[top:]).save(OUT+'order_sign_board.png')
cols=np.where(full[:top-40,:,3].any(0))[0]; lx=cols[cols<full.shape[1]//2]
x0,x1=lx.min()-30,lx.max()+30; ring=full[top-110:top+20,max(0,x0):x1]
Image.fromarray(ring).save(OUT+'order_sign_ring.png'); print('ring',ring.shape)
