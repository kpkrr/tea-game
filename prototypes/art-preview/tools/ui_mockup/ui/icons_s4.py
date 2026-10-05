"""Scene-style icons (no Higgsfield): MSR v1 props -> drinks + recipe steps on the scene's pixel grid.
Output (1 px = 1 art pixel, upscale with NEAREST): art/ui_s4/drink_*.png, step_*.png."""
import cv2, numpy as np
from PIL import Image, ImageDraw
R='/Users/kpkr/WebstormProjects/tea-game'; D=R+'/prototypes/art-preview/art/ui_s4/'
OUTLINE=(58,36,24,255)
def L(n): return Image.open(D+'src_'+n+'.png').convert('RGBA')
def pixelize(im,h,levels=28,outline=True):
    w=max(1,round(im.width*h/im.height)); a=np.array(im).astype(np.float32)/255
    a[...,:3]*=a[...,3:4]; sm=np.array(Image.fromarray((a*255).astype(np.uint8)).resize((w,h),Image.BOX)).astype(np.float32)/255
    al=sm[...,3]; rgb=np.where(al[...,None]>0,sm[...,:3]/np.maximum(al[...,None],1e-6),0)
    blur=cv2.blur(rgb,(3,3)); rgb=np.clip(rgb+(rgb-blur)*0.35,0,1)     # crisp like bake_pixel_plate
    rgb=np.round(rgb*levels)/levels; op=al>=0.5
    out=np.zeros((h+2,w+2,4),np.uint8); out[1:-1,1:-1,:3]=(rgb*255).astype(np.uint8); out[1:-1,1:-1,3]=op*255
    if outline:
        m=out[...,3]>0; ring=np.zeros_like(m)
        ring[1:]|=m[:-1]; ring[:-1]|=m[1:]; ring[:,1:]|=m[:,:-1]; ring[:,:-1]|=m[:,1:]; ring&=~m
        out[ring]=OUTLINE
    im=Image.fromarray(out); return im.crop(im.getbbox())
def tea_cup(col,ice=False,lemon=False):
    cup=L('cup'); W,H=cup.size; pad=70 if lemon or ice else 0
    c=Image.new('RGBA',(W+pad,H+pad),(0,0,0,0)); c.alpha_composite(cup,(0,pad))
    tea=Image.new('RGBA',c.size,(0,0,0,0)); d=ImageDraw.Draw(tea); cx,cy=190,62+pad
    d.ellipse((cx-98,cy-38,cx+98,cy+40),fill=col+(255,))
    dark=tuple(int(v*0.62) for v in col); d.chord((cx-98,cy-38,cx+98,cy+40),180,360,fill=dark+(255,))
    d.ellipse((cx-92,cy-26,cx+92,cy+40),fill=col+(255,))
    hi=tuple(min(255,int(v*1.25+25)) for v in col); d.ellipse((cx-40,cy+8,cx+30,cy+26),fill=hi+(255,))
    c.alpha_composite(tea)
    d=ImageDraw.Draw(c)
    if ice:
        for (x,y,s) in ((120,cy-34,56),(200,cy-42,60)):
            d.rounded_rectangle((x,y,x+s,y+s),radius=10,fill=(214,236,244,255),outline=(120,150,170,255),width=6)
            d.rectangle((x+10,y+10,x+26,y+22),fill=(250,253,255,255))
    if lemon:
        x,y,r=W-40,pad+18,70
        d.ellipse((x-r,y-r,x+r,y+r),fill=(222,170,30,255)); d.ellipse((x-r+12,y-r+12,x+r-12,y+r-12),fill=(250,232,140,255))
        import math
        for i in range(8):
            a_=i*math.pi/4; d.line((x,y,x+math.cos(a_)*(r-16),y+math.sin(a_)*(r-16)),fill=(255,250,215,255),width=7)
        d.ellipse((x-9,y-9,x+9,y+9),fill=(255,250,215,255))
    return c
TEA={'black':(150,62,28),'green':(176,182,72),'cold':(196,112,46)}
DRINKS={'black_tea':tea_cup(TEA['black']),'green_tea':tea_cup(TEA['green']),'cold_tea':tea_cup(TEA['cold'],ice=True),
 'black_tea_lemon':tea_cup(TEA['black'],lemon=True),'green_tea_lemon':tea_cup(TEA['green'],lemon=True)}
for n,im in DRINKS.items(): pixelize(im,30).save(D+'drink_'+n+'.png')
def kettle_drop(col):
    k=L('kettle'); c=Image.new('RGBA',(k.width+70,k.height+90),(0,0,0,0)); c.alpha_composite(k,(0,0)); d=ImageDraw.Draw(c)
    x,y=k.width+8,k.height-40; r=54
    d.ellipse((x-r-12,y-12,x+r+12,y+2*r+12),fill=(58,36,24,255)); d.polygon(((x-r-8,y+r*0.7),(x,y-r*1.6),(x+r+8,y+r*0.7)),fill=(58,36,24,255))
    d.ellipse((x-r,y,x+r,y+2*r),fill=col+(255,)); d.polygon(((x-r+4,y+r*0.7),(x,y-r*1.35),(x+r-4,y+r*0.7)),fill=col+(255,))
    d.ellipse((x-r*0.5,y+r*0.5,x-r*0.1,y+r*0.95),fill=(255,255,255,230)); return c
STEPS={'cup':L('cup'),'leaf_black':L('jar_black'),'leaf_green':L('jar_green'),'lemon':L('lemon_bowl'),
 'water_100':kettle_drop((226,70,62)),'water_80':kettle_drop((80,150,226))}
# iced tea step = the jug from the plate (scene art)
img=cv2.imread(R+'/prototypes/art-preview/art/plate.png'); m=np.zeros(img.shape[:2],np.uint8); bg=np.zeros((1,65)); fg=np.zeros((1,65))
cv2.grabCut(img,m,(990,1725,145,170),bg,fg,10,cv2.GC_INIT_WITH_RECT)
a=np.where((m==1)|(m==3),255,0).astype(np.uint8); n_,lab,st,_=cv2.connectedComponentsWithStats(a); a=np.where(lab==1+np.argmax(st[1:,4]),255,0).astype(np.uint8)
rgba=cv2.cvtColor(img,cv2.COLOR_BGR2RGBA); rgba[...,3]=a; jug=Image.fromarray(rgba); jug=jug.crop(jug.getbbox()); jug.save(D+'src_jug.png')
STEPS['iced_tea']=jug
for n,im in STEPS.items():
    pixelize(im,15).save(D+'step_'+n+'.png'); pixelize(im,26).save(D+'stepL_'+n+'.png')
print('ok')
