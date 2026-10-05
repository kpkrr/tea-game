from PIL import Image, ImageFont, ImageDraw
import numpy as np, json, sys
S=sys.argv[1]; R='/Users/kpkr/WebstormProjects/tea-game'
def load(p):
    im=Image.open(p).convert('RGBA'); a=np.array(im); a[...,3]=np.where(a[...,3]>=128,255,0); return Image.fromarray(a)
def cuts(sheet,boxes,scale):
    out={}
    for n,b in boxes.items():
        c=sheet.crop(tuple(int(v*scale) for v in b)); out[n]=c.crop(c.getbbox())
    return out
s0=load(R+'/art-source/ui/ui-s0-hud-pilot-v2-d58bac66.png')
C=cuts(s0,{'plaque':(90,20,475,160),'hf':(365,180,475,272),'he':(550,180,660,272),'pause':(175,395,305,528),'snd':(540,395,665,528),'coin':(355,545,470,660)},2)
s1=load(R+'/art-source/ui/ui-s1-world-ea631cbd.png')
B1={'slip':(65,40,610,160),'slip_s':(670,40,945,160),
'cup':(50,205,185,335),'lemon':(205,205,340,335),'leaf_green':(365,205,500,335),'water_80':(520,205,655,335),'iced_tea':(675,205,810,335),'water_100':(830,205,965,335),'leaf_black':(985,205,1120,335),
'r_full':(60,385,200,515),'r_23':(260,385,395,515),'r_14':(455,385,595,515),'warn':(665,395,790,525),'urgent':(860,385,1095,535),
'cup_e':(60,580,245,715),'cup_t':(285,540,470,715),'cup_r':(510,580,695,715),'ok':(750,580,890,715),'no':(940,580,1080,715),
'g0':(65,765,265,830),'g1':(285,765,475,830),'g2':(495,735,690,830),'disc':(770,745,890,860),'puff':(955,735,1110,860)}
C.update(cuts(s1,B1,2))
# empty heart: parchment fill
a=np.array(C['he']); h,w=a.shape[:2]; m=a[...,3]>0; out=np.zeros((h,w),bool)
st=[(y,x) for y in range(h) for x in (0,w-1)]+[(y,x) for x in range(w) for y in (0,h-1)]
while st:
    y,x=st.pop()
    if 0<=y<h and 0<=x<w and not out[y,x] and not m[y,x]: out[y,x]=True; st+=[(y+1,x),(y-1,x),(y,x+1),(y,x-1)]
a[~m&~out]=(246,234,211,190); C['he']=Image.fromarray(a)
FONT=S+'/Jersey10.ttf'
def F(sz): return ImageFont.truetype(FONT,sz)
def fit(im,h): return im.resize((max(1,round(im.width*h/im.height)),h),Image.LANCZOS)
def fitw(im,w,h): return im.resize((w,h),Image.LANCZOS)
INK=(43,29,26); MINT=(23,112,95); GOLDINK=(138,94,0)
def paste_c(f,im,cx,cy,alpha=1.0):
    if alpha<1: a=np.array(im); a[...,3]=(a[...,3]*alpha).astype('uint8'); im=Image.fromarray(a)
    f.alpha_composite(im,(int(cx-im.width/2),int(cy-im.height/2)))
def hud(f,dp):
    d=ImageDraw.Draw(f); x=dp(8); y=dp(6)
    pl=fit(C['plaque'],dp(52)); f.alpha_composite(pl,(x,y)); ph=pl.height
    d.text((x+dp(27),y+ph*0.31),'848',font=F(dp(26)),fill=MINT,anchor='lm')
    d.text((x+dp(27),y+ph*0.70),'250/250',font=F(dp(22)),fill=GOLDINK,anchor='lm')
    x2=x+pl.width+dp(6)
    for n in ('hf','hf','he'):
        s=fit(C[n],dp(24)); f.alpha_composite(s,(x2,y+dp(14))); x2+=s.width+dp(3)
    bx=f.width-dp(8)
    for n in ('snd','pause'):
        s=fit(C[n],dp(46)); bx-=s.width; f.alpha_composite(s,(bx,y+dp(3))); bx-=dp(4)
def ring(frac,size):
    N=22; c=(N-1)/2; im=Image.new('RGBA',(N,N),(0,0,0,0)); px=im.load()
    import math
    stops=[(1.0,(108,194,74)),(0.6,(242,194,48)),(0.25,(240,120,106)),(0.0,(216,50,60))]
    for i in range(len(stops)-1):
        if stops[i+1][0]<=frac<=stops[i][0]:
            t=(frac-stops[i+1][0])/(stops[i][0]-stops[i+1][0]); col=tuple(int(stops[i+1][1][j]+(stops[i][1][j]-stops[i+1][1][j])*t) for j in range(3)); break
    for y in range(N):
        for x in range(N):
            r=math.hypot(x-c,y-c)
            if r>10.1 or r<4.6: continue
            if r>8.9 or r<5.8: px[x,y]=(43,29,26,255); continue
            ang=(math.degrees(math.atan2(x-c,-(y-c)))+360)%360   # clockwise from 12
            px[x,y]=(*col,255) if ang>=360*(1-frac) else (92,70,60,255)
    return im.resize((size,size),Image.NEAREST)
def ticket(steps,price,dp):
    tk=dp(15); gap=dp(2); pad=dp(5); coin=dp(11); digit=dp(10)
    w=pad*2+len(steps)*(tk+gap)+digit; h=dp(27)
    base=C['slip_s'] if len(steps)<3 else C['slip']
    t=fitw(base,w,h); d=ImageDraw.Draw(t); x=pad; cy=int(h*0.43)
    for s in steps: t.alpha_composite(fit(C[s],tk),(x,cy-tk//2)); x+=tk+gap
    x+=dp(1)
    d.text((x,cy),str(price),font=F(dp(19)),fill=INK,anchor='lm')
    return t
ISLAND='low'
MASKS={n:np.load(f'{S}/ui/mask_{n}.npy') for n in ('cup','leaf_green','leaf_black','iced_tea','lemon','water_100','water_80','barista')}
STATIONS='sign'
STEP_COL={'cup':(245,241,232),'lemon':(247,210,58),'leaf_green':(124,203,78),'water_80':(88,166,238),
 'iced_tea':(168,130,219),'water_100':(232,66,79),'leaf_black':(176,96,42)}
def glyph_mask(step,n):
    """Ink glyph of a round token, re-pixelled to n x n units (outer ring dropped)."""
    t=np.array(C[step].convert('RGBA')).astype(int); h,w=t.shape[:2]
    yy,xx=np.mgrid[0:h,0:w]; r=np.hypot(xx-w/2,yy-h/2)/(min(h,w)/2)
    dark=(t[...,:3].sum(-1)<200)&(t[...,3]>0)&(r<0.66)
    ys,xs=np.where(dark); dark=dark[ys.min():ys.max()+1,xs.min():xs.max()+1]
    im=Image.fromarray((dark*255).astype('uint8')); s_=n/max(im.size)
    im=im.resize((max(1,round(im.width*s_)),max(1,round(im.height*s_))),Image.BOX)
    return np.array(im)>90
def sign(step,unit,legs=5):
    W,BW,BH=22,22,16; H=BH+legs
    a=np.zeros((H,W,4),np.uint8); INKc=(43,29,26,255)
    WOOD=(155,104,58,255); WOOD_HI=(196,140,84,255); WOOD_LO=(112,72,40,255)
    for y in range(BH):
        for x in range(BW):
            corner=(x in (0,BW-1)) and (y in (0,BH-1))
            if corner: continue
            edge=x in (0,BW-1) or y in (0,BH-1) or ((x in (1,BW-2)) and (y in (1,BH-2)))
            if edge: a[y,x]=INKc
            elif y==1 or y==2 and x not in (1,BW-2): a[y,x]=WOOD_HI
            elif x in (1,2,BW-3,BW-2) or y in (BH-3,BH-2) or y==3: a[y,x]=WOOD if y<BH-3 else WOOD_LO
            else:
                c=STEP_COL[step]; a[y,x]=(*c,255)
    # face highlight row
    for x in range(3,BW-3): 
        c=STEP_COL[step]; a[4,x]=(min(255,c[0]+30),min(255,c[1]+30),min(255,c[2]+30),255)
    g=glyph_mask(step,9); gh,gw=g.shape; oy=4+(BH-3-4-gh)//2+1; ox=(BW-gw)//2
    for y in range(gh):
        for x in range(gw):
            if g[y,x]: a[oy+y,ox+x]=INKc
    for lx in (4,BW-6):  # legs
        for y in range(BH,H):
            a[y,lx]=INKc; a[y,lx+1]=WOOD_LO if y<H-1 else INKc; a[y,lx+2]=INKc
    im=Image.fromarray(a); sh=Image.new('RGBA',(W,H+2),(0,0,0,0)); d=ImageDraw.Draw(sh)
    d.ellipse((2,H-2,W-3,H+1),fill=(30,18,12,90)); sh.alpha_composite(im,(0,0))
    return sh.resize((sh.width*unit,sh.height*unit),Image.NEAREST)
def mock(frame_path,anchors_path,sc,held=None):
    f=Image.open(frame_path).convert('RGBA'); A=json.load(open(anchors_path))
    k=f.width/A['viewport'][0]; dp=lambda v:int(round(v*sc)); P=lambda p:(p[0]*k,p[1]*k)
    st=A['stations']
    for sid,v in st.items():
        t=v['type']
        if t in ('slot','trash'): continue
        x,y=P(v['top'])
        if t.startswith('water'):
            g='g1' if v['state']==1 else ('g2' if v['state']==2 else 'g0')
            if STATIONS!='sign': paste_c(f,fit(C[g],dp(9 if g!='g2' else 13)),x,y-dp(52))
        if STATIONS=='sign':
            m=MASKS[t]; ys,xs=np.where(m); top,bot=ys.min(),ys.max(); cx=(xs.min()+xs.max())/2
            unit=3; gap=dp(3); base=bot-dp(4)
            legs=max(3,int((base-(top-gap))/unit))
            sg=sign(t,unit,legs)
            f.alpha_composite(sg,(int(cx-sg.width/2),int(base-sg.height+dp(1))))
            if t.startswith('water'):
                paste_c(f,fit(C[g],dp(9 if g!='g2' else 13)),cx,top-gap-16*unit-dp(8))
            continue
        if t.startswith('water'):
            paste_c(f,fit(C[t],dp(22)),x,y-dp(82))
    if STATIONS=='sign':
        src=np.array(Image.open(frame_path).convert('RGBA'))
        for n,m in MASKS.items():
            a=src.copy(); a[...,3]=m*255; f.alpha_composite(Image.fromarray(a))
    waiting=sorted([g for g in A['guests'] if g['state']!=0],key=lambda g:g['head'][0])
    rows={id(g):i%2 for i,g in enumerate(waiting)}
    for g in A['guests']:
        x,y=P(g['feet']); appr=g['state']==0; al=0.6 if appr else 1.0
        row=0 if appr else rows[id(g)]
        t=ticket(g['steps'],g['price'],dp)
        rg=ring(g['patience'],dp(20))
        if appr: t=t.resize((int(t.width*0.8),int(t.height*0.8)),Image.LANCZOS); rg=rg.resize((dp(16),dp(16)),Image.NEAREST)
        ty=y+dp(16)+row*dp(29)
        tot=rg.width+dp(2)+t.width; x0=x-tot/2
        paste_c(f,rg,x0+rg.width/2,ty,al); paste_c(f,t,x0+rg.width+dp(2)+t.width/2,ty,al)
        if g['level']!='calm': paste_c(f,fit(C['warn' if g['level']=='warn' else 'urgent'],dp(14)),x0+rg.width-dp(1),ty-dp(12))
    if held:
        bx,by=P(A['barista']['hand']); paste_c(f,fit(C['cup_t'],dp(18)),bx+dp(4),by)
        hx,hy=P(A['barista']['head']); x0=hx-(len(held)*dp(15))/2
        for j,s in enumerate(held): paste_c(f,fit(C[s],dp(14)),x0+j*dp(15)+dp(7),hy-dp(8))
        paste_c(f,fit(C['ok'],dp(13)),x0+len(held)*dp(15)+dp(9),hy-dp(8))
    hud(f,dp); return f
if __name__=='__main__':
    U=S+'/ui'
    ph=mock(U+'/clean-360x800-t52.png',U+'/clean-360x800-t52.json',2.0,held=['leaf_green','water_80'])
    old=Image.open(R+'/production/qa/evidence/aa-003-rhombC-2-day-360x800.png').convert('RGBA').resize(ph.size)
    W,H=ph.size; g=40; out=Image.new('RGBA',(W*2+g,H),(40,30,26,255)); out.alpha_composite(old,(0,0)); out.alpha_composite(ph,(W+g,0))
    out.convert('RGB').save(R+'/production/qa/evidence/ui-s1-world-before-after-360x800.jpg',quality=92)
    ph.crop((0,int(H*0.18),W,int(H*0.92))).resize((W*2,int(H*0.74)*2),Image.NEAREST).convert('RGB').save(R+'/production/qa/evidence/ui-s1-world-zoom.jpg',quality=92)

    strip=Image.new('RGBA',(9*120,150),(200,200,200,255))
    for i,fr in enumerate([1.0,0.875,0.75,0.6,0.5,0.4,0.25,0.15,0.05]):
        strip.alpha_composite(ring(fr,88),(i*120+16,16)); ImageDraw.Draw(strip).text((i*120+40,118),f"{int(fr*100)}%",font=F(28),fill=INK)
    strip.convert('RGB').save(R+'/production/qa/evidence/ui-s1-patience-ring-states.jpg',quality=92)
